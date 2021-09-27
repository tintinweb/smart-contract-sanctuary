/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title FailingContract
 * @dev Always fails
 */
contract FailingContract {
    uint numSuccesses = 0;

    /**
     * @dev Fail this transaction just because
     */
    function failOnPurpose(uint256 num) public {
        require(num == 4, "Num must be 4");
        numSuccesses++;
    }
    
    function getNumSuccesses() public view returns (uint) {
        return numSuccesses;
    }
}