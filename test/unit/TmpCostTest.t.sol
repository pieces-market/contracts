// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AuctionerDev} from "../../src/helpers/AuctionerDev.sol";
import {Asset} from "../../src/Asset.sol";
import {Governor} from "../../src/Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../../src/interfaces/IGovernor.sol";

contract TmpCostTest is Test {
    AuctionerDev private auctioner;
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
        auctioner = new AuctionerDev(FOUNDATION, address(governor));
        governor.transferOwnership(address(auctioner));

        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 100, block.timestamp, block.timestamp + 7 days, BROKER);
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
        deal(DEVIL, 300 ether);
        deal(FOUNDATION, STARTING_BALANCE);
    }

    // test
    function testDeployAuctionerCost() external {
        new AuctionerDev(FOUNDATION, address(governor));

        // cost snapshot: 4544703 | 4552120
    }

    function testDeployAssetCost() external {
        new Asset("Asset", "AST", "https:", address(auctioner));

        // cost snapshot: 2_352_889
    }

    function testBuyoutProposeCost() external {
        vm.prank(BUYER);
        auctioner.buy{value: 6 ether}(0, 3);
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.propose{value: 12 ether}(0, "buyout", IAuctioner.ProposalType(0));

        // cost snapshot: 641297 | 640991
    }

    // test
    function testDescriptProposeCost() external {
        auctioner.stateHack(0, 3);

        string memory desc = "xdsftl vftpod";
        console.log("String Size: ", bytes(desc).length);

        vm.prank(FOUNDATION);
        auctioner.propose(0, desc, IAuctioner.ProposalType(1));

        // cost snapshot; 274785 | 274390
    }

    /// @dev TODO
    function testStringSize() external {}

    function testExecuteCost() external {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.propose{value: 12 ether}(0, "buyout", IAuctioner.ProposalType(0));

        vm.prank(address(governor));
        //governor.execute(0);
    }

    function testCancelCost() external {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.propose{value: 12 ether}(0, "", IAuctioner.ProposalType(0));

        vm.prank(FOUNDATION);
        auctioner.propose(0, "buyout", IAuctioner.ProposalType(1));

        (bool buyoutt, bool descriptt) = auctioner.getProposals(0);
        console.log("Proposals B: ", buyoutt, descriptt);

        vm.prank(address(governor));
        //governor.cancel(0);

        (bool buyout, bool descript) = auctioner.getProposals(0);
        console.log("Proposals: ", buyout, descript);

        // cost snapshot: 525_906
        // 526_146
    }

    function testRejectCost() external {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.propose{value: 12 ether}(0, "buyout", IAuctioner.ProposalType(0));

        vm.prank(address(governor));
        auctioner.reject(0, abi.encodeWithSignature("buyout(uint256)", 0));

        // cost snapshot: 525143 | 525153
    }

    function testWithdrawOfferCost() external {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        auctioner.stateHack(0, 3);

        vm.prank(DEVIL);
        auctioner.propose{value: 12 ether}(0, "buyout", IAuctioner.ProposalType(0));

        vm.prank(address(governor));
        auctioner.reject(0, abi.encodeWithSignature("buyout(uint256)", 0));

        vm.prank(DEVIL);
        auctioner.withdraw(0);

        // cost snapshot: 418_206
    }

    function testBuyCost() external {
        vm.prank(DEVIL);
        auctioner.buy{value: 6 ether}(0, 3);

        // cost snapshot: 237051 | 237059
    }

    function testRefundCost() external {
        vm.prank(DEVIL);
        auctioner.buy{value: 6 ether}(0, 3);

        auctioner.stateHack(0, 4);

        vm.prank(DEVIL);
        auctioner.refund(0);

        // cost snapshot: 365_782
        //                307_446
    }

    function testBigRefund() external {
        vm.prank(DEVIL);
        // Crashes on 100++ pieces
        auctioner.buy{value: 198 ether}(0, 99);

        auctioner.stateHack(0, 4);

        vm.prank(DEVIL);
        auctioner.refund(0);

        // cost snapshot: 3_957_735 * 7
        //                1_194_936 * 7
    }
}
