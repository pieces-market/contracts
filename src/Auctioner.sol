// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Asset} from "./Asset.sol";
import {Governor} from "./Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {IAuctioner} from "./interfaces/IAuctioner.sol";
import {IGovernor} from "./interfaces/IGovernor.sol";

/// @title Auction Contract
/// @notice Creates new auctions and new NFT's (assets), mints NFT per auctioned asset
/// @notice Allows users to buy pieces, buyout asset, claim revenues and refund
contract Auctioner is ReentrancyGuard, Ownable, IAuctioner {
    /// @dev Variables
    uint256 private s_totalAuctions;
    Governor private immutable i_governor;

    /// @dev CONSIDER CHANGING BELOW INTO MAPPING !!!
    /// @dev Arrays
    uint256[] private s_scheduledAuctions;

    struct Auction {
        address asset;
        uint256 price;
        uint256 pieces;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address recipient;
        bool proposalActive;
        address offerer;
        mapping(address offerer => bool) withdrawAllowed;
        mapping(address offerer => uint amount) offer;
        AuctionState state;
    }

    /// @dev Mappings
    mapping(uint256 id => Auction) private s_auctions;

    //mapping(address => uint) private s_funderToFunds;

    /// @dev Constructor
    constructor(address governor) Ownable(msg.sender) {
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
    /// @param span Duration of auction expressed in days. Smallest possible value is 1 (1 day auction duration)
    /// @param recipient Wallet address where funds from asset sale will be transferred
    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 price,
        uint256 pieces,
        uint256 max,
        uint256 start,
        uint256 span,
        address recipient
    ) external onlyOwner {
        Auction storage auction = s_auctions[s_totalAuctions];
        if (price == 0 || pieces == 0 || max == 0) revert Auctioner__ZeroValueNotAllowed();
        if (start < block.timestamp || span < 1) revert Auctioner__IncorrectTimestamp();
        if (recipient == address(0)) revert Auctioner__ZeroAddressNotAllowed();
        if (auction.state != AuctionState.UNINITIALIZED) revert Auctioner__AuctionAlreadyInitialized();

        /// @notice Creating new NFT (asset)
        Asset asset = new Asset(name, symbol, uri, address(this));

        auction.asset = address(asset);
        auction.price = price;
        auction.pieces = pieces;
        auction.max = max;
        auction.openTs = start;
        auction.closeTs = start + (span * 1 days);
        auction.recipient = recipient;

        if (auction.openTs > block.timestamp) {
            auction.state = AuctionState.SCHEDULED;
            s_scheduledAuctions.push(s_totalAuctions);

            emit Schedule(s_totalAuctions, start);
        } else {
            auction.state = AuctionState.OPENED;
        }

        emit Create(s_totalAuctions, address(asset), price, pieces, max, start, span, recipient);
        emit StateChange(s_totalAuctions, auction.state);

        s_totalAuctions += 1;
    }

    /// @inheritdoc IAuctioner
    function buy(uint256 id, uint256 pieces) external payable override nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.OPENED) revert Auctioner__AuctionNotOpened();
        //if (pieces < 1) revert Auctioner__ZeroValueNotAllowed(); -> MintZeroQuantity error from minter
        if (auction.pieces < pieces) revert Auctioner__InsufficientPieces();
        /// @dev Implement fee's
        if ((Asset(auction.asset).balanceOf(msg.sender) + pieces) > auction.max) revert Auctioner__BuyLimitExceeded();

        uint256 cost = auction.price * pieces;
        if (msg.value < cost) revert Auctioner__InsufficientFunds();
        if (msg.value > cost) revert Auctioner__Overpayment();

        auction.pieces -= pieces;

        /// @notice Mint pieces and immediately delegate votes to the buyer
        Asset(auction.asset).safeBatchMint(msg.sender, pieces);

        emit Purchase(id, pieces, msg.sender);

        /// @dev Consider moving below into Keepers -> check gas costs
        if (auction.pieces == 0) {
            auction.state = AuctionState.CLOSED;

            emit StateChange(id, auction.state);

            /// @notice Transfer funds to the broker
            uint256 payment = Asset(auction.asset).totalSupply() * auction.price;

            (bool success, ) = auction.recipient.call{value: payment}("");
            if (!success) revert Auctioner__TransferFailed();

            emit TransferToBroker(id, auction.recipient, payment);
        }
    }

    /// @dev REFACTOR REMOVE proposalType AND CHANGE IT INTO CALLDATA
    /// @dev WE CAN ACTUALLY CALL PROPOSE ON GOVERNOR?
    /// @dev encodedFunction should take number
    /// @inheritdoc IAuctioner
    function propose(uint256 id, string memory description, ProposalType proposal) external payable override {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.CLOSED) revert Auctioner__AuctionNotClosed();
        if (auction.proposalActive) revert Auctioner__ProposalInProgress();
        // Check below error
        if (uint(proposal) > 1) revert Auctioner__InvalidProposalType();

        // check cost memory vs none
        bytes memory encodedFunction;

        if (proposal == ProposalType.BUYOUT) {
            if (msg.value < (Asset(auction.asset).totalSupply() * auction.price)) revert Auctioner__InsufficientFunds();
            encodedFunction = abi.encodeWithSignature("buyout(uint256)", id);
        } else {
            /// @dev Check string size
            if (bytes(description).length == 0 || bytes(description).length > 100) revert Auctioner__IncorrectDescriptionSize();
            encodedFunction = abi.encodeWithSignature("descriptor(uint256,string)", id, description);
        }

        bool success = i_governor.propose(id, auction.asset, description, encodedFunction);
        if (!success) revert Auctioner__FunctionCallFailed();

        auction.proposalActive = true;
        auction.offerer = msg.sender;
        if (auction.withdrawAllowed[msg.sender]) auction.withdrawAllowed[msg.sender] = false;
        auction.offer[msg.sender] += msg.value;

        // consider emits
        emit Offer(id, msg.value, msg.sender);
    }

    /// @dev REFACTOR NEEDED
    /// @notice Called by Governor if the 'buyout' proposal succeeds
    /// @param id Auction id that we want to interact with
    function buyout(uint256 id) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        auction.state = AuctionState.FINISHED;
        uint256 amount = auction.offer[auction.offerer];

        if (amount > 0) {
            auction.offer[auction.offerer] = 0;
        } else {
            revert Auctioner__InsufficientFunds();
        }

        // redystrybucja kasy do userow
        (bool success, ) = auction.recipient.call{value: amount}("");
        if (!success) revert Auctioner__TransferFailed();

        //
        // Updated price will reevaluate total asset value, so new buyout offer will need to be higher
        auction.price = amount / Asset(auction.asset).totalSupply();
        auction.proposalActive = false;

        emit Buyout(id, auction.recipient, auction.offerer, amount);
        emit StateChange(s_totalAuctions, auction.state);
    }

    /// @dev THIS FUNCTION IS PURE THEORETICAL - refactor it to take description proposal, konto fundacji(nasze) tylko moze triggerowac ta funkcje
    /// @dev consider moving this fn into governor
    /// @notice Called by Governor if the 'offer' proposal succeeds
    /// @param id Auction id that we want to interact with
    function descriptor(uint256 id, uint256 value) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        /// @dev CHECK IF STARTING PRICE WILL BE 1 WEI AND WE WOULD LIKE TO UPDATE VALUE TO FOR EXAMPLE 50%
        auction.price = value / Asset(auction.asset).totalSupply();
    }

    /// @notice Called by Governor if the proposal fails
    /// @param id Auction id that we want to interact with
    function rejectProposal(uint256 id) external {
        if (msg.sender != address(i_governor)) revert Auctioner__UnauthorizedCaller();
        Auction storage auction = s_auctions[id];

        auction.proposalActive = false;
        auction.withdrawAllowed[auction.offerer] = true;
    }

    /// @inheritdoc IAuctioner
    function withdrawOffer(uint256 id) external nonReentrant {
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

        uint256 tokenBalance = Asset(auction.asset).balanceOf(msg.sender);
        uint256 amount = tokenBalance * auction.price;

        if (amount > 0) {
            Asset(auction.asset).batchBurn(msg.sender);
        } else {
            revert Auctioner__InsufficientFunds();
        }

        (bool success, ) = msg.sender.call{value: amount}("");

        /// @dev IF THIS REVERT WILL TAKE PLACE CHECK IF TOKENS WERE NOT BURNT
        if (!success) revert Auctioner__TransferFailed();

        emit Refund(id, amount, msg.sender);
    }

    /// @inheritdoc IAuctioner
    function claim(uint256 id) external override nonReentrant {
        // emit Claim();
    }

    // =========================================
    //              Developer Tools
    // =========================================

    /// @dev Tokens Owned By Address Getter -> to be removed
    function getTokens(uint id, address owner) public view returns (uint) {
        Auction storage auction = s_auctions[id];

        return Asset(auction.asset).balanceOf(owner);
    }

    /// @dev Auction Data Getter -> to be removed
    function getData(uint256 id) public view returns (address, uint, uint, uint, uint, uint, address, AuctionState) {
        Auction storage auction = s_auctions[id];

        return (auction.asset, auction.price, auction.pieces, auction.max, auction.openTs, auction.closeTs, auction.recipient, auction.state);
    }

    /// @dev HELPER DEV ONLY
    function errorHack(uint256 errorType) public pure {
        // 0 - Auctioner__AuctionDoesNotExist
        // 1 - Auctioner__AuctionNotOpened
        // 2 - Auctioner__AuctionNotClosed
        // 3 - Auctioner__AuctionNotFailed
        // 4 - Auctioner__InsufficientPieces
        // 5 - Auctioner__InsufficientFunds
        // ...

        if (errorType == 0) revert Auctioner__AuctionDoesNotExist();
        if (errorType == 1) revert Auctioner__AuctionNotOpened();
        if (errorType == 2) revert Auctioner__AuctionNotClosed();
        if (errorType == 3) revert Auctioner__AuctionNotFailed();
        if (errorType == 4) revert Auctioner__InsufficientPieces();
        if (errorType == 5) revert Auctioner__InsufficientFunds();
        if (errorType == 6) revert Auctioner__TransferFailed();
        if (errorType == 7) revert Auctioner__AuctionAlreadyInitialized();
        if (errorType == 8) revert Auctioner__ZeroValueNotAllowed();
        if (errorType == 9) revert Auctioner__IncorrectTimestamp();
        if (errorType == 10) revert Auctioner__ZeroAddressNotAllowed();
        if (errorType == 11) revert Auctioner__Overpayment();
        if (errorType == 12) revert Auctioner__BuyLimitExceeded();
        if (errorType == 13) revert Auctioner__FunctionCallFailed();
        if (errorType == 14) revert Auctioner__ProposalInProgress();
        if (errorType == 15) revert Auctioner__InvalidProposalType();
    }

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
    }

    /// @dev HELPER DEV ONLY
    function eventHack(uint256 eventId) public {
        // 0 - Create event
        // 1 - Schedule event
        // 2 - Purchase event
        // ...

        if (eventId == 0) emit Create(0, address(0), 0, 0, 0, 0, 0, address(0));
        if (eventId == 1) emit Schedule(0, 0);
        if (eventId == 2) emit Purchase(0, 0, address(0));
        if (eventId == 3) emit Buyout();
        if (eventId == 4) emit Claim();
        if (eventId == 5) emit Refund(0, 0, address(0));
        if (eventId == 6) emit Withdraw(0, 0, address(0));
        if (eventId == 7) emit Offer(0, 0, address(0));
        if (eventId == 8) emit TransferToBroker(0, address(0), 0);
        if (eventId == 9) emit StateChange(0, AuctionState.UNINITIALIZED);
    }
}
