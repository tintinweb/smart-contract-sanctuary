/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ReturnOne
 * @dev returns 1
 */
contract PrintStuff {

    /**
     * @dev Returns 1
     */
    uint32[] nums = [0, 1, 2, 3, 4];
    function print_stuff() public view returns (uint32[5] memory) {
        uint32[5] memory result;
        for(uint i=0; i<nums.length; i++){
            result[i] = nums[i]**2;
        }
        return result;
    }
}