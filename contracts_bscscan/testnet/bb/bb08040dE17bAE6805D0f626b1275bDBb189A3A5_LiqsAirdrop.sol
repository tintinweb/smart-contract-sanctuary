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
    IERC20 public _associatedToken;
    
    uint private _amountToTake;
    
    mapping(address => uint) private _beneficiaries;
    
    constructor(address tokenAddress_, uint amountToTake_) {
        _owner = msg.sender;
        _tokenAddress = tokenAddress_;
        _amountToTake = amountToTake_;
        _associatedToken = IERC20(_tokenAddress);
        _tokenDecimals = _associatedToken.decimals();
    }

    function depositTokens() external {
        _associatedToken.approve(msg.sender, _amountToTake);
        _associatedToken.transferFrom(msg.sender, address(this), _amountToTake );
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function amountToTake() external view returns (uint) {
        return _amountToTake;
    }

    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function tokenDecimals() external view returns (uint) {
        return _tokenDecimals;
    }

    function x() external payable {}
}