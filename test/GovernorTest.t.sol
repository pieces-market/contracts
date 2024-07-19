// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {Governor} from "../src/Governor.sol";
import {IAuctioner} from "../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../src/interfaces/IGovernor.sol";

contract GovernorTest is Test {
    Auctioner public auctioner;
    Asset public asset;
    Governor public governor;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER;
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        auctioner = new Auctioner();
        console.log("Auctioner: ", address(auctioner));
        asset = new Asset("Asset", "AST", "https:", OWNER);
        console.log("Asset: ", address(asset));
        governor = new Governor(address(auctioner));
        console.log("Governor: ", address(asset));

        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function testSomething() public {}
}
