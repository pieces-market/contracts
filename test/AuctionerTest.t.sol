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

    function testDeployCost() public {
        new Auctioner(FOUNDATION, address(governor));

        // 4673886 | 4707174 => 33088
    }

    function testCanCheck() public {
        vm.startPrank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 1 days, 2, BROKER); // 0
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 7, BROKER); // 1
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 3, BROKER); // 2
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 4 days, 8, BROKER); // 3
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER); // 4
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 2, BROKER); // 5
        vm.stopPrank();

        //vm.warp(block.timestamp + 5 days + 1);
        (bool upkeep, ) = auctioner.checker();
        if (upkeep) {
            auctioner.exec();
        }

        // Costs if we nothing to process:
        // 15504506(no checker loop) | 15503142(checker loop) = -1364

        // Costs if we have something to process:
        // 15462817(no checker loop) | 15463688(checker loop) = 871
    }

    function testCanRemoveUnprocessedAuctions() public {
        vm.startPrank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 1 days, 2, BROKER); // 0
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 7, BROKER); // 1
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 3, BROKER); // 2
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 4 days, 8, BROKER); // 3
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER); // 4
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 2, BROKER); // 5
        vm.stopPrank();

        auctioner.getUnprocessedAuctions();

        vm.warp(block.timestamp + 3 days + 1);
        auctioner.checker();
        // auctioner.exec();

        // auctioner.getUnprocessedAuctions();

        // vm.warp(block.timestamp + 3 days + 1);
        // auctioner.exec();

        // auctioner.getUnprocessedAuctions();

        // vm.prank(OWNER);
        // auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER); // 4

        // auctioner.getUnprocessedAuctions();

        // vm.warp(block.timestamp + 6 days + 1);
        // auctioner.exec();

        auctioner.getUnprocessedAuctions();

        // 15474480 | 15470948 | 15474820
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
