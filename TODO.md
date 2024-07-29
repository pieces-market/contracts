# Todo

0. Documentation for Governor
1. Write buyout function and connect it with Governor contract
2. Consider Auctioer automation by Chainlink or RedStone?

# Gas Calculation

`forge test --gas-report`
transaction cost(Remix) \* https://etherscan.io/gastracker -> GWEI: convert GWEI https://eth-converter.com/ into USD

# Tweed:

Requirements:

-   Our claimer needs to have a minter role in the contract.
-   Aleph network not supported
-   Gone are the days of purchasing crypto, going through KYC, and understanding gas fees!

# Vlayer

Use Cases:

1. Time travel -> dostep do starych danych, daje mozliwosc przeliczenia ponownie czy cos jest poprawne. Daje dostep do bardzo starych danych, ktorych potrzebujemy.
2. Calculation And Check -> Liczenie i przemieszczanie sie po innych chainach zeby porownac dane (laczy sie z time travel) otrzymac je na nowo.
3. Cryptography -> Dowod kryptograficzny na maila lub inne poswiadczenia.
