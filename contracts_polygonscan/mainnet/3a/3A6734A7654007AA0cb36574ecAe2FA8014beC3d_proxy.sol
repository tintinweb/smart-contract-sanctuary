/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

interface IIGainAAVEIRS {
	function mintA(uint256 amount, uint256 min_a) external returns (uint256 _a);
    function a() external returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract proxy {
	ILendingPool public AAVE; // AAVE LendingPool
	IIGainAAVEIRS public IGain;
	IERC20 public A;
    IERC20 public asset; // underlying asset's address

    constructor(address _asset, address _aave, address _igain) {
    	asset = IERC20(_asset);
    	AAVE = ILendingPool(_aave);
    	IGain = IIGainAAVEIRS(_igain);
    	A = IERC20(IGain.a());
    	asset.approve(_aave, type(uint256).max);
    	asset.approve(_igain, type(uint256).max);
    }

    function deposit(uint256 depositAmount, uint256 igainAmount, uint256 minToken) external {
    	asset.transferFrom(msg.sender, address(this), depositAmount + igainAmount);
    	AAVE.deposit(address(asset), depositAmount, msg.sender, uint16(0));
    	uint256 a = IGain.mintA(igainAmount, minToken);
    	A.transfer(msg.sender, a);
    }
}