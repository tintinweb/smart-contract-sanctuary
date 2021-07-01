// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract VaultERC {

    address private _owner;

    mapping(address => uint) _totalSupply;
    mapping(address => mapping(address => uint)) balances;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function totalSupply(address token) public view returns (uint) {
        return _totalSupply[token];
    }

    function balanceOf(address token, address account) public view returns (uint balance) {
        return balances[token][account];
    }

    function deposit(address token, uint amount) public returns (bool success) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token][msg.sender] = SafeMath.safeAdd(balances[token][msg.sender], amount);
        _totalSupply[token] = SafeMath.safeAdd(_totalSupply[token], amount);
        return true;
    }

    function withdraw(address token, uint amount) public onlyOwner returns (bool success) {
        require (amount < _totalSupply[token], "amount must be less than total supply");
        // if (IERC20(token).allowance(address(this), _owner) < amount) {
        //     _approve(_owner, token, 2**256 - 1);
        // }
        IERC20(token).transfer(_owner, amount);
        _totalSupply[token] = SafeMath.safeSub(_totalSupply[token], amount);
        return true;
    }
    
    function withdrawUnderlying(address token, uint amount) public returns (bool success) {
        require (amount < _totalSupply[token], "amount must be less than total supply");
        // if (IERC20(token).allowance(address(this), msg.sender) < amount) {
        //     _approve(msg.sender, token, amount);
        // }
        IERC20(token).transfer(msg.sender, amount);
        _totalSupply[token] = SafeMath.safeSub(_totalSupply[token], amount);
        return true;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function _approve(address account, address token, uint amount) private {
        IERC20(token).approve(account, amount);   
    }
}

library SafeMath {

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}