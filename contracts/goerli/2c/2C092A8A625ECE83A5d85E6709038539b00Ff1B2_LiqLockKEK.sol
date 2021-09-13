/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Ownable {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _Owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }
    
    modifier onlyOwner() {
        require(_Owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address _address) public virtual {
        require(msg.sender == _Owner);
        _Owner = _address;
        emit OwnershipTransferred(msg.sender, _address);
    }                                                                                        
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface SushiFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface SushiV2Pair { 
    function balanceOf(address _address) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function token0() external returns (address);
    function token1() external returns (address);
}

contract LiqLockKEK is Ownable {
    using SafeMath for uint256;
    
    SushiFactory private Factory;
    
    address private _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private _arbiLock = 0x7a42241aa1bF87259b4CCDe35B987065025A2007;
    address payable public devaddr;
    uint256 private _lockFee = 25000000000000000; // .025 ETH
    uint256 private _arbiLockTokenBurn = 10000 * 10 ** 9; // .025 ETH
    mapping (address => bool) private _Locked;
    mapping (address => uint256) private _PairRelease;
    mapping (address => bool) private _PairBurned;
    mapping (address => address) private _PayoutAddress;
    address[] private _allPairs;
    
    event Lock (address Pair, address Token0, address Token1, address Payout, uint256 Amount, uint256 Epoch);
    event ExtendLock (address Pair, address Token0, address Token1, address Payout, uint256 Epoch);
    event SetBurn (address Pair);

    constructor() payable {
        Factory = SushiFactory(_Factory);
        devaddr = payable(msg.sender);
    }
    
    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }
    
    function setLockFee(uint256 lockFee) public onlyOwner {
        _lockFee = lockFee;
    }
    
    function setTokenBurnAmount(uint256 arbiLockTokenBurn) public onlyOwner {
        _arbiLockTokenBurn = arbiLockTokenBurn;
    }
    
    function lockTokensStandard(address _sushiPair, uint256 _epoch, address _tokenPayout, uint256 _amount) external payable {
        SushiV2Pair(_sushiPair).approve(address(this), type(uint).max);
        if (_lockFee > 0)
            devaddr.transfer(_lockFee);
        require(SushiV2Pair(_arbiLock).balanceOf(_sushiPair) >= _arbiLockTokenBurn.sub(_arbiLockTokenBurn.div(20)), "Your LP Pair must hold the specified amount of ArbiLock Tokens");
        require(Factory.getPair(SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1()) == _sushiPair, "Please only deposit SushiV2 tokens");
        require(SushiV2Pair(_sushiPair).balanceOf(msg.sender).mul(100).div(SushiV2Pair(_sushiPair).totalSupply()) >= 50, "You must deposit at least 50% of LP Tokens");
        require(!_Locked[_sushiPair], "Liquidity already locked before");
        require(_epoch > block.timestamp, "Liq Lock needs to be in the future");
        _PairRelease[_sushiPair] = _epoch;
        _PayoutAddress[_sushiPair] = _tokenPayout;
        SushiV2Pair(_sushiPair).transferFrom(address(msg.sender), address(this), _amount);
        _Locked[_sushiPair] = true;
        addPair(_sushiPair);
        
        emit Lock(_sushiPair, SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1(), _PayoutAddress[_sushiPair], _amount, _epoch);
    }
    
    function lockTokensETHPay(address _sushiPair, uint256 _epoch, address _tokenPayout, uint256 _amount) external payable {
        SushiV2Pair(_sushiPair).approve(address(this), type(uint).max);
        if (_lockFee > 0)
            devaddr.transfer(_lockFee.mul(2));
        require(Factory.getPair(SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1()) == _sushiPair, "Please only deposit SushiV2 tokens");
        require(SushiV2Pair(_sushiPair).balanceOf(msg.sender).mul(100).div(SushiV2Pair(_sushiPair).totalSupply()) >= 50, "You must deposit at least 50% of LP Tokens");
        require(!_Locked[_sushiPair], "Liquidity already locked before");
        require(_epoch > block.timestamp, "Liq Lock needs to be in the future");
        _PairRelease[_sushiPair] = _epoch;
        _PayoutAddress[_sushiPair] = _tokenPayout;
        SushiV2Pair(_sushiPair).transferFrom(address(msg.sender), address(this), _amount);
        _Locked[_sushiPair] = true;
        addPair(_sushiPair);
        
        emit Lock(_sushiPair, SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1(), _PayoutAddress[_sushiPair], _amount, _epoch);
    }
    
    function releaseTokens(address _sushiPair) external {
        require(msg.sender == _PayoutAddress[_sushiPair]);
        require(_Locked[_sushiPair], "No liquidity locked currently");
        require(SushiV2Pair(_sushiPair).balanceOf(address(this)) > 0, "No tokens to release");
        require(block.timestamp > _PairRelease[_sushiPair], "Lock expiration not reached");

        SushiV2Pair(_sushiPair).approve(address(this), SushiV2Pair(_sushiPair).balanceOf(address(this)));
        SushiV2Pair(_sushiPair).transfer(_PayoutAddress[_sushiPair], SushiV2Pair(_sushiPair).balanceOf(address(this)));
        _Locked[_sushiPair] = false;
        
        removePair(_sushiPair);
    }
    
    function extendLock(address _sushiPair, uint256 _epoch) external {
        require(msg.sender == _PayoutAddress[_sushiPair]);
        require(_Locked[_sushiPair], "No liquidity locked currently");
        require(SushiV2Pair(_sushiPair).balanceOf(address(this)) > 0, "No tokens to release");
        require(_epoch > _PairRelease[_sushiPair], "Lock extension needs to be greater than current lock release timestamp");
        _PairRelease[_sushiPair] = _epoch;

        emit ExtendLock(_sushiPair, SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1(), _PayoutAddress[_sushiPair], _epoch);
    }
    
    function addLPToLock(address _sushiPair, uint256 _amount) external payable {
        require(msg.sender == _PayoutAddress[_sushiPair], "You have not locked liquidity before.");
        SushiV2Pair(_sushiPair).approve(address(this), type(uint).max);
        require(Factory.getPair(SushiV2Pair(_sushiPair).token0(), SushiV2Pair(_sushiPair).token1()) == _sushiPair, "Please only deposit SushiV2 tokens");
        require(_Locked[_sushiPair], "You have not locked liquidity before.");
        SushiV2Pair(_sushiPair).transferFrom(address(msg.sender), address(this), _amount);
    }
    
    function setBurn(address _sushiPair) external {
        require(msg.sender == _PayoutAddress[_sushiPair]);
        _PayoutAddress[_sushiPair] = address(0);
        _PairBurned[_sushiPair] = true;

        emit SetBurn(_sushiPair);
    }

    function getLockedTokens(address _sushiPair) external view returns (bool Locked, uint256 ReleaseDate, address PayoutAddress) {
        if(block.timestamp < _PairRelease[_sushiPair])
            return (true, _PairRelease[_sushiPair], _PayoutAddress[_sushiPair]);
        return (false, _PairRelease[_sushiPair], _PayoutAddress[_sushiPair]);
    }
    
    function lockedPercent(address _sushiPair) external view returns (uint256) {
        return SushiV2Pair(_sushiPair).balanceOf(address(this)).mul(100).div(SushiV2Pair(_sushiPair).totalSupply());
    }
    
    function checkLockFee() external view returns (uint256) {
        return _lockFee;
    }
    
    function checkTokenBurnFee() external view returns (uint256) {
        return _arbiLockTokenBurn;
    }
    
    function getAllPairs()public view returns(address[] memory){
        return _allPairs;
    }

    function addPair(address Sushipair) internal returns (bool success) {
      for(uint256 i=0; i < _allPairs.length; i++ ){
           if(_allPairs[i] == address(Sushipair))
                return false;
      }
      _allPairs.push(Sushipair);
      return true;
    }
    
    function removePair(address Sushipair) internal returns(bool success) {
        for (uint i; i< _allPairs.length-1; i++){
             if(_allPairs[i] == address(Sushipair))
                _allPairs[i] =_allPairs[i+1];
        }
        _allPairs.pop();
        return true;
    }
}