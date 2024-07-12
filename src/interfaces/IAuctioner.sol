// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__AuctionNotFailed();
    error Auctioner__InsufficientPieces();
    error Auctioner__InsufficientFunds();
    error Auctioner__TransferFailed();
    error Auctioner__AuctionAlreadyInitialized();
    error Auctioner__ZeroValueNotAllowed();
    error Auctioner__IncorrectTimestamp();
    error Auctioner__ZeroAddressNotAllowed();
    error Auctioner__Overpayment();
    error Auctioner__BuyLimitExceeded();

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

    struct Auction {
        address asset;
        uint256 price;
        uint256 pieces;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address recipient;
        AuctionState state;
    }

    /// @notice Emitted when an auction is created
    /// @param id The id of the auction
    /// @param asset The address of the NFT related to the auctioned asset
    /// @param price The price per piece of the asset
    /// @param pieces The total number of pieces available for sale
    /// @param max The maximum number of pieces one user can buy
    /// @param start The timestamp when the auction opens
    /// @param end The timestamp when the auction ends
    /// @param recipient The wallet address where funds from asset sale will be transferred
    event Create(uint256 indexed id, address indexed asset, uint256 price, uint256 pieces, uint256 max, uint256 start, uint256 end, address indexed recipient);

    /// @notice Emitted when an auction is created for timestamp in future
    /// @param id The id of the auction
    /// @param start The timestamp when the auction is scheduled to open
    event Schedule(uint256 indexed id, uint256 indexed start);

    /// @notice Emitted when pieces of an auction are bought
    /// @param id The id of the auction
    /// @param pieces The number of pieces bought
    /// @param buyer The address of the buyer
    event Purchase(uint256 indexed id, uint256 indexed pieces, address buyer);

    /// @notice Emitted when an early buyout offer is made for an auction
    event Buyout();

    /// @notice Emitted when revenue is claimed from an auction
    event Claim();

    /// @notice Emitted when a refund is requested for an auction
    /// @param id The id of the auction
    /// @param amount The amount refunded
    /// @param user The address of the user requesting the refund
    event Refund(uint256 id, uint256 amount, address user);

    /// @notice Emitted when a vote is cast for a buyout offer
    event Vote(); // Check if event is available in gov

    /// @notice Emitted when all pieces has been sold and funds are transferred to the broker
    /// @param id The id of the auction
    /// @param wallet The wallet address of the broker
    /// @param amount The amount transferred
    event TransferToBroker(uint256 indexed id, address indexed wallet, uint256 indexed amount);

    /// @notice Emitted when the state of an auction changes
    /// @param id The id of the auction
    /// @param state The new state of the auction
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
    /// @param id Auction id that we want to interact with
    function claim(uint256 id) external;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    /// @param id Auction id that we want to interact with
    function refund(uint256 id) external;
}
