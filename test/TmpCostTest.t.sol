// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {Governor} from "../src/Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuctioner} from "../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../src/interfaces/IGovernor.sol";

contract TmpCostTest is Test {
    Auctioner private auctioner;
    Asset private asset;
    Governor private governor;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        vm.startPrank(OWNER);
        governor = new Governor();
        auctioner = new Auctioner(address(governor));
        governor.transferOwnership(address(auctioner));

        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[1].topics[2])));
        asset = Asset(createdAsset);

        console.log("Auctioner: ", address(auctioner));
        console.log("Asset: ", address(asset));
        console.log("Governor: ", address(governor));

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function testDeployAuctionerCost() external {
        new Auctioner(address(governor));

        // cost snapshot: 3_906_500
    }

    function testDeployAssetCost() external {
        new Asset("Asset", "AST", "https:", address(auctioner));

        // cost snapshot: 2_352_889
    }

    function testMakeOfferCost() external {
        vm.prank(BUYER);
        auctioner.buy{value: 6 ether}(0, 3);
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.makeOffer{value: 12 ether}(0, "buyout offer");

        // cost snapshot: 568_288
    }

    function testWithdrawOfferCost() external {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.makeOffer{value: 12 ether}(0, "buyout offer");

        auctioner.rejectOffer(0);

        vm.prank(DEVIL);
        auctioner.withdrawOffer(0);

        // cost snapshot: 418_206
    }

    function testBuyCost() external {
        vm.prank(DEVIL);
        auctioner.buy{value: 6 ether}(0, 3);

        // cost snapshot: 236_868
        //                259_138
    }

    function testRefundCost() external {
        vm.prank(DEVIL);
        auctioner.buy{value: 6 ether}(0, 3);

        auctioner.stateHack(0, 4);

        vm.prank(DEVIL);
        auctioner.refund(0);

        // cost snapshot: 364_945
        //                366_301
    }
}
