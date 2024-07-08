// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    /// @dev Errors
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__InsufficientPieces();
    error Auctioner__NotEnoughFunds();
    error Auctioner__TransferFailed();
    error Auctioner__AuctionAlreadyInitialized();
    error Auctioner__ZeroValueNotAllowed();
    error Auctioner__IncorrectTimestamp();
    error Auctioner__ZeroAddressNotAllowed();

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
        string uri; // we need to pass it into FractAsset.sol
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

    /// @dev Events
    event Create();
    event Plan();
    event Purchase();
    event Buyout();
    event Claim();
    event Refund();
    event Vote(); // Check if event is available in gov
    event TransferToBroker(address indexed wallet, uint256 indexed amount);
    event StateChange(uint256 indexed auction, AuctionState indexed state);

    /// @notice Allows buying pieces of asset auctioned by broker
    /// @param id Auction id that we want to interact with
    /// @dev Emits Purchase event and TransferToBroker event if last piece has been bought
    function buy(uint256 id) external payable;

    /// @notice Allows making an offer to buy a certain asset auctioned by broker instantly
    /// @param id Auction id that we want to interact with
    function buyout(uint256 id) external payable;

    /// @notice Allows claiming revenue from pieces bought by buyers if auction closed successfully
    function claim() external;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    function refund() external;
}
