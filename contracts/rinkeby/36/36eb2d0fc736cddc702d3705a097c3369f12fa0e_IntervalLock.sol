/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

/*
    The FreeBSD Documentation License
    Copyright 1994-2021 The FreeBSD Project. All rights reserved.
*/

pragma solidity >=0.7.0 <0.9.0;

interface ERC20 { 
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract IntervalLock {

    address payable private owner;
    uint256 intervalBlock = 20;
    uint256 window = 5;

    modifier isOwner(){
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyUnlocked() {
        if ((block.number % intervalBlock) > window)
            revert();
        _;
    }
    
    fallback () external payable {
        
    }

    constructor() payable {
        owner = msg.sender; 
    }
    
    function withdraw(uint256 _amount) isOwner() onlyUnlocked() public {
        owner.transfer(_amount);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) isOwner() onlyUnlocked() public {
       ERC20 token = ERC20(_tokenContract);
       token.transfer(owner, _amount);
    }
}