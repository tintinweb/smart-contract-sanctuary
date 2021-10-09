/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface MyIERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract FeesVault {
    MyIERC20 renBTC = MyIERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);

    function getRenBalance() public view returns(uint balance) {
        balance = renBTC.balanceOf(address(this));
    }
}