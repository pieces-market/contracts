// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Asset} from "../Asset.sol";
import {Governor} from "../Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {IAuctioner} from "../interfaces/IAuctioner.sol";
import {IGovernor} from "../interfaces/IGovernor.sol";

/// @title Auction Contract With Developer Tools !!!
/// @notice Creates new auctions and new NFT's (assets), mints NFT per auctioned asset
/// @notice Allows users to buy pieces, buyout asset, claim revenues and refund
/// @notice Allows developer to manipulate states, force errors, events and get data easier
contract AuctionerDev is ReentrancyGuard, Ownable, IAuctioner {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    event UpdateTimestamp(uint time);

    /// @dev Variables
    uint256 private s_totalAuctions;
    /// @dev Consider adding fn to change this or if we leave it as immutable -> hardcode it in 'propose' function
    address private immutable s_foundation;
    Governor private immutable i_governor;

    /// @dev CONSIDER CHANGING BELOW INTO MAPPING IF POSSIBLE !!!
    /// @dev Arrays
    uint256[] private s_ongoingAuctions;

    struct Auction {
        address asset;
        uint256 price;
        uint256 pieces;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address recipient;
        bool buyoutProposalActive;
        bool descriptProposalActive;
        address offerer;
        mapping(address offerer => uint amount) offer;
        mapping(address offerer => bool) withdrawAllowed;
        AuctionState state;
    }

    /// @dev Mappings
    mapping(uint256 id => Auction) private s_auctions;
    mapping(address asset => bool eligible) private s_eligibleAssets;

    /// @dev Constructor
    constructor(address foundation, address governor) Ownable(msg.sender) {
        s_foundation = foundation;
        i_governor = Governor(governor);
    }

    /// @notice Creates new auction, mints NFT connected to auctioned asset
    /// @dev Emits Create and StateChange events
    /// @param name Asset name, which is also NFT contract name
    /// @param symbol Asset symbol, which is also NFT contract symbol
    /// @param uri Asset uri, which points to metadata file containing associated NFT data
    /// @param price Single piece of asset price
    /// @param pieces Amount of asset pieces available for sell
    /// @param max Maximum amount of pieces that one user can buy
    /// @param start Timestamp when the auction should open
    /// @param end Timestamp when the auction should end
    /// @param recipient Wallet address where funds from asset sale will be transferred
    /// @param royalty The royalty fee (BIPS) to be paid to the @param recipient on each secondary sale, as per the ERC2981 standard
    /// @param brokerFee The percentage of the royalty fee that will be sent to the broker
    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 price,
        uint256 pieces,
        uint256 max,
        uint256 start,
        uint256 end,
        address recipient,
        uint96 royalty,
        uint256 brokerFee
    ) external onlyOwner {
        Auction storage auction = s_auctions[s_totalAuctions];
        if (price == 0 || pieces == 0 || max == 0 || bytes(name).length == 0 || bytes(symbol).length == 0 || bytes(uri).length == 0)
            revert Auctioner__ZeroValueNotAllowed();
        if (start < block.timestamp || (end < start + 1 days)) revert Auctioner__IncorrectTimestamp();
        if (recipient == address(0)) revert Auctioner__ZeroAddressNotAllowed();

        /// @notice Creating new NFT (asset)
        Asset asset = new Asset(name, symbol, uri, recipient, royalty, brokerFee, address(this));

        // Update assets eligible list
        s_eligibleAssets[address(asset)] = true;

        // Update Auction struct
        auction.asset = address(asset);
        auction.price = price;
        auction.pieces = pieces;
        auction.max = max;
        auction.openTs = start;
        auction.closeTs = end;
        auction.recipient = recipient;

        if (auction.openTs > block.timestamp) {
            auction.state = AuctionState.SCHEDULED;

            emit Schedule(s_totalAuctions, start);
        } else {
            auction.state = AuctionState.OPENED;
        }

        s_ongoingAuctions.push(s_totalAuctions);

        emit Create(s_totalAuctions, address(asset), price, pieces, max, start, end, recipient, royalty, brokerFee);
        emit StateChange(s_totalAuctions, auction.state);

        s_totalAuctions++;
    }

    /// @inheritdoc IAuctioner
    function buy(uint256 id, uint256 pieces) external payable override nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.OPENED) revert Auctioner__AuctionNotOpened();
        if (auction.pieces < pieces) revert Auctioner__InsufficientPieces();
        /// @dev Implement fee's
        if ((Asset(payable(auction.asset)).balanceOf(msg.sender) + pieces) > auction.max) revert Auctioner__BuyLimitExceeded();
        if (msg.value != auction.price * pieces) revert Auctioner__IncorrectFundsTransfer();

        auction.pieces -= pieces;

        /// @notice Mint pieces and immediately delegate votes to the buyer
        Asset(payable(auction.asset)).safeBatchMint(msg.sender, pieces);

        emit Purchase(id, pieces, msg.sender);

        /// @dev Consider moving below into Keepers -> check gas costs
        if (auction.pieces == 0) {
            auction.state = AuctionState.CLOSED;

            emit StateChange(id, auction.state);

            /// @notice Transfer funds to the broker
            uint256 payment = Asset(payable(auction.asset)).totalMinted() * auction.price;

            (bool success, ) = auction.recipient.call{value: payment}("");
            if (!success) revert Auctioner__TransferFailed();

            emit TransferToBroker(id, payment, auction.recipient);
        }
    }

    /// @inheritdoc IAuctioner
    function propose(uint256 id, string memory description, ProposalType proposal) external payable override {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.CLOSED) revert Auctioner__AuctionNotClosed();
        /// @dev BELOW ERROR IS POINTLESS AS WE ARE UNABLE TO PASS OUT OF SCOPE INDEX FOR TYPE
        // if (uint(proposal) > 1) revert Auctioner__InvalidProposalType();

        bytes memory encodedFunction;

        if (proposal == ProposalType.BUYOUT) {
            if (auction.buyoutProposalActive) revert Auctioner__ProposalInProgress();
            if (msg.value < (Asset(payable(auction.asset)).totalMinted() * auction.price)) revert Auctioner__InsufficientFunds();

            auction.buyoutProposalActive = true;
            auction.withdrawAllowed[msg.sender] = false;
            auction.offerer = msg.sender;
            auction.offer[msg.sender] += msg.value;
            encodedFunction = abi.encodeWithSignature("buyout(uint256)", id);
        } else {
            if (msg.sender != s_foundation) revert Auctioner__UnauthorizedCaller();
            if (auction.descriptProposalActive) revert Auctioner__ProposalInProgress();
            if (msg.value > 0) revert Auctioner__Overpayment();
            if (bytes(description).length == 0 || bytes(description).length > 500) revert Auctioner__IncorrectDescriptionSize();

            auction.descriptProposalActive = true;
            encodedFunction = abi.encodeWithSignature("descript(uint256,string)", id, description);
        }

        i_governor.propose(id, auction.asset, description, encodedFunction);

        // Consider removing this emit -> depends on database
        emit Propose(id, msg.value, msg.sender);
    }

    /// @notice Called by Governor if the 'buyout' proposal succeeds
    /// @param id Auction id that we want to interact with
    function buyout(uint256 id) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        auction.state = AuctionState.FINISHED;

        emit Buyout(id, auction.offer[auction.offerer], auction.offerer);
        emit StateChange(id, auction.state);
    }

    /// @notice Called by Governor if the 'descript' proposal succeeds
    /// @param id Auction id that we want to interact with
    function descript(uint256 id, string memory description) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        auction.descriptProposalActive = false;

        emit Descript(id, description);
    }

    /// @notice Called by Governor if the proposal fails
    /// @param id Auction id that we want to interact with
    function reject(uint256 id, bytes memory encodedFunction) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        if (keccak256(encodedFunction) == keccak256(abi.encodeWithSignature("buyout(uint256)", id))) {
            auction.buyoutProposalActive = false;
            auction.withdrawAllowed[auction.offerer] = true;
        } else {
            auction.descriptProposalActive = false;
        }

        emit Reject(id);
    }

    /// @inheritdoc IAuctioner
    function withdraw(uint256 id) external nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (!auction.withdrawAllowed[msg.sender]) revert Auctioner__ProposalInProgress();

        uint amount = auction.offer[msg.sender];

        if (amount > 0) {
            auction.offer[msg.sender] = 0;
        } else {
            revert Auctioner__InsufficientFunds();
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Auctioner__TransferFailed();

        emit Withdraw(id, amount, msg.sender);
    }

    /// @inheritdoc IAuctioner
    function refund(uint256 id) external override nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.FAILED) revert Auctioner__AuctionNotFailed();

        uint256 tokenBalance = Asset(payable(auction.asset)).balanceOf(msg.sender);
        uint256 amount = tokenBalance * auction.price;

        if (amount > 0) {
            Asset(payable(auction.asset)).batchBurn(msg.sender);
        } else {
            revert Auctioner__InsufficientFunds();
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Auctioner__TransferFailed();

        emit Refund(id, amount, msg.sender);
    }

    /// @dev 3RD PARTY ALLOWED ONLY TO TRIGGER DISTRIBUTION OF FUNDS AMONG ASSET INVESTORS ONCE 3RD PARTY WILL SELL ASSET
    /// HOW CAN WE AUTOMATE IT AND KEEP DECENTRALIZED?
    /// @notice WE MAY GET CALLS FROM FOUNDATION ONLY -> TO CONSIDER (WEAK DECENTRALIZATION)
    /// @notice WE CAN USE 'VLAYER' TO TRIGGER THIS FUNCTION BASED ON SOME MAIL.
    // WE CAN ALSO DECLARE THAT THIS CONFIRMATION MAIL WILL COME FROM 'SOME' ADDRESS -> THIS SHOULD BE FOR EXAMPLE DECLARED BY BROKER ON AUCTION CREATION OR LATER ON.
    function fulfill(uint256 id) external payable override {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        /// @dev Below address(0) is tmp only, we need to get proper caller address
        if (msg.sender != address(0)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.CLOSED) revert Auctioner__AuctionNotClosed();
        if (msg.value < (Asset(payable(auction.asset)).totalMinted() * auction.price)) revert Auctioner__InsufficientFunds();

        auction.offerer = address(0);
        auction.offer[address(0)] = msg.value;
        auction.state = AuctionState.FINISHED;

        emit Fulfill(id, msg.value, msg.sender);
        emit StateChange(id, auction.state);
    }

    /// @inheritdoc IAuctioner
    function claim(uint256 id) external override nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.FINISHED) revert Auctioner__AuctionNotFinished();

        uint256 funds = auction.offer[auction.offerer];
        uint256 supply = Asset(payable(auction.asset)).totalMinted();
        uint256 tokens = Asset(payable(auction.asset)).balanceOf(msg.sender);

        /// @dev Supply will not be 0 here ever as to get auction finished there will be always some supply (totalMinted() from asset)
        uint256 amount = (funds / supply) * tokens;

        if (amount > 0) {
            Asset(payable(auction.asset)).batchBurn(msg.sender);
        } else {
            revert Auctioner__InsufficientFunds();
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Auctioner__TransferFailed();

        emit Claim(id, amount, msg.sender);

        if (Asset(payable(auction.asset)).totalSupply() == 0) {
            auction.state = AuctionState.ARCHIVED;

            emit StateChange(id, auction.state);
        }
    }

    // ====================================
    //              Royalty
    // ====================================

    function emitRoyaltySplit(
        address payer,
        address broker,
        uint256 brokerShare,
        address piecesMarket,
        uint256 piecesMarketShare,
        uint256 totalValue
    ) external {
        if (!s_eligibleAssets[msg.sender]) revert Auctioner__NotEligibleCaller();

        emit RoyaltySplitExecuted(msg.sender, payer, broker, brokerShare, piecesMarket, piecesMarketShare, totalValue);
    }

    // ====================================
    //              Automation
    // ====================================

    /// @dev CONSIDER MOVING ALL OF BELOW INTO SEPARATE CONTRACT, SO IT CAN BE DEPLOYED ONCE AND MANAGE ALL AUCTIONER CONTRACT VERSIONS

    /// @notice Execution API called by Gelato, determines if the exec function should be executed
    /// @dev This function is called by Gelato to decide whether executing the `exec()` function is necessary
    /// @return canExec Boolean that indicates whether the execution is necessary
    /// @return execPayload Encoded function selector for `exec()`
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        /// @dev Consider adding below restriction
        // if(tx.gasprice > 80 gwei) return (false, bytes("Gas price too high"));

        execPayload = abi.encodeWithSelector(this.exec.selector);

        /// @dev Consider below additional loop here, so we have 100% confirm that there is something to execute but it is a bit more expensive
        /// @dev We could implement whole logic and checks here to call fn responsible for updating state and removing id from array like exec(uint id)
        if (s_ongoingAuctions.length > 0) {
            for (uint i; i < s_ongoingAuctions.length; i++) {
                uint id = s_ongoingAuctions[i];
                Auction storage auction = s_auctions[id];

                if (
                    (auction.state == AuctionState.SCHEDULED && auction.openTs < block.timestamp) ||
                    (auction.state == AuctionState.OPENED && auction.closeTs < block.timestamp)
                ) {
                    return (true, execPayload);
                }
            }
        }

        return (false, execPayload);
    }

    /// @notice Execution API called by Gelato. Updates state of auction based on time
    /// @dev This function is triggered by Gelato when the `checker()` function indicates execution is necessary
    function exec() external {
        for (uint i; i < s_ongoingAuctions.length; ) {
            uint id = s_ongoingAuctions[i];
            Auction storage auction = s_auctions[id];

            if (auction.state == AuctionState.SCHEDULED && auction.openTs < block.timestamp) {
                auction.state = AuctionState.OPENED;

                emit StateChange(id, auction.state);
            }

            if (auction.state == AuctionState.OPENED && auction.closeTs < block.timestamp) {
                auction.state = AuctionState.FAILED;

                emit StateChange(id, auction.state);

                // Swap current element with the last one to remove it
                s_ongoingAuctions[i] = s_ongoingAuctions[s_ongoingAuctions.length - 1];
                s_ongoingAuctions.pop();

                // Consider adding emit here

                // Do not increment 'i', recheck the element at index 'i' (since it was swapped)
                continue;
            }

            unchecked {
                i++;
            }
        }
    }

    // =========================================
    //              Developer Tools
    // =========================================

    /// @dev Tokens Owned By Address Getter -> to be removed
    function getTokens(uint id, address owner) public view returns (uint) {
        Auction storage auction = s_auctions[id];

        return Asset(payable(auction.asset)).balanceOf(owner);
    }

    /// @dev Auction Data Getter -> to be removed
    function getData(uint256 id) public view returns (address, uint, uint, uint, uint, uint, address, AuctionState) {
        Auction storage auction = s_auctions[id];

        return (auction.asset, auction.price, auction.pieces, auction.max, auction.openTs, auction.closeTs, auction.recipient, auction.state);
    }

    function getProposals(uint id) public view returns (bool, bool) {
        Auction storage auction = s_auctions[id];

        return (auction.buyoutProposalActive, auction.descriptProposalActive);
    }

    function getUnprocessedAuctions() external view returns (uint[] memory) {
        return s_ongoingAuctions;
    }

    /// @dev HELPER DEV ONLY
    // function errorHack(uint256 errorType) public pure {
    //     if (errorType == 0) revert Auctioner__AuctionDoesNotExist();
    //     if (errorType == 1) revert Auctioner__AuctionNotOpened();
    //     if (errorType == 2) revert Auctioner__AuctionNotClosed();
    //     if (errorType == 3) revert Auctioner__AuctionNotFailed();
    //     if (errorType == 4) revert Auctioner__AuctionNotFinished();
    //     if (errorType == 5) revert Auctioner__InsufficientPieces();
    //     if (errorType == 6) revert Auctioner__InsufficientFunds();
    //     if (errorType == 7) revert Auctioner__TransferFailed();
    //     if (errorType == 8) revert Auctioner__ZeroValueNotAllowed();
    //     if (errorType == 9) revert Auctioner__IncorrectTimestamp();
    //     if (errorType == 10) revert Auctioner__ZeroAddressNotAllowed();
    //     if (errorType == 11) revert Auctioner__Overpayment();
    //     if (errorType == 12) revert Auctioner__BuyLimitExceeded();
    //     if (errorType == 14) revert Auctioner__ProposalInProgress();
    //     if (errorType == 15) revert Auctioner__InvalidProposalType();
    //     if (errorType == 16) revert Auctioner__IncorrectFundsTransfer();
    //     if (errorType == 17) revert Auctioner__NotEligibleCaller();
    // }

    /// @dev HELPER DEV ONLY
    function stateHack(uint256 id, uint256 state) public {
        Auction storage auction = s_auctions[id];

        // 0 - UNINITIALIZED
        // 1 - SCHEDULED
        // 2 - OPENED
        // 3 - CLOSED
        // 4 - FAILED
        // 5 - FINISHED
        // 6 - ARCHIVED

        auction.state = AuctionState(state);

        emit StateChange(id, AuctionState(state));
    }

    /// @dev HELPER DEV ONLY
    function eventHack(uint256 eventId) public {
        if (eventId == 0) emit Create(1, address(666), 0.1 ether, 80, 20, 666, 777, address(6), 500, 50);
        if (eventId == 1) emit Schedule(1, 0);
        if (eventId == 2) emit Purchase(1, 0, address(6));
        if (eventId == 3) emit Buyout(1, 0.1 ether, address(6));
        if (eventId == 4) emit Claim(1, 0.1 ether, address(6));
        if (eventId == 5) emit Refund(2, 0.1 ether, address(6));
        if (eventId == 6) emit Withdraw(1, 0.1 ether, address(6));
        if (eventId == 7) emit Propose(1, 5, address(0));
        if (eventId == 8) emit TransferToBroker(0, 0, address(0));
        if (eventId == 9) emit StateChange(1, AuctionState.UNINITIALIZED);
        if (eventId == 10) emit UpdateTimestamp(block.timestamp);
        if (eventId == 11) emit RoyaltySplitExecuted(address(333), address(555), address(666), 0.3 ether, address(777), 0.2 ether, 0.5 ether);
    }
}
