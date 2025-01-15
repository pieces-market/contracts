// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IRoyaltySplitter} from "./interfaces/IRoyaltySplitter.sol";

contract RoyaltySplitter is IRoyaltySplitter {
    receive() external payable {
        split();
    }

    function split() internal {
        (bool success, ) = msg.sender.call{value: msg.value}("");
        if (!success) revert RoyaltySplitter__TransferFailed();

        emit RoyaltySplitExecuted(msg.sender, msg.value);
    }
}
