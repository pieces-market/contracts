// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {IAuctioner} from "./interfaces/IAuctioner.sol";

/// @title Auction Contract
/// @notice Creates new auctions, mints NFT per auctioned asset
/// @notice Allows users to buy pieces, buyout asset, claim revenues and refund
contract Auctioner is Ownable, ReentrancyGuard, IAuctioner {
    /// @dev Libraries

    /// @dev Errors
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__InsufficientPieces();
    error Auctioner__NotEnoughFunds();
    error Auctioner__TransferFailed();

    /// @dev Variables
    uint public s_totalAuctions;

    /// @dev Arrays

    /// @dev Enums
    enum AuctionState {
        UNINITIALIZED,
        PLANNED,
        OPENED,
        CLOSED,
        FAILED,
        VOTING,
        FINISHED,
        ARCHIVED
    }

    /// @dev Structs
    struct Auction {
        address asset;
        string uri; // ??? -> we can get it from NFT
        uint256 price;
        uint256 pieces;
        uint256 available;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address[] assetOwners; // we can get it from NFT
        mapping(address => uint) ownerToFunds; // we can get it from NFT
        address recipient;
        AuctionState auctionState;
    }

    /// @dev Mappings
    mapping(uint256 id => Auction map) private s_auctions;

    /// @dev Events
    event Create();
    event Purchase();
    event Buyout();
    event Claim();
    event Refund();
    event Vote(); // Check if event is available in gov
    event TransferToBroker(address indexed wallet, uint256 indexed amount);
    event StateChange(uint256 indexed auction, AuctionState indexed state);

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    /// @notice Creates new auction, mints NFT connected to auctioned asset
    /// @dev Emits Create event
    /// @param name Asset name, which is also NFT contract name
    /// @param symbol Asset symbol, which is also NFT contract symbol
    /// @param uri Asset uri, which leads to visual representation of asset linked with NFT
    /// @param price Single piece of asset price
    /// @param pieces Amount of asset pieces available for sell
    /// @param max Maximum amount of pieces that one user can buy
    /// @param openTs Timestamp when the auction opens
    /// @param closeTs Timestamp when the auction ends
    /// @param recipient Wallet address where funds from asset sale will be transferred
    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 price,
        uint256 pieces,
        uint256 max,
        uint256 openTs,
        uint256 closeTs,
        address recipient
    ) external onlyOwner {
        // Na podstawie czasu kiedy aukcja ma sie rozpoczac wywolujemy funkcje 'open' (instant start) lub 'schedule' (delayed start)
        //
        // emit Create();
    }

    // Function used for delayed auction start
    function delayedAuction() internal {}

    /// @inheritdoc IAuctioner
    function buy(uint256 id) external payable nonReentrant {
        // emit Purchase();
        //
        // If last piece bought ->
        // emit TransferToBroker();
    }

    /// @inheritdoc IAuctioner
    function buyout(uint256 id) external {
        // emit Buyout();
    }

    /// @inheritdoc IAuctioner
    function claim() external {
        // emit Claim();
    }

    /// @inheritdoc IAuctioner
    function refund() external {
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

    /// @dev HELPERS DEV ONLY
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

    function errorHack(uint256 errorType) external pure {
        // 0 - Auctioner__AuctionDoesNotExist
        // 1 - Auctioner__AuctionNotOpened
        // 2 - Auctioner__InsufficientPieces
        // 3 - Auctioner__NotEnoughFunds
        // 4 - Auctioner__TransferFailed

        if (errorType == 0) revert Auctioner__AuctionDoesNotExist();
        if (errorType == 1) revert Auctioner__AuctionNotOpened();
        if (errorType == 2) revert Auctioner__InsufficientPieces();
        if (errorType == 3) revert Auctioner__NotEnoughFunds();
        if (errorType == 4) revert Auctioner__TransferFailed();
    }
}