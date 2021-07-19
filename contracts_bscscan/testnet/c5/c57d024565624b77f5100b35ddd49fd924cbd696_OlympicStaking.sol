/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6 ;

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

contract OlympicStaking {
    
    using SafeMath for uint8;
    using SafeMath for uint32;
    using SafeMath for uint256;
    
    address payable private owner;
    mapping (uint32 => bool) public _open ;
    mapping (uint32 => bool) public _claim ;
    mapping (uint32 => bool) public _refund ;
    mapping (uint32 => uint256) public fee ;
    mapping (uint32 => uint256) public totalReward ;
    mapping (uint32 => uint8) public winner ;
    mapping (uint32 => uint256) public gameTVL ;
    mapping (uint32 => mapping (uint8 => mapping(address => uint256))) public ledger ;
    mapping (uint32 => mapping (uint8 => mapping(address => bool))) public stakers ;
    mapping (uint32 => mapping (uint8 => uint256)) public poolValue ;
    mapping (uint32 => mapping (address => uint256)) public userTotalStaking ;
    mapping (uint32 => mapping (address => uint256)) private userCanWithdraw ;
    
    constructor() {
        owner = msg.sender ;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender) ;
        _;
    }
    
    modifier whenOpen(uint32 _gameNumber) {
        require(_open[_gameNumber]) ;
        _;
    }
    
    modifier whenNotOpen(uint32 _gameNumber) {
        require(!_open[_gameNumber]) ;
        _;
    }
    
    modifier canClaim(uint32 _gameNumber) {
        require(_claim[_gameNumber]) ;
        _;
    }
    
    modifier canRefund(uint32 _gameNumber) {
        require(_refund[_gameNumber]) ;
        _;
    }
    
    event stake(uint32 game, uint8 pool, address staker, uint256 stakingValue) ;
    
    event takeOut(uint32 game, address taker, uint256 claimValue) ;
    
    function open(uint32 _gameNumber) public whenNotOpen(_gameNumber) onlyOwner returns (bool) {
        _open[_gameNumber] = true ;
        return _open[_gameNumber] ;
    }
    
    function close(uint32 _gameNumber) public whenOpen(_gameNumber) onlyOwner returns (bool) {
        _open[_gameNumber] = false ;
        return _open[_gameNumber] ;
    }
    
    function openClaim(uint32 _gameNumber) public whenNotOpen(_gameNumber) onlyOwner returns (bool) {
        _claim[_gameNumber] = true ;
        return _claim[_gameNumber] ;
    }
    
    function openRefund(uint32 _gameNumber) public whenNotOpen(_gameNumber) onlyOwner returns (bool) {
        _refund[_gameNumber] = true ;
        return _refund[_gameNumber] ;
    }
    
    function isStaker(uint32 _gameNumber, uint8 _pool, address _addr) internal view returns (bool) {
        return stakers[_gameNumber][_pool][_addr] ;
    }
    
    function staking(uint32 _gameNumber, uint8 _pool) public whenOpen(_gameNumber) payable {
        require(msg.value > 0 ) ;
        
        if (!isStaker(_gameNumber, _pool, msg.sender)) {
            stakers[_gameNumber][_pool][msg.sender] = true ;
        }
        
        ledger[_gameNumber][_pool][msg.sender] = ledger[_gameNumber][_pool][msg.sender].add(msg.value) ;
        userTotalStaking[_gameNumber][msg.sender] = userTotalStaking[_gameNumber][msg.sender].add(msg.value) ;
        poolValue[_gameNumber][_pool] = poolValue[_gameNumber][_pool].add(msg.value) ;
        gameTVL[_gameNumber] = gameTVL[_gameNumber].add(msg.value) ;
        
        emit stake(_gameNumber, _pool, msg.sender, msg.value) ;
    }
    
    function getWinner(uint32 _gameNumber, uint8 _winner) public onlyOwner whenNotOpen(_gameNumber) {
        
        fee[_gameNumber] = gameTVL[_gameNumber].div(40) ;
        totalReward[_gameNumber] = gameTVL[_gameNumber].sub(fee[_gameNumber]) ;
        winner[_gameNumber] = _winner ;
    }
    
    function claim(uint32 _gameNumber) public whenNotOpen(_gameNumber) canClaim(_gameNumber) {

        if (winner[_gameNumber] == 0) {
            userCanWithdraw[_gameNumber][msg.sender] = (userTotalStaking[_gameNumber][msg.sender].mul(39)).div(40) ;
            userTotalStaking[_gameNumber][msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw[_gameNumber][msg.sender]) ;
            
            emit takeOut(_gameNumber, msg.sender, userCanWithdraw[_gameNumber][msg.sender]) ;
        }
        else {
            userCanWithdraw[_gameNumber][msg.sender] = totalReward[_gameNumber].mul(ledger[_gameNumber][winner[_gameNumber]][msg.sender]).div(poolValue[_gameNumber][winner[_gameNumber]]) ;
            ledger[_gameNumber][winner[_gameNumber]][msg.sender] = 0 ;
            msg.sender.transfer(userCanWithdraw[_gameNumber][msg.sender]) ;
            
            emit takeOut(_gameNumber, msg.sender, userCanWithdraw[_gameNumber][msg.sender]) ;
        }
    }
    
    function end(uint32 _gameNumber) public whenNotOpen(_gameNumber) canClaim(_gameNumber) onlyOwner {
        owner.transfer(fee[_gameNumber]) ;
        fee[_gameNumber] = 0 ;
    }
    
    function emergencyRefund(uint32 _gameNumber) public whenNotOpen(_gameNumber) canRefund(_gameNumber) {

        userCanWithdraw[_gameNumber][msg.sender] = (userTotalStaking[_gameNumber][msg.sender]) ;
        userTotalStaking[_gameNumber][msg.sender] = 0 ;
        msg.sender.transfer(userCanWithdraw[_gameNumber][msg.sender]) ;
            
        emit takeOut(_gameNumber, msg.sender, userCanWithdraw[_gameNumber][msg.sender]) ;
    }
}