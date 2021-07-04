/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StarHolder
{
    struct TokenLock
    {
        address owner;
        uint256 amount;
        uint256 unlockDate;
    }
    
    IERC20 STARLightToken;
    
    constructor()
    {
        STARLightToken = IERC20(0x2bBF4f7B8Ab300Db01d45662769821Da6E400ef4);
    }
    
    mapping(address => TokenLock[]) public userToTokenLocks;
    
    /////////////////
    // Lock functions
    
    function lockToken(uint256 _amount) external
    {
       
        
        STARLightToken.transferFrom(msg.sender, address(this), _amount);
        
        uint256 unlockDate;
        
        unlockDate = block.timestamp + 31540000000; // 1 year lock
        
        userToTokenLocks[msg.sender].push(TokenLock(
            msg.sender,
            _amount,
            unlockDate
        ));
    }
    
    /////////////////////
    // Withdraw functions
    
    function withdrawLockedToken(uint256 _index) external
    {
        TokenLock memory lock = userToTokenLocks[msg.sender][_index];
        
        require(block.timestamp >= lock.unlockDate, "You are almost there, please HODL a little longer!! ");

        STARLightToken.transfer(msg.sender, lock.amount);
        
        delete userToTokenLocks[msg.sender][_index];
    }
}