// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";

/// @title Dummy contract that always reverts
/// @notice Used as a placeholder to ensure reverts on attempted calls
contract InvalidRecipient is Ownable {
    constructor() Ownable(msg.sender) {}

    function propose(uint, address, string memory, bytes memory) external pure {
        revert IAuctioner.Auctioner__FunctionCallFailed();
    }
}
