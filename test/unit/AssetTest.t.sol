// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../../src/Auctioner.sol";
import {Governor} from "../../src/Governor.sol";
import {Asset} from "../../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CorruptedClock} from "../mocks/CorruptedClock.sol";
import "../../src/extensions/ERC721AVotes.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @dev REFACTOR NEEDED: CLEAR UNUSED FUNCTIONS, TRIM CONTRACT TO MINIMUM.

contract AssetTest is Test {
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
        deal(FOUNDATION, STARTING_BALANCE);
    }

    function testCountsTotalMintedTokensAndAssignsCorrectURIAndRevertsForNonExistenToken() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(DEVIL);
        auctioner.buy{value: 8 ether}(0, 4);

        vm.expectRevert(IERC721A.URIQueryForNonexistentToken.selector);
        asset.tokenURI(7);

        uint totalMinted = asset.totalMinted();
        assertEq(totalMinted, 7);

        string memory userTokenURI = asset.tokenURI(2);
        string memory devTokenURI = asset.tokenURI(5);

        assertEq(userTokenURI, "https:");
        assertEq(devTokenURI, "https:");
    }

    function testCanReceiveVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        /// @dev USE BELOW IF CLOCK() IS SET FOR TIMESTAMP
        vm.warp(block.timestamp + 1);
        /// @dev USE BELOW IF CLOCK() IS SET FOR BLOCK NUMBER
        // vm.roll(block.number + 1);

        uint snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);
    }

    function testCanTransferTokensAndAdjustVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        console.log("Clock: ", asset.clock());

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 1);
        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);
        assertEq(snapshotVotes, 2);
    }

    function testCanBatchTransferTokensAndAdjustVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        console.log("Clock: ", asset.clock());

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);

        uint256[] memory tokenIds = asset.tokensOfOwner(USER);

        vm.prank(USER);
        asset.safeBatchTransferFrom(USER, DEVIL, tokenIds);

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 0);
        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);
        assertEq(snapshotVotes, 3);
    }

    function testCanSupportInterfaces() public view {
        bytes4 votesInterfaceId = type(IVotes).interfaceId;
        bytes4 erc165InterfaceId = type(IERC165).interfaceId;

        assertTrue(asset.supportsInterface(votesInterfaceId));
        assertTrue(asset.supportsInterface(erc165InterfaceId));
    }

    /// @dev REVERT TO FIX ON CLOCK, MOCKING CALL DOES NOT WORK
    function testClockMode() public {
        uint256 currentClock = asset.clock();
        uint256 currentTimestamp = block.timestamp;

        assertEq(currentClock, currentTimestamp);
        assertEq(asset.CLOCK_MODE(), "mode=timestamp&from=default");

        // CorruptedClock corrClock = new CorruptedClock();

        // vm.expectRevert(Votes.ERC6372InconsistentClock.selector);
        // vm.mockFunction(address(asset), address(corrClock), abi.encodeWithSelector(asset.clock.selector));
        vm.mockCall(address(this), abi.encodeWithSelector(asset.clock.selector), abi.encode(block.timestamp + 100));
        asset.CLOCK_MODE();

        // Step 3: Test the normal behavior when the clock is consistent
        // vm.clearMockedCalls(); // Clear the mocked call so clock() returns the actual block timestamp
        // assertEq(asset.CLOCK_MODE(), "mode=timestamp&from=default");
    }
}
