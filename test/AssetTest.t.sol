// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAuctioner} from "../src/interfaces/IAuctioner.sol";

contract AssetTest is Test {
    Auctioner private auctioner;
    Asset private asset;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        vm.startPrank(OWNER);
        auctioner = new Auctioner();

        address precomputedAsset = vm.computeCreateAddress(address(auctioner), vm.getNonce(address(auctioner)));

        vm.recordLogs();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Create(0, precomputedAsset, 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[2].topics[2])));
        asset = Asset(createdAsset);

        console.log("Auctioner: ", address(auctioner));
        console.log("Asset: ", address(asset));

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function testCanGetPastVotes() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.roll(block.number + 1);

        console.log("Clock: ", asset.clock());

        uint votes = asset.getPastVotes(USER, 1);

        assertEq(votes, 3);
    }

    // function testCanReceiveVotingPower() public {
    //     vm.prank(USER);
    //     auctioner.buy{value: 6 ether}(0, 3);

    //     assertEq(3, asset.getVotes(USER));
    // }

    // function testCanTransferTokensAndAdjustVotingPower() public {
    //     vm.prank(USER);
    //     auctioner.buy{value: 6 ether}(0, 3);

    //     assertEq(3, asset.balanceOf(USER));
    //     assertEq(3, asset.getVotes(USER));

    //     assertEq(0, asset.balanceOf(DEVIL));
    //     assertEq(0, asset.getVotes(DEVIL));

    //     assertEq(0, asset.getVotes(OWNER));

    //     vm.startPrank(USER);
    //     asset.safeTransferFrom(USER, DEVIL, 0);
    //     asset.safeTransferFrom(USER, DEVIL, 2);
    //     vm.stopPrank();

    //     assertEq(1, asset.balanceOf(USER));
    //     assertEq(1, asset.getVotes(USER));

    //     assertEq(2, asset.balanceOf(DEVIL));
    //     assertEq(2, asset.getVotes(DEVIL));

    //     assertEq(0, asset.getVotes(OWNER));
    // }

    modifier mod() {
        _;
    }
}
