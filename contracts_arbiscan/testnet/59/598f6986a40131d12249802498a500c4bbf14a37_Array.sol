/**
 *Submitted for verification at arbiscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// Array function to delete element at index and re-organize the array
// so that their are no gaps between the elements.
library Array {
    function remove(uint[] storage arr, uint index) public {
        // Move the last element into the place to delete
        require(arr.length > 0, "Can't remove from empty array");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}