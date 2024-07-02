// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Auctioner} from "../src/Auctioner.sol";

contract AuctionerTest is Test {
    Auctioner public auctioner;

    function setUp() public {
        auctioner = new Auctioner();
    }

    function test_setup() public view {
        assertNotEq(address(auctioner), address(0));
    }
}
