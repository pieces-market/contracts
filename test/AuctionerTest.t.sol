// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {IAuctioner} from "../src/interfaces/IAuctioner.sol";

contract AuctionerTest is Test {
    Auctioner public auctioner;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        vm.prank(OWNER);
        auctioner = new Auctioner();
        console.log("Auctioner: ", address(auctioner));

        deal(OWNER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function test_setup() public {
        string memory name = "auction";
        string memory symbol = "auc";
        string memory uri = "https";
        uint price = 2 ether;
        uint pieces = 100;
        uint max = 5;
        uint start = block.timestamp;
        uint end = block.timestamp + 7 days;
        address rec = DEVIL;

        vm.prank(OWNER);
        auctioner.create(name, symbol, uri, price, pieces, max, start, end, rec);

        uint tokens;
        tokens = auctioner.getTokens(0, BUYER);
        assertEq(tokens, 0);

        vm.prank(BUYER);
        auctioner.buy{value: 6 ether}(0, 3);

        /// @dev Changing auction state to failed, so refunds are available
        auctioner.stateHack(0, 4);

        vm.prank(BUYER);
        auctioner.refund(0);

        tokens = auctioner.getTokens(0, BUYER);
        assertEq(tokens, 0);

        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        vm.prank(BUYER);
        auctioner.refund(0);
    }
}
