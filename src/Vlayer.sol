// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Asset} from "./Asset.sol";
import {Governor} from "./Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {IAuctioner} from "./interfaces/IAuctioner.sol";
import {IGovernor} from "./interfaces/IGovernor.sol";

/// @title Vlayer Integration
/// @notice Creates new auctions and new NFT's (assets), mints NFT per auctioned asset
/// @notice Allows users to buy pieces, buyout asset, claim revenues and refund
abstract contract Vlayer is ReentrancyGuard, Ownable, IAuctioner {
    /// @dev Variables
    uint256 private s_totalAuctions;
    address private immutable s_foundation;
    Governor private immutable i_governor;
    address private immutable i_vlayerAuthorizedAddress;

    struct Auction {
        address asset;
        uint256 price;
        uint256 pieces;
        uint256 max;
        uint256 openTs;
        uint256 closeTs;
        address recipient;
        bool buyoutProposalActive;
        bool descriptProposalActive;
        address offerer;
        mapping(address offerer => uint amount) offer;
        mapping(address offerer => bool) withdrawAllowed;
        AuctionState state;
    }

    /// @dev Mappings
    mapping(uint256 id => Auction) private s_auctions;

    event UpdateFromVlayer(uint id, uint value, address fulfiller);

    /// @dev Constructor
    constructor(address foundation, address governor, address vlayerAddress) Ownable(msg.sender) {
        s_foundation = foundation;
        i_governor = Governor(governor);
        i_vlayerAuthorizedAddress = vlayerAddress;
    }

    /// @notice ONLY 'VLAYER' ALLOWED TO TRIGGER THIS FUNCTION BASED ON SOME OFF-CHAIN CONFIRMATION.
    function vlayer(uint256 id, uint value, address fulfiller) external {
        if (msg.sender != i_vlayerAuthorizedAddress) revert Auctioner__UnauthorizedCaller();
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];
        if (auction.state != AuctionState.CLOSED) revert Auctioner__AuctionNotClosed();

        /// @dev VLAYER to update below based on for example mail confirmation:
        auction.offerer = fulfiller;
        auction.offer[auction.offerer] = value;

        emit UpdateFromVlayer(id, value, fulfiller);
    }

    /// @notice 3RD PARTY ALLOWED ONLY TO TRIGGER DISTRIBUTION OF FUNDS AMONG ASSET INVESTORS ONCE 3RD PARTY WILL SELL ASSET
    function fulfill(uint256 id) external payable override {
        if (id >= s_totalAuctions) revert Auctioner__AuctionDoesNotExist();
        Auction storage auction = s_auctions[id];

        if (msg.sender != auction.offerer) revert Auctioner__UnauthorizedCaller();
        if (msg.value < auction.offer[auction.offerer]) revert Auctioner__InsufficientFunds();
        if (auction.state != AuctionState.CLOSED) revert Auctioner__AuctionNotClosed();

        auction.state = AuctionState.FINISHED;

        emit StateChange(id, auction.state);
    }
}
