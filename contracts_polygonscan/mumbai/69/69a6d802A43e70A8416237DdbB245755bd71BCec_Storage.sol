/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 public number;
    string public url;
    
    event StoredNumber(uint256 indexed num);

    function setNumber(uint256 num) public {
        emit StoredNumber(num);
        number = num;
    }
    
    function setUrl(string memory _url) public {
        url = _url;
    }
}