// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    /// @dev Consider merging errors for state into AuctionIncorrectState
    error Auctioner__AuctionDoesNotExist();
    error Auctioner__AuctionNotOpened();
    error Auctioner__AuctionNotClosed();
    error Auctioner__AuctionNotFailed();
    error Auctioner__AuctionNotFinished();
    error Auctioner__InsufficientPieces();
    error Auctioner__InsufficientFunds();
    error Auctioner__TransferFailed();
    error Auctioner__AuctionAlreadyInitialized();
    error Auctioner__ZeroValueNotAllowed();
    error Auctioner__IncorrectTimestamp();
    error Auctioner__ZeroAddressNotAllowed();
    error Auctioner__Overpayment();
    error Auctioner__BuyLimitExceeded();
    error Auctioner__ProposalInProgress();
    error Auctioner__UnauthorizedCaller();
    error Auctioner__InvalidProposalType();
    error Auctioner__IncorrectDescriptionSize();
    error Auctioner__IncorrectFundsTransfer();
    error Auctioner__NotEligibleCaller();

    enum AuctionState {
        UNINITIALIZED,
        SCHEDULED,
        OPENED,
        CLOSED,
        FAILED,
        FINISHED,
        ARCHIVED
    }

    enum ProposalType {
        BUYOUT,
        DESCRIPT
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
    /// @param royalty The royalty fee (BIPS) to be paid to the @param recipient on each secondary sale, as per the ERC2981 standard
    /// @param brokerFee The broker share (BIPS) of the royalty fee
    event Create(
        uint256 indexed id,
        address indexed asset,
        uint256 price,
        uint256 pieces,
        uint256 max,
        uint256 start,
        uint256 end,
        address indexed recipient,
        uint96 royalty,
        uint256 brokerFee
    );

    /// @notice Emitted when an auction is created for timestamp in future
    /// @param id The id of the auction
    /// @param start The timestamp when the auction is scheduled to open
    event Schedule(uint256 indexed id, uint256 indexed start);

    /// @notice Emitted when pieces of an auction are bought
    /// @param id The id of the auction
    /// @param pieces The number of pieces bought
    /// @param buyer The address of the buyer
    event Purchase(uint256 indexed id, uint256 indexed pieces, address indexed buyer);

    /// @notice Emitted when proposal request has been sent to Governor contract
    /// @param id The id of the auction
    /// @param amount The amount of the offer transferred to contract
    /// @param offerer The address of the user that made offer
    event Propose(uint256 indexed id, uint256 indexed amount, address indexed offerer);

    /// @notice Emitted when proposal fails
    /// @param id The id of the auction
    event Reject(uint256 indexed id);

    /// @notice Emitted when voting passes for buyout proposal
    /// @param id The id of the auction
    /// @param offerer The wallet address of the offerer
    /// @param amount The amount paid
    event Buyout(uint256 indexed id, uint256 indexed amount, address indexed offerer);

    /// @notice Emitted when voting passes for descript proposal
    /// @param id The id of the auction
    /// @param description Description of the proposal
    event Descript(uint256 indexed id, string description);

    /// @notice Emitted when a refund has been executed
    /// @param id The id of the auction
    /// @param amount The amount refunded
    /// @param refunder The address of the user requesting the refund
    event Refund(uint256 indexed id, uint256 indexed amount, address indexed refunder);

    /// @notice Emitted when a withdraw has been executed
    /// @param id The id of the auction
    /// @param amount The amount withdrew
    /// @param offerer The address of the user requesting the withdrawal
    event Withdraw(uint256 indexed id, uint256 indexed amount, address indexed offerer);

    /// @notice Emitted when a fulfill has been executed
    /// @param id The id of the auction
    /// @param amount The amount fulfill
    /// @param fulfiller The address of the user performing the fulfill
    event Fulfill(uint indexed id, uint indexed amount, address indexed fulfiller);

    /// @notice Emitted when revenue is claimed from an auction
    /// @param id The id of the auction
    /// @param amount The amount claimed
    /// @param claimer The address of the user requesting the claim
    event Claim(uint256 indexed id, uint256 indexed amount, address indexed claimer);

    /// @notice Emitted when all pieces has been sold and funds are transferred to the broker
    /// @param id The id of the auction
    /// @param wallet The wallet address of the broker
    /// @param amount The amount transferred
    event TransferToBroker(uint256 indexed id, uint256 indexed amount, address indexed wallet);

    /// @notice Emitted when the state of an auction changes
    /// @param id The id of the auction
    /// @param state The new state of the auction
    event StateChange(uint256 indexed id, AuctionState indexed state);

    /// @notice Emitted when the royalty fee has been split successfully between the broker and the pieces market
    /// @param asset The address of the NFT that received royalty payment
    /// @param sender The address that sent the royalty fee
    /// @param broker The address that receives broker share of royalty payment
    /// @param brokerShare The portion of the royalty fee sent to the broker
    /// @param piecesMarket The address of the pieces market wallet that receives share of royalty payment
    /// @param piecesMarketShare The portion of the royalty fee sent to the pieces market
    /// @param value The total value of the royalty fee
    event RoyaltySplitExecuted(
        address asset,
        address sender,
        address indexed broker,
        uint256 indexed brokerShare,
        address piecesMarket,
        uint256 indexed piecesMarketShare,
        uint256 value
    );

    /// @notice Allows buying pieces of asset auctioned by broker
    /// @param id Auction id that we want to interact with
    /// @param pieces Number of pieces that user wants to buy
    /// @dev Emits Purchase event and TransferToBroker event if last piece has been bought
    function buy(uint256 id, uint256 pieces) external payable;

    /// @notice Creates proposal by calling Governor contract
    /// @param id Auction id that we want to interact with
    /// @param description Description of the proposal
    /// @param proposal Type of the proposal (0 - BUYOUT, 1 - DESCRIPT)
    function propose(uint256 id, string memory description, ProposalType proposal) external payable;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    /// @param id Auction id that we want to interact with
    function refund(uint256 id) external;

    /// @notice Allows withdrawing funds transferred with offer if proposal fails
    /// @param id Auction id that we want to interact with
    function withdraw(uint256 id) external;

    /// @notice Fulfills agreement details allowing investors to claim
    /// @param id Auction id that we want to interact with
    function fulfill(uint256 id) external payable;

    /// @notice Allows claiming revenue from pieces bought by buyers if auction closed successfully
    /// @param id Auction id that we want to interact with
    function claim(uint256 id) external;
}
