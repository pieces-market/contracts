// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAuctioner} from "../src/interfaces/IAuctioner.sol";

contract AuctionerTest is Test {
    Auctioner private auctioner;
    Asset private asset;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        vm.prank(OWNER);
        auctioner = new Auctioner();

        console.log("Auctioner: ", address(auctioner));

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function testCanBuyPieces() public auctionCreated {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
    }

    modifier auctionCreated() {
        vm.startPrank(OWNER);
        auctioner = new Auctioner();

        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[1].topics[2])));
        asset = Asset(createdAsset);

        console.log("Asset: ", address(asset));

        _;
    }
}
