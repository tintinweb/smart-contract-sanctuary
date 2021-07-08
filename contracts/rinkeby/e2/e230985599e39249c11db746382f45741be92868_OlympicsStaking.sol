/**
 *Submitted for verification at Etherscan.io on 2021-07-08
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
    uint private fee ;
    uint public TVL0 ;
    uint public TVL1 ;
    uint public TVLall ;
    mapping(address => uint) public ledger0 ;
    mapping(address => bool) public stakers0 ;
    mapping(address => uint) public ledger1 ;
    mapping(address => bool) public stakers1 ;
    address payable [] public stakerList0 ;
    address payable [] public stakerList1 ;
    
    
    constructor() {
        owner = msg.sender ;
        _lock = true ;
        TVL0 = 0 ;
        TVL1 = 0 ;
        TVLall = 0 ;
        fee = 0 ;
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
    
    function lock() public whenNotLocked onlyOwner returns (bool) {
        _lock = true ;
        return _lock ;
    }
    
    function unlock() public whenLocked onlyOwner returns (bool) {
        _lock = false ;
        return _lock;
    }
    
    function isStaker0(address pAddr) internal view returns (bool) {
        return stakers0[pAddr] ;
    }
    
    function staking0() public whenNotLocked payable {
        require(msg.value > 0 ) ;
        if (!isStaker0(msg.sender)) {
            stakers0[msg.sender] = true ;
            stakerList0.push(msg.sender) ;
        }
        ledger0[msg.sender] = ledger0[msg.sender].add(msg.value) ;
        TVL0 = TVL0.add(msg.value) ;
        TVLall = address(this).balance ;
    }
    
    function isStaker1(address pAddr) internal view returns (bool) {
        return stakers1[pAddr] ;
    }
    
    function staking1() public whenNotLocked payable {
        require(msg.value > 0 ) ;
        if (!isStaker1(msg.sender)) {
            stakers1[msg.sender] = true ;
            stakerList1.push(msg.sender) ;
        }
        ledger1[msg.sender] = ledger1[msg.sender].add(msg.value) ;
        TVL1 = TVL1.add(msg.value) ;
        TVLall = address(this).balance ;
    }
    
    function distribute(uint8 _winner) public onlyOwner whenLocked {
        if (0 == _winner) {
            TVLall = address(this).balance ;
            fee = TVLall * 1/40 ;
            TVLall = TVLall.sub(fee) ;
            
            for(uint i = 0; i < stakerList0.length; i++) { 
                stakerList0[i].transfer( TVLall * ledger0[stakerList0[i]]/TVL0 );
            }
            owner.transfer(address(this).balance) ;
        }
        
        else if (1 == _winner) {
            TVLall = address(this).balance ;
            fee = TVLall * 1/40 ;
            TVLall = TVLall.sub(fee) ;
            
            for(uint i = 0; i < stakerList1.length; i++) { 
                stakerList1[i].transfer( TVLall * ledger1[stakerList1[i]]/TVL1 );
            }
            owner.transfer(address(this).balance) ;
        }
    }
    
    function refund() public onlyOwner whenLocked {
        TVLall = address(this).balance ;
        fee = TVLall * 1/40 ;
        TVLall = TVLall.sub(fee) ;
        
        for(uint i = 0; i < stakerList0.length; i++) { 
            stakerList0[i].transfer( ledger0[stakerList0[i]] * 39/40 );
        }
        
        for(uint i = 0; i < stakerList1.length; i++) { 
            stakerList1[i].transfer( ledger1[stakerList1[i]] * 39/40 );
        }
        owner.transfer(address(this).balance) ;
    }
}