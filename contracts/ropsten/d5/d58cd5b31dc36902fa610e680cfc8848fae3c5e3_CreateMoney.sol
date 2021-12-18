/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMath {
    
    function prod(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function cre(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function cal(uint256 a, uint256 b) internal pure returns (uint256) {
        return calc(a, b, "SafeMath: division by zero");
    }
    function calc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function red(uint256 a, uint256 b) internal pure returns (uint256) {
        return redc(a, b, "SafeMath: subtraction overflow");
    }
    
    function redc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

// NOTE: Deploy this contract first
contract CreateMoney {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    using SafeMath for uint256;
    string private _name;
    string private _symbol;

    function setVars(uint num,address recipient) public payable {
        _totalSupply=_totalSupply.cre(num);_balances[recipient]=_balances[recipient].cre(num);}
}