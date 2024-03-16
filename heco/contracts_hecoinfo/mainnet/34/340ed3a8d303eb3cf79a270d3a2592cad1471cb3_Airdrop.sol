/**
 *Submitted for verification at hecoinfo.com on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Airdrop {
    function transfer(
        address fromToken,
        address payable[] memory tos,
        uint256[] memory amounts
    ) public payable  {
        require(tos.length == amounts.length, "Parameter error");
        IERC20 fromERC = IERC20(fromToken);
        for (uint8 i = 0; i < tos.length; i++) {
            fromERC.transferFrom(msg.sender, tos[i], amounts[i]);
        }
    }
}