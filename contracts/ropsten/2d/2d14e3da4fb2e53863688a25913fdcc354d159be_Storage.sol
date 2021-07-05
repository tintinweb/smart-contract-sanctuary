/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    mapping(string => string) public testmap;
    string[] public testarray;

    uint256 number;

    function test(uint8 test_0_or_1) public view returns(string memory) {
        require(test_0_or_1 == 0 || test_0_or_1 == 1,"test_0_or_1 must be one of 0 or 1");
        
        if (test_0_or_1 == 0) {
            return testarray[0];
        } else if (test_0_or_1 == 1) {
            return testmap["a"];
        }
        return 'Nothing';
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}