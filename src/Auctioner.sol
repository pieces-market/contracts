// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {IAuctioner} from "./interfaces/IAuctioner.sol";
import {FractAsset} from "./FractAsset.sol";

/// @title Auction Contract
/// @notice Creates new auctions and new NFT's (assets), mints NFT per auctioned asset
/// @notice Allows users to buy pieces, buyout asset, claim revenues and refund
contract Auctioner is Ownable, ReentrancyGuard, IAuctioner {
    /// @dev Libraries

    /// @dev Variables
    uint256 private s_totalAuctions;

    /// @dev Arrays
    uint256[] private s_scheduledAuctions;

    /// @dev Mappings
    mapping(uint256 id => Auction map) private s_auctions;

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    /// @notice Creates new auction, mints NFT connected to auctioned asset
    /// @dev Emits Create event
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
        if (auction.auctionState != AuctionState.UNINITIALIZED) revert Auctioner__AuctionAlreadyInitialized();

        // Creating new NFT (asset)
        FractAsset asset = new FractAsset(name, symbol, uri, pieces, recipient);

        auction.asset = address(asset);
        auction.price = price;
        auction.pieces = pieces;
        auction.available = pieces;
        auction.max = max;
        auction.openTs = start;
        auction.closeTs = start + (span * 1 days);
        auction.recipient = recipient;

        if (auction.openTs > block.timestamp) {
            auction.auctionState = AuctionState.PLANNED;
            s_scheduledAuctions.push(s_totalAuctions);

            emit Plan(s_totalAuctions, start);
        } else {
            auction.auctionState = AuctionState.OPENED;
        }

        emit StateChange(s_totalAuctions, auction.auctionState);
        emit Create(s_totalAuctions, address(asset), price, pieces, max, start, span, recipient);

        s_totalAuctions += 1;
    }

    /// @inheritdoc IAuctioner
    function buy(uint256 id, uint256 pieces) external payable override nonReentrant {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.auctionState != AuctionState.OPENED) revert Auctioner__AuctionNotOpened();
        if (pieces < 1) revert Auctioner__ZeroValueNotAllowed();
        if (auction.available < pieces) revert Auctioner__InsufficientPieces();
        if (msg.value < (pieces * auction.price)) revert Auctioner__InsufficientFunds();

        // emit Purchase();
        //
        // If last piece bought ->
        // emit TransferToBroker();
    }

    /// @inheritdoc IAuctioner
    function buyout(uint256 id) external payable override {
        // emit Buyout();
    }

    /// @inheritdoc IAuctioner
    function claim() external override {
        // emit Claim();
    }

    /// @inheritdoc IAuctioner
    function refund() external override {
        // emit Refund();
    }

    // =========================================
    //              Developer Tools
    // =========================================

    /// @dev Getter -> to be removed
    function getState(uint256 id) public view returns (AuctionState) {
        Auction storage auction = s_auctions[id];

        return auction.auctionState;
    }

    /// @dev HELPER DEV ONLY
    function errorHack(uint256 errorType) external pure {
        // 0 - Auctioner__AuctionDoesNotExist
        // 1 - Auctioner__AuctionNotOpened
        // 2 - Auctioner__InsufficientPieces
        // 3 - Auctioner__NotEnoughFunds
        // 4 - Auctioner__TransferFailed
        // ...

        if (errorType == 0) revert Auctioner__AuctionDoesNotExist();
        if (errorType == 1) revert Auctioner__AuctionNotOpened();
        if (errorType == 2) revert Auctioner__InsufficientPieces();
        if (errorType == 3) revert Auctioner__InsufficientFunds();
        if (errorType == 4) revert Auctioner__TransferFailed();
        if (errorType == 5) revert Auctioner__AuctionAlreadyInitialized();
        if (errorType == 6) revert Auctioner__ZeroValueNotAllowed();
        if (errorType == 7) revert Auctioner__IncorrectTimestamp();
        if (errorType == 8) revert Auctioner__ZeroAddressNotAllowed();
    }

    /// @dev HELPER DEV ONLY
    function stateHack(uint256 id, uint256 state) external {
        Auction storage auction = s_auctions[id];

        // 0 - UNINITIALIZED
        // 1 - PLANNED
        // 2 - OPENED
        // 3 - CLOSED
        // 4 - FAILED
        // 5 - VOTING
        // 6 - FINISHED
        // 7 - ARCHIVED

        auction.auctionState = AuctionState(state);
    }

    /// @dev HELPER DEV ONLY
    function eventHack(uint256 eventId) external {
        // 0 - Create event
        // 1 - Plan event
        // 2 - Purchase event
        // 3 - Buyout event
        // 4 - Claim event
        // 5 - Refund event
        // 6 - Vote event
        // 7 - TransferToBroker event
        // 8 - StateChange event

        if (eventId == 0) emit Create(0, address(0), 0, 0, 0, 0, 0, address(0));
        if (eventId == 1) emit Plan(0, 0);
        if (eventId == 2) emit Purchase();
        if (eventId == 3) emit Buyout();
        if (eventId == 4) emit Claim();
        if (eventId == 5) emit Refund();
        if (eventId == 6) emit Vote();
        if (eventId == 7) emit TransferToBroker(address(0), 0);
        if (eventId == 8) emit StateChange(0, AuctionState.UNINITIALIZED);
    }
}
