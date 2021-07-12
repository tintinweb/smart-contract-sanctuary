pragma solidity ^0.5.10;
// SPDX-License-Identifier: CC-BY-SA-2.1-JP
import "./SafeMath.sol";
import "./ownable.sol";

contract LTMToken is ownable {
    using SafeMath for uint;
    
//**************************
//* Variables
//**************************
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
//    uint8 burnPercent = 1;
//    uint8 charityPercent = 1;
//    uint8 holdersPercent = 1;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address charityAddress = 0xE4e99f02a9e184D552941B920090EE6F5E7e8C28;
    uint holdersPoolIn = 0;
    uint holdersPoolOut = 0;
    uint poolSupply = 0;
    uint periodsGap = 1 weeks;
    struct Period {
        uint calculateTime;
        uint poolSupply;
        uint holdersSupply;
        uint remainedBalance;
    }
    mapping(uint => Period) periods;
    uint periodsCount = 0;
    struct Holder {
        uint lastPoolPeriod;
        uint poolShareReceived;
    }
    mapping(address => Holder) holders; 
//**************************
//* Modifiers
//**************************
    modifier isHolder {
        require(balances[msg.sender] > 0,"You are not a token holder.");
        _;
    }
    
//**************************
//* Events
//**************************
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event Mint(address _to, uint _amount);
    
//**************************
//* Main Functions
//**************************
    constructor() public {
        _name = 'LightMoon';
        _symbol = 'LTM';
        _decimals = 9;
        _totalSupply = 1e24;
        balances[admin] = _totalSupply;
    }

// Outputs the name of the token.
    function name() public view returns(string memory) {
        return(_name);
    }
    
// Outputs the symbol of the token.
    function symbol() public view returns(string memory) {
        return(_symbol);
    }
    
// Outputs the number of deciaml places in the token.
    function decimals() public view returns(uint8) {
        return(_decimals);
    }

// Outputs total supply of the token. 
    function totalSupply() public view returns(uint) {
        return(_totalSupply);
    }

// Outputs the token balance of _owner parameter address.
    function balanceOf(address _owner) public view returns(uint256) {
        return(balances[_owner]);
    }
    
// Transfers _amount tokens from the sender to the destination _to address.
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_amount > 0,"Invalid amount.");
        require(_amount <= balanceOf(msg.sender),"Out of balance.");
        require(_to != address(0),"Invalid address.");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        if (msg.sender == admin || tx.origin == admin) {
            balances[_to] = balances[_to].add(_amount);
        } else {
            uint _burnAmount = _amount.div(100);
            uint _charityAmount = _burnAmount;
            uint _holdersAmount = _burnAmount;
            balances[_to] = balances[_to].add(_amount.sub(_burnAmount).sub(_charityAmount).sub(_holdersAmount));
            balances[charityAddress] = balances[charityAddress].add(_charityAmount);
            balances[burnAddress] = balances[burnAddress].add(_burnAmount);
            balances[address(this)] = balances[address(this)].add(_holdersAmount);
            holdersPoolIn = holdersPoolIn.add(_holdersAmount);
            poolSupply = poolSupply.add(_holdersAmount);
        }
        emit Transfer(msg.sender, _to, _amount);
        return(true);
    }
    
// Transfers _amount tokens from _from address (deligated address) to the destionation _to address.
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(_amount <= balanceOf(_from),"Transfer value is out of balance.");
        require(_amount <= allowed[_from][msg.sender],"Transfer value is not allowed.");
        require(_to != address(0),"Receiver value is not valid.");
        balances[_from] = balances[_from].sub(_amount);
        if (_from == admin) {
            balances[_to] = balances[_to].add(_amount);
        } else {
            uint _burnAmount = _amount.div(100);
            uint _charityAmount = _burnAmount;
            uint _holdersAmount = _burnAmount;
            balances[_to] = balances[_to].add(_amount.sub(_burnAmount).sub(_charityAmount).sub(_holdersAmount));
            balances[charityAddress] = balances[charityAddress].add(_charityAmount);
            balances[burnAddress] = balances[burnAddress].add(_burnAmount);
            balances[address(this)] = balances[address(this)].add(_holdersAmount);
            holdersPoolIn = holdersPoolIn.add(_holdersAmount);
            poolSupply = poolSupply.add(_holdersAmount);
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return(true);
    }
    
// Delegates the _spender address to transfer maximum _amount tokens.
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return(true);
    }
    
// get the remained amount that _owner address delegated the _spender address.
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
// Increases delegation of _spender address by _addedValue tokens.
    function increaseAllowance(address _spender, uint256 _addedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

// decreases delegation of _spender address by _subtractedValue tokens.
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

// Holders call this function and get their share from the holders pool.
    function payMyPoolShare() public isHolder {
        require(msg.sender != admin,"Oops, you can not be paid as a holder.");
        uint _sum = 0;
        uint _share;
        uint _period;
        for (uint i = holders[msg.sender].lastPoolPeriod.inc(); i <= periodsCount; i = i.inc()) {
            uint j = i.dec();
            if (periods[j].holdersSupply > 0) {
                _share = balances[msg.sender].mul(periods[j].poolSupply).div(periods[j].holdersSupply).min(periods[j].remainedBalance);
                _sum = _sum.add(_share);
                periods[j].remainedBalance = periods[j].remainedBalance.sub(_share);
            }
            _period = i;
        }
        holdersPoolOut  = holdersPoolOut.add(_sum);
        balances[msg.sender] = balances[msg.sender].add(_sum);
        if (_period > 0)
            holders[msg.sender].lastPoolPeriod = _period;
        holders[msg.sender].poolShareReceived = holders[msg.sender].poolShareReceived.add(_sum);
    }
    
//**************************
//* Admin Functions
//**************************
// Admin calls this function to register a period after the gap between the last period.
    function registerPeriod() public isAdmin {
        if (periodsCount > 0)
            require(now.sub(periods[periodsCount.dec()].calculateTime) > periodsGap,"Periods gap is not reached.");
        require(poolSupply > 0,"Pool supply is zero.");
        uint _holdersSupply = getHoldersSupply();
        require(_holdersSupply > 0,"Holders supply is zero.");
        periods[periodsCount] = Period({
            calculateTime: now,
            poolSupply: poolSupply,
            holdersSupply: _holdersSupply,
            remainedBalance: poolSupply
        });
        periodsCount = periodsCount.inc();
        poolSupply = 0;
    }

//**************************
//* Internal Functions
//**************************
    function _getTimeTo(uint _time) internal view returns(uint) {
        if (now >= _time)
            return(0);
        return(_time.sub(now));
    }

//**************************
//* Setter Functions
//**************************
// Admin calls this function to set the minimum gap between periods. (unit: sec)
    function setPeriodsGap(uint _periodsGap) public {
        require(_periodsGap != periodsGap,"New value required.");
        periodsGap = _periodsGap;
    }

//**************************
//* Getter Functions
//**************************
// gets the sum of tokens that holders hold at this moment.
    function getHoldersSupply() public view returns(uint) {
        return(_totalSupply.sub(balanceOf(admin)));
    }
    
// gets the minimum gap between periods.
    function getPeriodsGap() public view returns(uint) {
        return(periodsGap);
    }
    
// gets the sender pool share that remianed in the holders pool.
    function getMyPoolShare() public view isHolder returns(uint) {
        uint _sum = 0;
        uint _share;
        for (uint i = holders[msg.sender].lastPoolPeriod.inc(); i <= periodsCount; i = i.inc()) {
            uint j = i.dec();
            if (periods[j].holdersSupply > 0) {
                _share = balances[msg.sender].mul(periods[j].poolSupply).div(periods[j].holdersSupply).min(periods[j].remainedBalance);
                _sum = _sum.add(_share);
            }
        }
        return(_sum);
    }
    
// gets number of periods registered.
    function getPeriodsCount() public view returns(uint) {
        return(periodsCount);
    }
    
// get the information of the period with _periodId parameter. (_periodId is counted from 0 to n-1, where n is number of periods.)
    function getPeriod(uint _periodId) public view returns(uint _calculateTime, uint _poolSupply, uint _holdersSupply, uint _remainedBalance) {
        require(_periodId < periodsCount,"Invalid period id.");
        Period memory _period = periods[_periodId];
        _calculateTime = _period.calculateTime;
        _poolSupply = _period.poolSupply;
        _holdersSupply = _period.holdersSupply;
        _remainedBalance = _period.remainedBalance;
    }
    
// gets the information of the holder by _owner address.
    function getHolderInfo(address _owner) public view returns(uint _lastPeriodReceived, uint _poolShareReceivedSum, uint _balance) {
        Holder memory _holder = holders[_owner];
        _lastPeriodReceived = _holder.lastPoolPeriod;
        _poolShareReceivedSum = _holder.poolShareReceived;
        _balance = balances[_owner];
        require(_balance > 0,"Not holder");
    }
    
// gets the information of the sender if holder.
    function getMyInfo() public view isHolder returns(uint _lastPeriodReceived, uint _poolShareReceivedSum, uint _balance) {
        return(getHolderInfo(msg.sender));
    }
    
// gets the information of holders pool.
    function getHoldersPoolInfo() public view returns(uint _holdersPoolIn, uint _holdersPoolOut) {
        _holdersPoolIn = holdersPoolIn;
        _holdersPoolOut = holdersPoolOut;
    }
    
// gets the 
    function getPoolSupply() public view returns(uint) {
        return(poolSupply);
    }
    
// gets the remained time to the next period registration in sec.
    function getTimeToNextPeriod() public view returns(uint) {
        if (periodsCount == 0)
            return(0);
        return(_getTimeTo(periods[periodsCount.dec()].calculateTime.add(periodsGap)));
    }
    
// gets the past time after last period registration in sec.
    function getTimeAfterLastPeriod() public view returns(uint) {
        if (periodsCount == 0)
            return(0);
        return(now.sub(periods[periodsCount.dec()].calculateTime));
    }
}