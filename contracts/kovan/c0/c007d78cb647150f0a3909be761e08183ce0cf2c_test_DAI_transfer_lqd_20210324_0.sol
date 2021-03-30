/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract test_DAI_transfer_lqd_20210324_0 {
    IERC20 lqdTestCoin2;
    constructor() {
        lqdTestCoin2 = IERC20(0x4ad584d9594919E7a94A66122f2182c83b99937e);
    }
    function foo() external {
        lqdTestCoin2.transfer(msg.sender, 100000000000000000);
    }
}