// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAsset {
    error VotesDelegationOnlyOnTokensTransfer();
    error RoyaltyTransferFailed();
    error InvalidBrokerFee();

    /// @notice Emitted when the royalty fee has been split successfully between the broker and the pieces market
    /// @param sender The address that sent the royalty fee
    /// @param brokerShare The portion of the royalty fee sent to the broker
    /// @param piecesMarketShare The portion of the royalty fee sent to the pieces market
    /// @param value The total value of the royalty fee
    event RoyaltySplitExecuted(address sender, uint256 brokerShare, uint256 piecesMarketShare, uint256 value);
}
