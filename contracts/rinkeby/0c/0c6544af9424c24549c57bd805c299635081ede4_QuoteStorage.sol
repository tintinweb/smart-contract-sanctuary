/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title QuoteStorage
 * @dev Store & retrieve value in a variable
 */
contract QuoteStorage {

    string quote;

    /**
     * @dev Store value in variable
     * @param quoteToStore value to store
     */
    function store(string memory quoteToStore) public {
        quote = quoteToStore;
    }

    /**
     * @dev Return value 
     * @return value of 'quote'
     */
    function retrieve() public view returns (string memory){
        return quote;
    }
}