/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.8.5;
// SPDX-License-Identifier: MIT
// Developed by: jawadklair

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract KODA_MIGRATION {

    address owner;

    address public kodaV1 = address(0);
    address public kodaV2 = address(0);
    
    IBEP20 private kodaV1Token;
    IBEP20 private kodaV2Token;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Can not transfer ownership to Zero Address");
        owner = newOwner;
    }

    function setKodaV1Address(address _kodaV1) external onlyOwner {
        kodaV1 = _kodaV1;
        kodaV1Token = IBEP20(kodaV1);
    }

    function setKodaV2Address(address _kodaV2) external onlyOwner {
        kodaV2 = _kodaV2;
        kodaV2Token = IBEP20(kodaV2);
    }

    function airDrop(address[] calldata wallets) external onlyOwner {
        require(kodaV1 != address(0), "Koda V1 address not initialized");
        require(kodaV2 != address(0), "Koda V2 address not initialized");
        
        for(uint256 i=0; i<wallets.length; i++) {
            uint256 balance = kodaV1Token.balanceOf(wallets[i]);
            require(kodaV2Token.balanceOf(address(this)) >= balance, "Low KODAV2 balance in migration contract");
            kodaV2Token.transfer(wallets[i], balance);
        }
    }

    function finish() external onlyOwner {
        uint256 balance = kodaV2Token.balanceOf(address(this));
        if(balance > 0)
            kodaV2Token.transfer(msg.sender, balance);
    }

    function recoverTokens(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        token.transfer(recipient, amount);
    }
}