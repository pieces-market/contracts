# 📃 **Documentation**

## <u>**Auctioner Contract Structure**</u>

### **Error Handling**

-   **`AuctionDoesNotExist:`** Error thrown when attempting to interact with a non-existent auction
-   **`AuctionNotOpened:`** Error thrown when attempting to perform an action on an auction that hasn't opened yet
-   **`AuctionNotFailed:`** Error thrown when user tries to refund but auction is not in failed state
-   **`InsufficientPieces`**: Error thrown when there aren't enough pieces left to fulfill an order
-   **`InsufficientFunds:`** Error thrown when there are insufficient funds for an action
-   **`TransferFailed:`** Error thrown when a fund transfer operation fails
-   **`AuctionAlreadyInitialized:`** Error thrown when admin calls create on existing auction
-   **`ZeroValueNotAllowed:`** Error thrown when a zero value is provided as parameter where it is not allowed
-   **`IncorrectTimestamp:`** Error thrown when a provided timestamp is incorrect or invalid
-   **`ZeroAddressNotAllowed:`** Error thrown when a zero address is provided where it is not allowed
-   **`Overpayment:`** Error thrown when an overpayment is detected in buy or buyout functions
-   **`BuyLimitExceeded:`** Error thrown when the buy limit of pieces for an auction is exceeded

### **Auction States**

-   **`UNINITIALIZED:`** Auction has not been initialized
-   **`SCHEDULED:`** Auction has been initialized and awaits its start date
-   **`OPENED:`** Auction ready to get orders for asset pieces
-   **`CLOSED:`** Auction finished positively - all asset pieces sold
-   **`FAILED:`** Auction finished negatively - not all asset pieces bought in given time, buyers can refund
-   **`VOTING:`** Active buyout offer, buyers vote to accept or decline this offer
-   **`FINISHED:`** All funds gathered from closed auction have been transferred to broker and broker transferred revenues to contract, buyers can claim revenues
-   **`ARCHIVED:`** Everyone claimed their revenues, investment ultimately closed

### **Auction Structure**

-   **`address asset:`** Address of NFT related to auctioned asset
-   **`uint256 price:`** Single piece of asset price
-   **`uint256 pieces:`** Total number of pieces available for sale
-   **`uint256 max:`** Maximum number of pieces one user can buy
-   **`uint256 openTs:`** Timestamp when the auction opens
-   **`uint256 closeTs:`** Timestamp when the auction ends
-   **`address recipient:`** Wallet address where funds from asset sale will be transferred
-   **`AuctionState state:`** Current state of the auction

### **Events**

-   **`Create:`** Emitted when a new auction is created.
-   **`Schedule:`** Emitted when auction is created with open timestamp in future.
-   **`Purchase:`** Emitted when pieces of an auction are bought.
-   **`Buyout:`** Emitted when a buyout offer is made for an auction.
-   **`Claim:`** Emitted when revenue is claimed from an auction.
-   **`Refund:`** Emitted when a refund is requested for an auction.
-   **`Vote:`** (Additional event check if event is available in gov)
-   **`TransferToBroker:`** Emitted when funds are transferred to the broker.
-   **`StateChange:`** Emitted when the state of an auction changes.

## <u>**Asset Contract Structure**</u>

## <u>**Governor Contract Structure**</u>

### **Error Handling**

-   **`ProposalDoesNotExist:`** Error thrown when interacting with a non-existent proposal
-   **`ProposalNotActive:`** Error thrown when attempting to vote on a non-active proposal
-   **`AlreadyVoted:`** Error thrown when attempting to vote more than once
-   **`ZeroVotingPower:`** Error thrown when a user with zero voting power attempts to vote

### **Proposal States**

-   **`INACTIVE:`** Proposal does not exist
-   **`ACTIVE:`** Proposal is currently open for voting
-   **`PASSED:`** Proposal passed and is ready to be executed
-   **`SUCCEEDED:`** Proposal successfully executed
-   **`FAILED:`** Proposal did not pass and awaits cancellation
-   **`CANCELLED:`** Proposal did not pass and has been cancelled

### **Vote Types**

-   **`FOR:`** Indicates a vote in favor of the proposal
-   **`AGAINST:`** Indicates a vote against the proposal
-   **`ABSTAIN:`** Indicates an abstention from voting

### **Proposal Structure**

-   **`address asset:`** Address of the asset linked to the proposal
-   **`uint256 voteStart:`** Timestamp when voting starts
-   **`uint256 voteEnd:`** Timestamp when voting ends
-   **`string description:`** Description of the proposal
-   **`uint256 forVotes:`** Number of votes in favor of the proposal
-   **`uint256 againstVotes:`** Number of votes against the proposal
-   **`uint256 abstainVotes:`** Number of abstaining votes
-   **`ProposalState state:`** Current state of the proposal

### **Events**

-   **`Propose:`** Emitted when a new proposal is created
-   **`StateChange:`** Emitted when the state of a proposal changes
