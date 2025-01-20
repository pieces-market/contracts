// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAsset {
    error VotesDelegationOnlyOnTokensTransfer();
    error RoyaltyTransferFailed();
    error InvalidBrokerFee();
}
