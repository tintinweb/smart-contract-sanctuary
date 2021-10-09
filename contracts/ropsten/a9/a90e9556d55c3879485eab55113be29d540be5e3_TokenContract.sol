// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./BEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract TokenContract is BEP20, Ownable{
    using SafeMath for uint256;
    uint8 decimal = 18;
    uint256  _totalSupply = 1000000000000000 * 10 ** uint8(decimal);
    constructor (string memory name, string memory symbol) BEP20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    TokenContract private token;
    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 0;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public endsAt = 0;
    
     ///Stack Struct
    struct stakeUserStruct {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }

    uint256 lockperiod = 0 days;
    uint256 ROI = 4761;
    uint256 stakerCount = 0;
    mapping (address => stakeUserStruct) public staker;


    event Staked(address _staker, uint256 _amount);
    event UnStaked(address _staker, uint256 _amount);
    event Harvested(address _staker, uint256 _amount);

    function setStartsAt(uint256 time) onlyOwner public {
        startsAt = time;
    }
    
    function setEndsAt(uint256 time) onlyOwner public {
        endsAt = time;
    }

    function getEndTime() public view returns (uint) {
        if(startsAt < block.timestamp && endsAt > block.timestamp){
            return uint(endsAt).sub(block.timestamp);
        }else{
            return 0;
        }
    }
 
    function updateTime(uint _startsAt, uint _endsAt) onlyOwner public returns (bool) {
        startsAt = _startsAt;
        endsAt = _endsAt;
        return true;
    }
    
    function transferTokens(address _to, uint256 _value) public onlyOwner returns (bool) {
        token.transfer( _to, _value.sub(2).div(100));
        return true;
    }

    function stake (uint256 _amount , address _token) public returns (bool) {
        require(_token != address(0));
		token = TokenContract(payable(_token));
        require(getEndTime() > 0, "Time Out");
        require(TokenContract(_token).balanceOf(msg.sender) > _amount, "Low balance");
        require (token.allowance(msg.sender, address(this)) >= _amount.sub(2).div(100), "You don't have enough tokens");
        require (!staker[msg.sender].isExist, "You already staked");
        token.transfer(address(this), _amount.sub(2).div(100));
        stakeUserStruct memory stakerinfo;
        stakerCount++;

        stakerinfo = stakeUserStruct({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0
        }); 
        staker[msg.sender] = stakerinfo;
        emit Staked(msg.sender, _amount);
        return true;
    }

    function unstake () public returns (bool) {
        require (staker[msg.sender].isExist, "You are not staked");
        require (staker[msg.sender].stakeTime < uint256(block.timestamp).sub(lockperiod), "Amount is in lock period");

        if(_getCurrentReward(msg.sender) > 0){
            _harvest(msg.sender);
        }
        token.transfer(payable(msg.sender), staker[msg.sender].stake.sub(2).div(100));
        emit UnStaked(msg.sender, staker[msg.sender].stake);

        stakerCount--;
        staker[msg.sender].isExist = false;
        staker[msg.sender].stake = 0;
        staker[msg.sender].stakeTime = 0;
        staker[msg.sender].harvested = 0;
        return true;
    }

    function harvest() public returns (bool) {
        _harvest(msg.sender);
        return true;
    }

    function _harvest(address _user) internal {
        require(_getCurrentReward(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward(_user);
        staker[_user].harvested += harvestAmount;
        emit Harvested(_user, harvestAmount);
    }

    function getTotalReward (address _user) public view returns (uint256) {
        return _getTotalReward(_user);
    }

    function _getTotalReward (address _user) internal view returns (uint256) {
        if(staker[_user].isExist){
            return uint256(block.timestamp).sub(staker[_user].stakeTime).mul(staker[_user].stake).mul(ROI).div(1 days);
        }else{
            return 0;
        }
    }
    
     function getCurrentReward (address _user) public view returns (uint256) {
        return _getCurrentReward(_user);
    }

    function _getCurrentReward (address _user) internal view returns (uint256) {
        if(staker[_user].isExist){
            return uint256(getTotalReward(_user)).sub(staker[_user].harvested);
        }else{
            return 0;
        }
        
    }
}