// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    /// @dev Errors
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__InsufficientPieces();
    error Auctioner__InsufficientFunds();
    error Auctioner__TransferFailed();
    error Auctioner__AuctionAlreadyInitialized();
    error Auctioner__ZeroValueNotAllowed();
    error Auctioner__IncorrectTimestamp();
    error Auctioner__ZeroAddressNotAllowed();
    error Auctioner__Overpayment();
    error Auctioner__BuyLimitExceeded();

    /// @dev Enums
    enum AuctionState {
        UNINITIALIZED,
        SCHEDULED,
        OPENED,
        CLOSED,
        FAILED,
        VOTING, // Rethink this while developing Governor
        FINISHED,
        ARCHIVED
    }

    /// @dev Structs
    struct Auction {
        address asset;
        uint256 price;
        uint256 pieces;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address recipient;
        AuctionState auctionState;
    }

    /// @dev Events
    event Create(uint256 indexed id, address indexed asset, uint256 price, uint256 pieces, uint256 max, uint256 start, uint256 end, address indexed recipient);
    event Schedule(uint256 indexed id, uint256 indexed start);
    event Purchase(uint256 indexed id, uint256 indexed pieces, address buyer);
    event Buyout();
    event Claim();
    event Refund(uint256 id, uint256 amount, address user);
    event Vote(); // Check if event is available in gov
    event TransferToBroker(uint256 indexed id, address indexed wallet, uint256 indexed amount);
    event StateChange(uint256 indexed id, AuctionState indexed state);

    /// @notice Allows buying pieces of asset auctioned by broker
    /// @param id Auction id that we want to interact with
    /// @param pieces Number of pieces that user wants to buy
    /// @dev Emits Purchase event and TransferToBroker event if last piece has been bought
    function buy(uint256 id, uint256 pieces) external payable;

    /// @notice Allows making an offer to buy a certain asset auctioned by broker instantly
    /// @param id Auction id that we want to interact with
    function buyout(uint256 id) external payable;

    /// @notice Allows claiming revenue from pieces bought by buyers if auction closed successfully
    function claim() external;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    function refund(uint256 id) external;
}
