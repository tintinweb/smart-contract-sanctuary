/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    struct TokenInfo {
        uint8 _decimals;
        uint256 _tTotal;
        string _name;
        string _symbol;
    }

    TokenInfo public _tokeninfo = TokenInfo(18, 100, 'test', 'TEST');

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function setName(string memory name) public returns (bool) {
        _tokeninfo._name = name;
        return true;
    }
    
    function setDec(uint8 decimals) public returns (bool) {
        _tokeninfo._decimals = decimals;
        return true;
    }
    function setTotal(uint256 total) public returns (bool) {
        _tokeninfo._tTotal = total;
        return true;
    }
    function setSymbol(string memory symbol) public returns (bool) {
        _tokeninfo._symbol = symbol;
        return true;
    }

}