# Todo

1. Consider refactor for 'Propose' events on Auctioner and Governor to keep ProposalType only in one of those and avoid duplication

# Gas Calculation

`forge test - - gas- report`
transaction cost(Remix) \* https://etherscan.io/gastracker - > GWEI: convert GWEI https://eth- converter.com/ into USD

# Vlayer

Use Cases:

1. Time travel - > dostep do starych danych, daje mozliwosc przeliczenia ponownie czy cos jest poprawne. Daje dostep do bardzo starych danych, ktorych potrzebujemy.
2. Calculation And Check - > Liczenie i przemieszczanie sie po innych chainach zeby porownac dane (laczy sie z time travel) otrzymac je na nowo.
3. Cryptography - > Dowod kryptograficzny na maila lub inne poswiadczenia.

# Pick One:

1. Paytweed contract will be calling our and we must give them permission for minting.
2. Funds will stay on their contract and NFT will be on user wallet, so we would need to refactor whole code

**Tweed** - missing customizable UI, strange solutions for handling contract calls.

**Web3Auth** - they are using "Fiat On- Ramp Aggregator", it integrates fiat on- ramp providers that allow users to convert fiat to cryptocurrency. Once the user has cryptocurrency in their wallet, they can use it to purchase NFTs from our contract. They also allow no- modal solution, so we can use their functionality and our design. Pricing: Free for up to 1000 monthly active users then 69$++ per month with additional features. +0.05$ per additional MAU. Minus is that on- ramp solution costs at least 399$ per month.

**Dynamic** - Similar to Privy they do not offer fiat/on- ramp payments directly. They use 3rd party named Banxa. Modals are totally customizable and they allow entirely decouple a frontend from Dynamic and still enable onboarding experiences. Pricing: FIRST 200 monthly active users then 99$ per month up to 2k MAUs 0.05$ per MAU thereafter. On- ramp feature available in free mode and for 99$ per month if we pass MAU limit.

automatyczne testy - > poszukac automatycznych testerow kontraktow. Cromtab
ipfs - > apillon
crosschain
unit testy

# Automated Testing

-   Chainlink Keepers:
-   We can perform tests on Sepolia only
-   Gelato Network:
-   Use hardhat to create calls with random addresses and arguments etc.
-   Use foundry and create script that we can just run from time to time manually.
-   Keep calling fn with same args using automation or with random args using same wallet.
-   OpenZeppelin Defender:
-   To be checked

# TODO

### 2- 3dni

-   Rozpisac baze danych
-   Deploy new contract version on Aleph
-   5- 10 aukcji w każdym możliwym statusie, na początek, każdy stan który inaczej wygląda na UI.
-   Testy proces ciągły, ale kilka dni potrzebnych na pierwszą wersję.

### 2dni

-   Obsługa IPFSa, implementacja w API

*   Wyprowadzenie wszystkich endpointów, mocki danych? czy już z bazy z blockchaina?
*   Obsłużenie blockchain eventów, zapis do bazy

### NA WRZESIEŃ:

-   Cross- chain
-   Zabezpieczenie API - Adam

# DATABASE

### Create Auction

POST /auctions/create
Parameters: name, symbol, uri, price, pieces, max, start, span, recipient
Function: create

### Buy Pieces

POST /auctions/:id/buy
Parameters: pieces
Function: buy

### Propose -> Governor

POST /proposals/:id/propose
Parameters: description, proposal
Function: propose

### CastVote -> Governor

POST /proposals/:id/vote
Parameters: proposalId, voteType, votes
Function: castVote

### Withdraw Funds

POST /auctions/:id/withdraw
Function: withdraw

### Refund

POST /auctions/:id/refund
Function: refund

### Fulfill

POST /auctions/:id/fulfill
Parameters: amount
Function: fulfill

### Claim

POST /auctions/:id/claim
Function: claim

## Structure

Tables

`unconfirmed auctions`

-   id (INT, Primary Key, Auto Increment)
-   asset (VARCHAR(42)) - Address of the NFT contract
-   price (DECIMAL(18, 4)) - Price per piece
-   pieces (INT) - Total number of pieces available
-   max (INT) - Maximum number of pieces one user can buy
-   openTs (DATETIME) - Auction start timestamp
-   closeTs (DATETIME) - Auction end timestamp
-   recipient (VARCHAR(42)) - Wallet address for fund transfer
-   state (ENUM) - Auction state (UNINITIALIZED, SCHEDULED, OPENED, CLOSED, FAILED, FINISHED, ARCHIVED)

`active auctions`

-   id (INT, Primary Key, Auto Increment)
-   asset (VARCHAR(42)) - Address of the NFT contract
-   price (DECIMAL(18, 4)) - Price per piece
-   pieces (INT) - Total number of pieces available
-   max (INT) - Maximum number of pieces one user can buy
-   openTs (DATETIME) - Auction start timestamp
-   closeTs (DATETIME) - Auction end timestamp
-   recipient (VARCHAR(42)) - Wallet address for fund transfer
-   state (ENUM) - Auction state (UNINITIALIZED, SCHEDULED, OPENED, CLOSED, FAILED, FINISHED, ARCHIVED)

`buy`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   pieces (INT) - Total number of pieces bought
-   buyer (VARCHAR(42)) - Address of the buyer

`proposals`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   description (TEXT) - Description of the proposal
-   proposalType (ENUM) - Proposal type (BUYOUT, DESCRIPT)
-   offerer (VARCHAR(42)) - Address of the proposer
-   amount (DECIMAL(18, 4)) - Amount offered (if applicable)

`buyouts`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   offerer (VARCHAR(42)) - Address of the offerer
-   amount (DECIMAL(18, 4)) - Amount of the offer

`withdrawals`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   amount (DECIMAL(18, 4)) - Amount withdrawn
-   offerer (VARCHAR(42)) - Address of the offerer

`descripts`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   description (TEXT) - Description of the proposal

`refunds`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   user (VARCHAR(42)) - Address of the user requesting the refund
-   amount (DECIMAL(18, 4)) - Amount refunded

`claims`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   user (VARCHAR(42)) - Address of the user claiming revenue
-   amount (DECIMAL(18, 4)) - Amount claimed

`events`

-   id (INT, Primary Key, Auto Increment)
-   auctionId (INT, Foreign Key) - Reference to auctions.id
-   eventType (ENUM) - Type of the event (Create, Schedule, Purchase, etc.)
-   timestamp (DATETIME) - Timestamp of the event

`Foreign Keys:`

-   offers.auctionId references auctions.id
-   proposals.auctionId references auctions.id
-   refunds.auctionId references auctions.id
-   claims.auctionId references auctions.id
-   withdrawals.auctionId references auctions.id
-   events.auctionId references auctions.id

`Indexes:`

-   Index on auctions(state) for quick state lookups.
-   Index on offers(offerer) for efficient querying of offers by user.
-   Index on proposals(proposalType) for filtering proposals by type.
-   Index on refunds(user) and claims(user) for user- specific queries.
