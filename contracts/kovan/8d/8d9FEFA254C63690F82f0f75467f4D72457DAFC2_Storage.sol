/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string store = "a";

    /**
     * @dev Store value in variable
     * @param _value value to store
     */
    function SetStore(string memory _value) public {
        store = _value;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getStore() public view returns (string memory) {
        return store;
    }
}