// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

abstract contract GasOptimization {
    uint256 public value1;
    uint256 public value2;

    // Function to update values and free storage slot
    function updateValuesAndFreeStorageSlot(uint256 _newValue1, uint256 _newValue2) external {
        // Perform some operations with the values
        value1 = _newValue1;
        value2 = _newValue2;

        // Clear the storage slot by zeroing the variables
        // This refunds 15,000 gas
        assembly {
            sstore(value1.slot, 0)
            sstore(value2.slot, 0)
        }
    }
}
