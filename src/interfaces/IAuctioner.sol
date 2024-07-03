// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IAuctioner {
    /// @notice Allows buying pieces of asset auctioned by broker
    /// @param id Auction id that we want to interact with
    /// @dev Emits Purchase event and TransferToBroker event if last piece has been bought
    function buy(uint256 id) external payable;

    /// @notice Allows making an offer to buy a certain asset auctioned by broker instantly
    /// @param id Auction id that we want to interact with
    function buyout(uint256 id) external payable;

    /// @notice Allows claiming revenue from pieces bought by buyers if auction closed successfully
    function claim() external;

    /// @notice Allows withdrawing funds by buyers if auction failed selling all pieces in given time period
    function refund() external;
}
