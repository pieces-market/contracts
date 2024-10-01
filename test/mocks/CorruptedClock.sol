// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "../../src/extensions/ERC721AVotes.sol";

/// @title Dummy contract that returns shifted clock
/// @notice Used for Asset.sol clock revert test
contract CorruptedClock {
    function clock() public view returns (uint48) {
        return Time.timestamp() + 100;
    }

    function CLOCK_MODE() public view returns (string memory) {
        // Check that the clock was not modified
        if (clock() != Time.timestamp()) revert Votes.ERC6372InconsistentClock();

        return "mode=timestamp&from=default";
    }
}
