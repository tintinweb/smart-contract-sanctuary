/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool); 
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function CA() external view returns (address);
}
contract Test{
    event testuse(address who); 

    function test() public {
        emit testuse(msg.sender);
    }

}