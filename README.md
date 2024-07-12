## 🔬 **What Is pieces.market?**

## 🚀 **Deployments**

-   **Aleph Zero Testnet:** 0x89C9040709ebce46e3b68E75c2664653E9816c9B
-   **Sepolia:** 0x5bbdCB1cA918FB54Ef2f42fd7550F37273C43534

## 👷‍♂️ **To Implement**

-   mozliwosc glosowania jesli pojawi sie oferta wykupu assetu (early buyout) (tylko do wykupu)
    [ktos wrzuca kase do tego wykupu na kontrakt -> udzialowcy glosuja -> decyzja i albo wykup kasa do udzialowcow albo zwrot]
-   starting price 100 usd

## 📃 **Documentation**

### Contracts Structure

### Auction States -> This will be moved into IAuctioner

-   **`UNINITIALIZED:`** Auction has not been initialized
-   **`SCHEDULED:`** Auction has been initialized and awaits its start date
-   **`OPENED:`** Auction ready to get orders for asset pieces
-   **`CLOSED:`** Auction finished positively - all asset pieces sold
-   **`FAILED:`** Auction finished negatively - not all asset pieces bought, buyers can refund
-   **`VOTING:`** Active buyout offer, buyers vote to accept or decline this offer
-   **`FINISHED:`** All funds gathered from closed auction transferred to broker and broker transferred revenues to contract, buyers can claim revenues
-   **`ARCHIVED:`** Everyone claimed their revenues, investment ultimately closed

### Auction Structure -> This will be moved into IAuctioner

-   **`address asset:`** Address of NFT related to auctioned asset
-   **`uint256 price:`** Single piece of asset price
-   **`uint256 pieces:`** Total number of pieces available for sale
-   **`uint256 max:`** Maximum number of pieces one user can buy
-   **`uint256 openTs:`** Timestamp when the auction opens
-   **`uint256 closeTs:`** Timestamp when the auction ends
-   **`address recipient:`** Wallet address where funds from asset sale will be transferred
-   **`auctionState:`** Current state of the auction

### Error Handling -> This will be moved into IAuctioner

-   **`AuctionDoesNotExist:`** Error thrown when attempting to interact with a non-existent auction
-   **`AuctionNotOpened:`** Error thrown when attempting to perform an action on an auction that hasn't opened yet
-   **`InsufficientPieces`**: Error thrown when there aren't enough pieces left to fulfill an order
-   **`NotEnoughFunds:`** Error thrown when there are insufficient funds for an action
-   **`TransferFailed:`** Error thrown when a fund transfer operation fails

### Events -> This will be moved into IAuctioner

-   **`Create:`** Emitted when a new auction is created.
-   **`Schedule:`** Emitted when auction is created with open timestamp in future.
-   **`Purchase:`** Emitted when pieces of an auction are bought.
-   **`Buyout:`** Emitted when a buyout offer is made for an auction.
-   **`Claim:`** Emitted when revenue is claimed from an auction.
-   **`Refund:`** Emitted when a refund is requested for an auction.
-   **`Vote:`** (Additional event check if event is available in gov)
-   **`TransferToBroker:`** Emitted when funds are transferred to the broker.
-   **`StateChange:`** Emitted when the state of an auction changes.

### License

    This contract is licensed under the GNU General Public License v3.0 or later.
