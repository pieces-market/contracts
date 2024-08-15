# Todo

0. Search '-> call' for code to discuss on pieces call
1. Write buyout function and connect it with Governor contract
2. Consider Auctioner automation by Chainlink or RedStone?
3. Implement fees on buy and buyout

# Gas Calculation

`forge test --gas-report`
transaction cost(Remix) \* https://etherscan.io/gastracker -> GWEI: convert GWEI https://eth-converter.com/ into USD

# Vlayer

Use Cases:

1. Time travel -> dostep do starych danych, daje mozliwosc przeliczenia ponownie czy cos jest poprawne. Daje dostep do bardzo starych danych, ktorych potrzebujemy.
2. Calculation And Check -> Liczenie i przemieszczanie sie po innych chainach zeby porownac dane (laczy sie z time travel) otrzymac je na nowo.
3. Cryptography -> Dowod kryptograficzny na maila lub inne poswiadczenia.

# Pick One:

1. Paytweed contract will be calling our and we must give them permission for minting.
2. Funds will stay on their contract and NFT will be on user wallet, so we would need to refactor whole code

**Tweed** - missing customizable UI, strange solutions for handling contract calls.

**Web3Auth** - they are using "Fiat On-Ramp Aggregator", it integrates fiat on-ramp providers that allow users to convert fiat to cryptocurrency. Once the user has cryptocurrency in their wallet, they can use it to purchase NFTs from our contract. They also allow no-modal solution, so we can use their functionality and our design. Pricing: Free for up to 1000 monthly active users then 69$++ per month with additional features. +0.05$ per additional MAU. Minus is that on-ramp solution costs at least 399$ per month.

**Dynamic** - Similar to Privy they do not offer fiat/on-ramp payments directly. They use 3rd party named Banxa. Modals are totally customizable and they allow entirely decouple a frontend from Dynamic and still enable onboarding experiences. Pricing: FIRST 200 monthly active users then 99$ per month up to 2k MAUs 0.05$ per MAU thereafter. On-ramp feature available in free mode and for 99$ per month if we pass MAU limit.

automatyczne testy -> poszukac automatycznych testerow kontraktow. Cromtab
ipfs -> apillon
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
