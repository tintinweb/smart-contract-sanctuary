/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// File: burner.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCBurn {
    function burn(uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract Burner {

    event BurnWithMessage(uint256 amount, string message);
    IERCBurn public immutable cndlToken;

    constructor(address _cndlAddress) {
        cndlToken = IERCBurn(_cndlAddress);
    }

    function burnWithMessage(uint256 _amount, string memory _message) public {
        cndlToken.burnFrom(msg.sender, _amount);
        emit BurnWithMessage(_amount, _message);
    }
}