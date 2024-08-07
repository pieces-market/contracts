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

# Tweed:

1. Paytweed contract will be calling our and we must give them permission for minting.
2. Funds will stay on their contract and NFT will be on user wallet, so we would need to refactor whole code
