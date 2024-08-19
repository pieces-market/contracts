// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Governor} from "../src/Governor.sol";
import {Asset} from "../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuctioner} from "../src/interfaces/IAuctioner.sol";

contract AuctionerTest is Test {
    Auctioner private auctioner;
    Asset private asset;
    Governor private governor;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");
    address private FOUNDATION = makeAddr("foundation");

    function setUp() public {
        vm.startPrank(OWNER);
        governor = new Governor();
        auctioner = new Auctioner(FOUNDATION, address(governor));
        governor.transferOwnership(address(auctioner));
        vm.stopPrank();

        console.log("Auctioner: ", address(auctioner));

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
        deal(FOUNDATION, STARTING_BALANCE);
    }

    function testCanBuyPieces() public auctionCreated {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
    }

    function testCanRemoveUnprocessedAuctions() public {
        vm.startPrank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 7, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 3, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 1 days, 8, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 2, BROKER);
        vm.stopPrank();

        auctioner.getUnprocessedAuctions();

        vm.warp(block.timestamp + 3 days + 1);
        auctioner.exec();

        auctioner.getUnprocessedAuctions();

        // vm.warp(block.timestamp + 2 days + 1);
        // auctioner.exec();

        // auctioner.getUnprocessedAuctions();
    }

    modifier auctionCreated() {
        vm.startPrank(OWNER);
        auctioner = new Auctioner(FOUNDATION, address(governor));

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
