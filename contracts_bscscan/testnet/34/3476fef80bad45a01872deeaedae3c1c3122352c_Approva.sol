/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


//import the ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Approva {
    function Approvetoken(address _tokenIn)external{
    IERC20(_tokenIn).approve(0xD99D1c33F9fC3444f8101754aBC46c52416550D1,115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
}