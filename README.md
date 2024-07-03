## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

NFT - pNFT (mint)

-   predefiniowany czas trwania inwestycji
-   mozliwosc glosowania jesli pojawi sie oferta wykupu assetu (early buyout) (tylko do wykupu)
    [ktos wrzuca kase do tego wykupu na kontrakt -> udzialowcy glosuja -> decyzja i albo wykup kasa do udzialowcow albo zwrot]
-   starting price 100 usd
-   broker moze dodawac aukcje
-   mozliwosc handlu nft na rynku wtornym

## Documentation

### Auction States

-   **`UNINITIALIZED:`** Auction has not been initialized
-   **`PLANNED:`** Auction has been initialized and awaits its start date
-   **`OPENED:`** Auction ready to get orders for asset pieces
-   **`CLOSED:`** Auction finished positively - all asset pieces sold
-   **`FAILED:`** Auction finished negatively - not all asset pieces bought, buyers can refund
-   **`VOTING:`** Active buyout offer, buyers vote to accept or decline this offer
-   **`FINISHED:`** All funds gathered from closed auction transferred to broker and broker transferred revenues to contract, buyers can claim revenues
-   **`ARCHIVED:`** Everyone claimed their revenues, investment ultimately closed

### Auction Structure

-   **`auctionState:`** Represents the current state of the auction

### Error Handling

-   **`AuctionDoesNotExist:`** Error thrown when attempting to interact with a non-existent auction
-   **`AuctionNotOpened:`** Error thrown when attempting to perform an action on an auction that hasn't opened yet
-   **`InsufficientPieces`**: Error thrown when there aren't enough pieces left to fulfill an order
-   **`NotEnoughFunds:`** Error thrown when there are insufficient funds for an action
-   **`TransferFailed:`** Error thrown when a fund transfer operation fails

### Events

-   **`Create:`** Emitted when a new auction is created.
-   **`Purchase:`** Emitted when pieces of an auction are bought.
-   **`Buyout:`** Emitted when a buyout offer is made for an auction.
-   **`Claim:`** Emitted when revenue is claimed from an auction.
-   **`Refund:`** Emitted when a refund is requested for an auction.
-   **`Vote:`** (Additional event check if event is available in gov)
-   **`TransferToBroker:`** Emitted when funds are transferred to the broker.
-   **`StateChange:`** Emitted when the state of an auction changes.

### License

    This contract is licensed under the GNU General Public License v3.0 or later.
