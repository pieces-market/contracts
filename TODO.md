# Todo

1. Mock transactions on Aleph Zero blockchain testnet to reproduce all possible states of auction along with proposals and other possible transactions and branches
2. Implement fee's into 'Auctioner' 'buy' function
3. Refactor 'Auctioner' functions to check equivalent of USD value instead of native blockchain currency (we will be using Oracles to get proper price feeds here)
4. Implement Vlayer solution into 'Auctioner' 'fulfill' function to ensure cryptographic proof has been provided via email or other credentials
5. Implement Cross Chain solution
6. Consider implementing starting/minimal price for example 100 USD per piece
7. Consider refactor for 'Propose' events on 'Auctioner' and 'Governor' to keep 'ProposalType' only in one of those and avoid duplication
8. Fix all unit tests and implement advanced testing (fuzz testing and invariant, differential testing - if needed)

# Vlayer

Use Cases:

1. Time travel - > dostep do starych danych, daje mozliwosc przeliczenia ponownie czy cos jest poprawne. Daje dostep do bardzo starych danych, ktorych potrzebujemy.
2. Calculation And Check - > Liczenie i przemieszczanie sie po innych chainach zeby porownac dane (laczy sie z time travel) otrzymac je na nowo.
3. Cryptography - > Dowod kryptograficzny na maila lub inne poswiadczenia.

# FIAT payments:

**Tweed** - missing customizable UI, strange solutions for handling contract calls.

**Web3Auth** - they are using "Fiat On- Ramp Aggregator", it integrates fiat on- ramp providers that allow users to convert fiat to cryptocurrency. Once the user has cryptocurrency in their wallet, they can use it to purchase NFTs from our contract. They also allow no- modal solution, so we can use their functionality and our design. Pricing: Free for up to 1000 monthly active users then 69$++ per month with additional features. +0.05$ per additional MAU. Minus is that on- ramp solution costs at least 399$ per month.

**Dynamic** - Similar to Privy they do not offer fiat/on- ramp payments directly. They use 3rd party named Banxa. Modals are totally customizable and they allow entirely decouple a frontend from Dynamic and still enable onboarding experiences. Pricing: FIRST 200 monthly active users then 99$ per month up to 2k MAUs 0.05$ per MAU thereafter. On- ramp feature available in free mode and for 99$ per month if we pass MAU limit.

# Gas Calculation

`forge test - - gas- report`
transaction cost(Remix) \* https://etherscan.io/gastracker - > GWEI: convert GWEI https://eth- converter.com/ into USD
