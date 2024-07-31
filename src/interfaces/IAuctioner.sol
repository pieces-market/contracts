// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__AuctionNotClosed();
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
    error Auctioner__FunctionCallFailed();
    error Auctioner__ProposalInProgress();

    enum AuctionState {
        UNINITIALIZED,
        SCHEDULED,
        OPENED,
        CLOSED,
        FAILED,
        FINISHED,
        ARCHIVED
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

    /// @param id The id of the auction
    /// @param amount The amount of the offer transferred to contract
    /// @param offerer The address of the user that made offer
    event Offer(uint256 indexed id, uint256 indexed amount, address indexed offerer);

    /// @notice Emitted when an early buyout offer is made for an auction
    event Buyout();

    /// @notice Emitted when revenue is claimed from an auction
    event Claim();

    /// @notice Emitted when a refund has been executed
    /// @param id The id of the auction
    /// @param amount The amount refunded
    /// @param user The address of the user requesting the refund
    event Refund(uint256 indexed id, uint256 indexed amount, address indexed user);

    /// @notice Emitted when a withdraw has been executed
    /// @param id The id of the auction
    /// @param amount The amount withdrew
    /// @param offerer The address of the user requesting the withdrawal
    event Withdraw(uint256 indexed id, uint256 indexed amount, address indexed offerer);

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

    /// @notice Makes an offer to modify auction assumptions
    /// @dev Creates proposal by calling Governor contract
    /// @param id Auction id that we want to interact with
    /// @param description Auction id that we want to interact with
    function makeOffer(uint256 id, string memory description) external payable;

    /// @notice Allows withdrawing funds transferred with offer if proposal fails
    /// @param id Auction id that we want to interact with
    function withdrawOffer(uint256 id) external;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    /// @param id Auction id that we want to interact with
    function refund(uint256 id) external;

    /// @notice Allows claiming revenue from pieces bought by buyers if auction closed successfully
    /// @param id Auction id that we want to interact with
    function claim(uint256 id) external;
}
