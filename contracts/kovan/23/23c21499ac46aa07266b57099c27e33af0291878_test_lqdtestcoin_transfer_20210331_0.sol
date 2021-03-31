/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 tokens) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract test_lqdtestcoin_transfer_20210331_0 {
    IERC20 lqdtestcoin11;
    constructor() {
        lqdtestcoin11 = IERC20(0xa1BCbBFa3eD55857bA3d5e33ff25b8f6389FBeFD);
    }
    function foo() external {
        lqdtestcoin11.transfer(0xf259583c632006161613642F00411ee0E4b548d7, 1000000000000000000);
    }
}