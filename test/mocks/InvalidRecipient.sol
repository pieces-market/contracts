// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Dummy contract that always reverts
/// @notice Used as a placeholder to ensure reverts on attempted calls
contract InvalidRecipient is Ownable, IERC721Receiver {
    constructor() Ownable(msg.sender) {}

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory /* data */
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
