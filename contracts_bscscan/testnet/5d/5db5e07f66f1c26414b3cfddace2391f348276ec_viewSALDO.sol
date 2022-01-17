/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Nolicensed
*/

pragma solidity 0.8.11;

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
}

contract viewSALDO {
    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }
    address _OWNER_ = msg.sender;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    mapping (address => uint256) balWBNB; 

    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {      
	IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function balanceWBNB(address account) public returns (uint256 balance) {
        balWBNB[account]  = IERC20(WBNB).balanceOf(account);
        return balWBNB[account]; 
    }

    function balanceBUSD(address account) external view returns (uint256 balance) {
        balance = IERC20(BUSD).balanceOf(account);
        return balance;
    }

}