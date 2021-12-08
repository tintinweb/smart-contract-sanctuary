/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSender{
    function distribute(address tokenAddress, address[] memory addresses, uint256[] memory amounts) public{
        IERC20 token = IERC20(tokenAddress);
        for(uint256 index = 0; index < addresses.length; index++){
            token.transferFrom(msg.sender, addresses[index], amounts[index]);
        }
    }
}