// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IRoyaltySplitter {
    error RoyaltySplitter__TransferFailed();

    event RoyaltySplitExecuted(address sender, uint256 value);
}
