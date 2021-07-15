/**
 *Submitted for verification at BscScan.com on 2021-07-15
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

// test70701
contract OlympicsStaking {
    
    using SafeMath for uint8;
    using SafeMath for uint256;
    
    address payable private owner;
    bool public _lock ;
    bool public _canClaim ;
    bool public _refund ;
    uint256 public fee ;
    uint256 public totalReward ;
    uint8 public winner ;
    uint256 public TVL ;
    mapping (uint8 => mapping(address => uint256)) public ledger ;
    mapping (uint8 => mapping(address => bool)) public stakers ;
    mapping (uint8 => uint256) public poolValue ;
    mapping (address => uint256) public userTotalStaking ;
    mapping (address => uint256) private userCanWithdraw ;
    
    constructor() {
        owner = msg.sender ;
        _lock = true ;
        _canClaim = false ;
        _refund = false ;
        TVL = 0 ;
        fee = 0 ;
        totalReward = 0 ;
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
    
    modifier canRefund() {
        require(_refund) ;
        _;
    }
    
    event stake(uint8 pool, address staker, uint256 stakingValue) ;
    
    event takeOut(address taker, uint256 claimValue) ;
    
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
    
    function openRefund() public whenLocked onlyOwner returns (bool) {
        _refund = true ;
        return _refund;
    }
    
    function isStaker(uint8 _pool, address _addr) internal view returns (bool) {
        return stakers[_pool][_addr] ;
    }
    
    function staking(uint8 _pool) public whenNotLocked payable {
        require(msg.value > 0 ) ;
        
        if (!isStaker(_pool, msg.sender)) {
            stakers[_pool][msg.sender] = true ;
        }
        
        ledger[_pool][msg.sender] = ledger[_pool][msg.sender].add(msg.value) ;
        userTotalStaking[msg.sender] = userTotalStaking[msg.sender].add(msg.value) ;
        poolValue[_pool] = poolValue[_pool].add(msg.value) ;
        TVL = TVL.add(msg.value) ;
        
        emit stake(_pool, msg.sender, msg.value) ;
    }
    
    function getWinner(uint8 _winner) public onlyOwner whenLocked {
        
        TVL = address(this).balance ;
        fee = TVL.div(40) ;
        totalReward = TVL.sub(fee) ;
        
        winner = _winner ;
    }
    
    function claim() public whenLocked canClaim {

        if (winner == 0) {
            userCanWithdraw[msg.sender] = (userTotalStaking[msg.sender].mul(39)).div(40) ;
            userTotalStaking[msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw[msg.sender]) ;
            
            emit takeOut(msg.sender, userCanWithdraw[msg.sender]) ;
        }
        else {
            userCanWithdraw[msg.sender] = totalReward.mul(ledger[winner][msg.sender]).div(poolValue[winner]) ;
            ledger[winner][msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw[msg.sender]) ;
            
            emit takeOut(msg.sender, userCanWithdraw[msg.sender]) ;
        }
    }
    
    function end() public whenLocked canClaim onlyOwner {
        owner.transfer(fee) ;
        fee = 0 ;
    }
    
    function emergencyRefund() public whenLocked canRefund {

        userCanWithdraw[msg.sender] = (userTotalStaking[msg.sender]) ;
        userTotalStaking[msg.sender] = 0 ;
        msg.sender.transfer(userCanWithdraw[msg.sender]) ;
            
        emit takeOut(msg.sender, userCanWithdraw[msg.sender]) ;
    }
}