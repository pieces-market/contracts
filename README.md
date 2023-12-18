# <img src="logo.png" alt="Pieces.market">

[![Legal](https://img.shields.io/badge/docs-%F0%9F%93%84-yellow)](https://todo)
[![Discord](https://img.shields.io/badge/forum-%F0%9F%92%AC-yellow)](https://todo)
[![GPLv3](https://img.shields.io/badge/license-GPLv3-blue.svg)](https://choosealicense.com/licenses/gpl-3.0/)

## Pieces market contracts

**Repository for secure smart contract development.** Build on a solid foundation of community-vetted code.

 * Asset Auction [`auction.sol`](https://github.com/pieces-market/contracts/auction.sol)
 * Buyout Governor [`buyout_gov.sol`](https://github.com/pieces-market/contracts/buyout_gov.sol)

This repository contains the smart contracts used by [Pieces market](https://pieces.market) platform.
   
> [!IMPORTANT]
> Pieces.market contracts are not backward compatible, it's unsafe to assume that newer version have the same functions or state variables.
> We are still in the early phase, so follow us on social media for new updates and take part in our revolution in the luxury market.
> 

## Our mission
Revolution in access to the luxury market.

Many luxury investments are great value stores, some may even be recession-proof. They have been in investors’ crosshairs for the last few years, driving prices up and creating handsome returns. However, due to high entry price, luxury market is still reserved just for the wealthiest. We believe that with assets sovereignty and digitalization coming to Web3, investing in high-class luxury assets should be easy and available for everyone.

## Overview

Current implementation (MVP) is dedicated to allow to fractionalize NFT ERC721, break down high-value NFT into thousands of pNFTs (pieces), making them accessible to crypto-investors.
 
### Asset Auction [`auction.sol`](https://github.com/pieces-market/contracts/auction.sol)

TODO:
Auction.sol is solidity smart contract responsible for:
- auction configuration by asset Broker
- burning new fractionalized pNFTs (pieces)
- distributing investors payments to Broker
- allow lock deposit and execute buyout NFT proposal
- revenue redistribution

### Buyout Governor [`buyout_gov.sol`](https://github.com/pieces-market/contracts/buyout_gov.sol)

Buyout Governor is solidity smart contract responsible for governing proposals to buyout asset from cyprto investors.

### Demo - MVP

To better understand the usage scenarios, please don't hesitate to visit Our test environment.
It requires:
 * [MetaMask wallet](https://metamask.io)
 * Moonbase Alpha account with DEV tokens
 * Moonbase Alpha DEV tokens [DEV currency faucet](https://apps.moonbeam.network/moonbase-alpha/faucet/)

### [Pieces market MVP site](https://test.pieces.market)


### Project Nomenclature

To better understand auction life-cycle we strongly advise to understand following concepts first:

* pieces (also called as pNFTs) - ERC-721 tokens enabling investment in assets on the platform grant users voting rights in governance over asset sales and allow them to claim their share of revenue after the asset is sold

* fractionalization - the process allowing users to invest in a specific asset by paying only a percentage of its total value. It involves issuing tokens, granting owners the right to co-decide on the fractionalized asset and to receive a proportional share of revenue after the asset is sold

* asset - In the pieces.market model, physical luxury assets (watches, cars, yachts, etc.) undergo fractionalization. The technological MVP uses ERC-721 tokens to simulate physical assets

* platform - the UI at demo.pieces.market allows users to interact with smart contracts

* guest - a person on the platform who is not logged in by connecting their wallet, and therefore can only browse auctions on the platform

* user - a person on the platform who is logged in by connecting their wallet, with privileges including the ability to purchase pieces

* broker - an individual or organization selling an asset, with additional privileges like creating and editing auction details

* administrator - pieces.market employee overseeing the creation and management of auctions

* auction - a mechanism lasting a specific duration, during which users have the opportunity to purchase pieces of a specific asset

* platform fee - an additional percentage fee on the purchased pieces amount incurred by the user at the time of purchase

* investment period - a period between the successful conclusion of an auction and the sale of the asset, resulting in the revenue redistribution to users

* buyout - a mechanism where a user acquires the entire asset by submitting a purchase offer for a specific amount, accepted by piece holders, and depositing it into a special vault for subsequent revenue redistribution

* governance - a mechanism for collective decision-making by token holders through voting

* revenue redistribution - A mechanism allowing users to claim their share of revenue in the vault by burning their pieces




## Auction life-cycle

# <img src="auction_life_cycle.png" alt="Auction life cycle">

### General workflow
 
#### Auction Preparation and Scheduling

A broker, willing to sell the asset (in the MVP, this is a digital NFT, not a physical luxury asset) on the Platform, prepares auction details such as name, total value, and description, as well as details about fractionalization (e.g. amount of pieces). Then, the asset is placed in a specially prepared smart contract. Once everything is ready, the auction is sent for admin approval, who sets the auction start.

#### Active Auction
When the auction starts, users can buy pieces (pNFTs ) by paying for the pieces and an additional operational fee. As a result of the transaction, the piece is transferred to the user's wallet. The auction ends either after a specified time or when all pieces are sold.

If all pieces are sold, the auction ends successfully and the investment period begins.

However, if not all pieces are sold by the end of the specified time, the auction ends unsuccessfully, and users who bought pieces can return them to reclaim the tokens spent on the purchase and the operational fee.

#### Investment Period
Between a successful auction conclusion and the redistribution of revenue from the asset sale, users can freely trade their pieces on public NFT marketplaces.

#### Asset Buyout Offer and Governance
A user interested in owning the entire asset can make a buyout offer. To do this, they deposit funds equal to the asset's desired buyout value, and this offer is subject to governance voting. In governance, each piece equals one vote, and an absolute majority of pieces must vote in favor for the buyout offer to be accepted.

If the votes in favor do not constitute an absolute majority during the decision time, the offer is rejected, and the deposit is returned to the offeror.

If an absolute majority votes in favor at the end of the voting period, the offer is accepted, the asset goes to the new owner, and the funds go to a vault for revenue redistribution.

#### Revenue Redistribution
When funds from the asset buyout reach the vault, each piece holder can claim their proportional share of the revenue (tokens in the vault / total number of pieces * number of pieces held by the user) by burning their pieces. After all pieces are burned, the auction becomes archived.



### Auction statuses
<table>
  <tr><td>#</td><td>Auction status</td><td>Description</td></tr>
  <tr><td>1</td><td>WIP</td><td>Auction first status, Broker fills out all auction fields. Auction is not yet on blockchain, it's configuration is saved on Pieces.market server.
  </td></tr>
  <tr><td>2</td><td>Open</td><td>Auction is deployed to blockchain, investors can start buying pieces (pNFT)</td></tr>
  <tr><td>3</td><td>Closed</td><td>Auction is closed, all possible pieces were bought (and burn). During this status potenitial new owners can place offers (Governance). Each offer lasts for 24h, the quorum is > 50%.</td></tr>
  <tr><td>4</td><td>Failed</td><td>Auction is failed, during given time period, not all pieces were sold. Investors can refund their invested tokens by burning ther pieces.</td></tr>
  <tr><td>5</td><td>Finished</td><td>Auction is finished, new ultimate owner gets the assets. Pieces crypto-investors can claim their revenue.</td></tr>
  <tr><td>6</td><td>Archived</td><td>Auction is archived, revenue distribution is finished, all pieces were burn.</td></tr>
  </table>


## Smart contract implementation - TODO

### Auction

```http
  GET /api/items
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `api_key` | `string` | **Required**. Your API key |


#### add(num1, num2)

Takes two numbers and returns the sum.

### Buyout Governor

```http
  GET /api/items
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `api_key` | `string` | **Required**. Your API key |


#### add(num1, num2)

Takes two numbers and returns the sum.

### Usage

Once installed, you can use the contracts in the library by importing them:

```solidity
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyCollectible is ERC721 {
    constructor() ERC721("MyCollectible", "MCO") {
    }
}
```


> [!WARNING]
> Smart contracts are a nascent technology and carry a high level of technical risk and uncertainty. Although Pieces market is performing internal security audits, using Our Contracts is not a substitute for a security audit.



## FAQ - TODO

#### Question 1

Answer 1

#### Question 2

Answer 2


## Authors

- [@adamromanski](https://www.github.com/vendimpl)
- [@stanislawherjan](https://www.github.com/stanislawherjan)


## Security

This project is maintained by [Pieces.market](https://pieces.market) with the goal of providing a secure and reliable smart contracts for assets fractionalization. 

We address security through risk management in various areas such as engineering and open source best practices, scoping and API design, multi-layered review processes, and incident response preparedness.

The security policy is detailed in [`SECURITY.md`](./SECURITY.md) as well, and specifies how you can report security vulnerabilities, which versions will receive security patches, and how to stay informed about them. 

We plan to run a [bug bounty program on Immunefi](https://immunefi.com) to reward the responsible disclosure of vulnerabilities.

The engineering guidelines we follow to promote project quality can be found in [`GUIDELINES.md`](./GUIDELINES.md).

Pieces.market contracts are made available under the GPLv3 License, which disclaims all warranties in relation to the project and which limits the liability of those that contribute and maintain the project. As set out further in the Terms, you acknowledge that you are solely responsible for any use of Pieces.market contracts and you assume all risks associated with any such use.

## Contribute

Pieces.market contracts exists thanks to its contributors. There are many ways you can participate and help build high quality software. Check out the [contribution guide](CONTRIBUTING.md)!

## License

Pieces.market contracts is released under the [GPLv3](LICENSE).

## Legal

Your use of this Project is governed by the terms found at www.pieces.market/terms (the "Terms").