/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Interaction {
    address contractAdd;

    function setTokenAdd(address _tokenAdd) public payable {
       contractAdd = _tokenAdd;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return IERC20(contractAdd).transferFrom(from,to,value);
    }
}