/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.1 ;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract OlympicsStaking {
    
    using SafeMath for uint;
    
    address payable private owner;
    bool public _lock ;
    bool public _canClaim ;
    uint public fee ;
    uint public reward ;
    uint8 public winner ;
    uint public TVL0 ;
    uint public TVL1 ;
    uint public totalTVL ;
    uint public userCanWithdraw ;
    mapping(address => uint) public ledger0 ;
    mapping(address => bool) public stakers0 ;
    mapping(address => uint) public ledger1 ;
    mapping(address => bool) public stakers1 ;
    
    constructor() {
        owner = msg.sender ;
        _lock = true ;
        _canClaim = false ;
        TVL0 = 0 ;
        TVL1 = 0 ;
        totalTVL = 0 ;
        fee = 0 ;
        reward = 0 ;
        userCanWithdraw = 0 ;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender) ;
        _;
    }
    
    modifier whenLocked() {
        require(_lock) ;
        _;
    }
    
    modifier whenNotLocked() {
        require(!_lock) ;
        _;
    }
    
    modifier canClaim() {
        require(_canClaim) ;
        _;
    }
    
    event stake0(address staker, uint stakingValue) ;
    
    event stake1(address staker, uint stakingValue) ;
    
    event takeOut(address taker, uint claimValue) ;
    
    function lock() public whenNotLocked onlyOwner returns (bool) {
        _lock = true ;
        return _lock ;
    }
    
    function unlock() public whenLocked onlyOwner returns (bool) {
        _lock = false ;
        return _lock;
    }
    
    function openClaim() public whenLocked onlyOwner returns (bool) {
        _canClaim = true ;
        return _canClaim;
    }
    
    function isStaker0(address pAddr) internal view returns (bool) {
        return stakers0[pAddr] ;
    }
    
    function staking0() public whenNotLocked payable {
        require(msg.value > 0 ) ;
        
        if (!isStaker0(msg.sender)) {
            stakers0[msg.sender] = true ;
        }
        
        ledger0[msg.sender] = ledger0[msg.sender].add(msg.value) ;
        TVL0 = TVL0.add(msg.value) ;
        
        emit stake0(msg.sender, msg.value) ;
    }
    
    function isStaker1(address pAddr) internal view returns (bool) {
        return stakers1[pAddr] ;
    }
    
    function staking1() public whenNotLocked payable {
        require(msg.value > 0 ) ;
        
        if (!isStaker1(msg.sender)) {
            stakers1[msg.sender] = true ;
        }
        
        ledger1[msg.sender] = ledger1[msg.sender].add(msg.value) ;
        TVL1 = TVL1.add(msg.value) ;
        
        emit stake1(msg.sender, msg.value) ;
    }
    
    function getWinner(uint8 _winner) public onlyOwner whenLocked {
        
        totalTVL = address(this).balance ;
        fee = totalTVL.div(40) ;
        reward = totalTVL.sub(fee) ;
        
        winner = _winner ;
    }
    
    function claim() public whenLocked canClaim {
        if (winner == 0) {
            
            userCanWithdraw = reward.mul(ledger0[msg.sender]).div(TVL0) ;
            ledger0[msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw) ;
            
            emit takeOut(msg.sender, userCanWithdraw) ;
        } 
        else if (winner == 1) {
            
            userCanWithdraw = reward.mul(ledger1[msg.sender]).div(TVL1) ;
            ledger1[msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw) ;
            
            emit takeOut(msg.sender, userCanWithdraw) ;
        } 
        else {
            
            userCanWithdraw = (ledger0[msg.sender].mul(39)).div(40) + (ledger1[msg.sender].mul(39)).div(40) ;
            ledger0[msg.sender] = 0 ;
            ledger1[msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw) ;
            
            emit takeOut(msg.sender, userCanWithdraw) ;
        }
    }
    
    function end() public whenLocked canClaim onlyOwner {
        owner.transfer(fee) ;
        fee = 0 ;
    }
}