/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenLocker
{
    
    mapping(address => uint256) public tokenToAmountUnlocked;
    
    mapping(address => mapping(address => uint256[])) public receiverToTokenToClaimTimes; // Number of claims
    mapping(address => mapping(address => uint256[])) public receiverToTokenToUnlockAmount; // Number of tokens withdrawable a claim
    mapping(address => mapping(address => uint256[])) public receiverToTokenToWithdrawTime; // Next claim date
    mapping(address => mapping(address => uint256[])) public receiverToTokenToWithdrawStepTime; // Number of time between claims
    
    address owner;
    
    constructor()
    {
        owner = msg.sender;
    }
    
    function depositTokens(address _token, uint256 _amount) external
    {
        IERC20 token = IERC20(_token);
        
        token.transferFrom(msg.sender, address(this), _amount);
        
        tokenToAmountUnlocked[_token] += _amount;
    }
    
    function lockToken(address _token, address _receiver, uint256 _unlockAmount, uint256 _claimTimes, uint256 _withdrawStepTime) external
    {   
        require(msg.sender == owner, "You are not the owner!");
        require(tokenToAmountUnlocked[_token] >= _claimTimes * _unlockAmount, "Contract doesn't have enough tokens!");
        
        tokenToAmountUnlocked[_token] -= _claimTimes * _unlockAmount;
        
        receiverToTokenToClaimTimes[_receiver][_token].push();
        receiverToTokenToUnlockAmount[_receiver][_token].push();
        receiverToTokenToWithdrawTime[_receiver][_token].push();
        receiverToTokenToWithdrawStepTime[_receiver][_token].push();
        
        receiverToTokenToClaimTimes[_receiver][_token][receiverToTokenToClaimTimes[_receiver][_token].length-1] = _claimTimes;
        receiverToTokenToUnlockAmount[_receiver][_token][receiverToTokenToUnlockAmount[_receiver][_token].length-1] = _unlockAmount;
        receiverToTokenToWithdrawTime[_receiver][_token][receiverToTokenToWithdrawTime[_receiver][_token].length-1] = block.timestamp + _withdrawStepTime;
        receiverToTokenToWithdrawStepTime[_receiver][_token][receiverToTokenToWithdrawStepTime[_receiver][_token].length-1] = _withdrawStepTime;
        
    }
    
    function claimsAvaible(address _token, uint256 _index) view public returns(int)
    {
        int256 claimsAvailable = int((int(block.timestamp) - (int(receiverToTokenToWithdrawTime[msg.sender][_token][_index]) - int(receiverToTokenToWithdrawStepTime[msg.sender][_token][_index])))) / int(receiverToTokenToWithdrawStepTime[msg.sender][_token][_index]);
        
        if(uint(claimsAvailable) > receiverToTokenToClaimTimes[msg.sender][_token][_index])
        {
            claimsAvailable = int(receiverToTokenToClaimTimes[msg.sender][_token][_index]);
        }
        
        return claimsAvailable;    
    }
    
    function withdrawLockedToken(address _token, uint256 _index) external
    {
        require(receiverToTokenToClaimTimes[msg.sender][_token][_index] > 0, "You don't have any claims left!");
        require(block.timestamp > receiverToTokenToWithdrawTime[msg.sender][_token][_index], "You cannot withdraw these tokens yet!");
        
        int256 claimsAvailable = claimsAvaible(_token, _index);
        
        IERC20 token = IERC20(_token);
        
        token.transfer(msg.sender, receiverToTokenToUnlockAmount[msg.sender][_token][_index] * uint(claimsAvailable));
        
        receiverToTokenToWithdrawTime[msg.sender][_token][_index] += receiverToTokenToWithdrawStepTime[msg.sender][_token][_index] * uint(claimsAvailable);
        receiverToTokenToClaimTimes[msg.sender][_token][_index] -= uint(claimsAvailable);
        
    }
}