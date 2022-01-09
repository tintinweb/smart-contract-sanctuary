// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 <0.9.0;

interface StakingMP {
    function getUserTotalInvestedTarif(address userAddress, uint256 id) external view returns(uint256);
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeMath.sol";

contract SaleWL {
    using SafeMath for uint256;

    uint256 private _START_TIME;
    uint256 private _SALE_DAYS;
    uint256 private _RATE;
    uint256 private _minBUSD;
    uint256 private _basevar;
    uint256 private _forSale;
    uint256 private _divider;
    uint256 private _round = 1;
    bool private _status;
    address private _owner;
    address private _token;
    uint256 private _totalSold;
    IERC20 constant private busd = IERC20(0x231DE287cE9a4ca39CE8Fa669F0C593D6262523b);// Token BUSD
    StakingMP constant private staking = StakingMP(0xa7dCdD1CA05058a9279adE36c24561c3975e6D74); // Staking With List
    
    struct Plan {
        uint256 weight;
    }

    struct Limit {
        uint256 timestamp;
        uint256 percent;
    }

    struct User {
        mapping(uint256 => uint256) invested;
        uint256 totalInvested;
        uint256 balance;
        uint256 tw;
        uint256 round;
    }

    mapping(address => User) private users;

    Plan[] public plans;
    Limit[] public limits;

    constructor(
        uint256 start_time,
        uint256 sale_days,
        uint256 rate,
        uint256 minBUSD,
        uint256 basevar,
        uint256 forSale,
        bool status,
        address owner,
        uint256 divider){
            _START_TIME = start_time;
            _SALE_DAYS = sale_days;
            _RATE = rate;
            _minBUSD = minBUSD.mul(10 ** 18);
            _basevar = basevar.mul(10 ** 18);
            _forSale = forSale.mul(10 ** 18);
            _status = status;
            _owner = owner;
            _divider = divider;

            plans.push(Plan({weight: 10}));
            plans.push(Plan({weight: 10}));
            plans.push(Plan({weight: 25}));
            plans.push(Plan({weight: 25}));
            plans.push(Plan({weight: 75}));
            plans.push(Plan({weight: 75}));
            plans.push(Plan({weight: 150}));
            plans.push(Plan({weight: 150}));
    }

    function checkAddress(address userAddress, uint256 id) public view returns(uint256){
        return staking.getUserTotalInvestedTarif(userAddress, id);
    }

    function getWeight(uint256 id) public view returns(uint256){
        return plans[id].weight;
    }

    function invest(uint256 _amount) public {
        require(block.timestamp >= _START_TIME,"Expect the start");
        require(_status == true,"Sale ended1");
        require(_token != address(0),"Token not specified");
        require(getLeftToken() >= _minBUSD.div(_RATE).mul(_divider),"Sale ended2");
        uint256 limit = getMaxBusdUser(msg.sender);
        require(limit > 0,"You did not participate in staking");
        if(block.timestamp < _START_TIME.add(_SALE_DAYS)){
            if(users[msg.sender].round == _round){
                require(limit >= (_amount.add(users[msg.sender].invested[_round])),"You cannot invest");
                limit = limit.sub(users[msg.sender].invested[_round]);
            }
        }
        if(block.timestamp >= _START_TIME.add(_SALE_DAYS) && getLeftToken() >= _minBUSD.div(_RATE).mul(_divider)){
            _START_TIME = block.timestamp;
            _round++;
        }
        require(block.timestamp <= _START_TIME.add(_SALE_DAYS),"Sale ended3");
        require(_amount >= _minBUSD,"Minimum amount limitation");
        require(_amount <= limit,"Maximum amount limitation");
        require(busd.balanceOf(msg.sender) >= _amount,"You do not have the required amount");
        uint256 tokens = _amount.div(_RATE).mul(_divider);
        require(getLeftToken() >= tokens,"No tokens left");
        uint256 allowance = busd.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        require(busd.transferFrom(msg.sender, address(this),_amount),"Error transferFrom");
        User storage user = users[msg.sender];
        user.totalInvested = users[msg.sender].totalInvested.add(_amount);
        user.balance = user.balance.add(tokens);
        user.invested[_round] = (users[msg.sender].invested[_round]).add(_amount);
        user.round = _round;
        _totalSold = _totalSold.add(tokens);
    }

    function withdrawingUserTokens() public {
        require(getLeftToken() < _minBUSD.div(_RATE).mul(_divider) || _status == false,"Expect the end of the sell");
        require(getUserWithdrawNow(msg.sender) > 0, "You have not tokens");
        require(getContractBalanceToken() >= getUserWithdrawNow(msg.sender), "Not enough tokens");
        require(_token != address(0),"Token not specified");
        IERC20 token = IERC20(_token);// Token
        require(token.transfer(msg.sender, getUserWithdrawNow(msg.sender)));
        User storage user = users[msg.sender];
        user.tw = block.timestamp;
    }

    function withdrawingOwnerBusd() public {
        require(msg.sender == _owner);
        busd.transfer(msg.sender, busd.balanceOf(address(this)));
    }

    function withdrawingOwnerTokens() public {
        require(msg.sender == _owner);
        require(_token != address(0),"Token not specified");
        IERC20 token = IERC20(_token);// Token
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function getUserLimitNow(address userAddress) public view returns(uint256){
        if(_token == address(0)){
            return 0;
        }
        uint256 weight;
        for(uint256 i=0;i<8;i++){
            if(checkAddress(userAddress,i)>0){
                weight = weight.add(plans[i].weight);
            }
        }
        if(weight == 0){
            return 0;
        }
        if(getLeftToken() < _minBUSD.div(_RATE).mul(_divider)){
            return 0;
        }
        uint256 limit;
        if(block.timestamp < _START_TIME.add(_SALE_DAYS)){
            if(users[userAddress].round == 0){
                limit = _basevar.mul(weight).div(10);
            }
            if(users[userAddress].round == _round){
                limit = (_basevar.mul(weight).div(10)).sub(users[userAddress].invested[_round]);
            }
        }
        if(block.timestamp >= _START_TIME.add(_SALE_DAYS) && getLeftToken() >= _minBUSD.div(_RATE).mul(_divider)){
            limit = _basevar.mul(weight).div(10);
        }
        if(_round > users[msg.sender].round){
            limit = _basevar.mul(weight).div(10);
        }
        return limit;
    }

    function getUserWithdrawNow(address userAddress) public view returns(uint256) {
        if(getLeftToken() < _minBUSD.div(_RATE).mul(_divider)){
            uint256 percent;
            for(uint256 i=0;i<limits.length;i++){
                if(limits[i].timestamp <= block.timestamp){
                    if(limits[i].timestamp > users[userAddress].tw){
                        percent = percent.add(limits[i].percent);
                    }
                }
            }
            return users[userAddress].balance.mul(percent).div(100);
        }else{
            return 0;
        }
    }

    function getNextWithdrawalDate() public view returns(uint256) {
        uint256 timestamp;
        for(uint256 i=0;i<limits.length;i++){
            if(limits[i].timestamp >= block.timestamp){
                if(limits[i].timestamp > _START_TIME.add(_SALE_DAYS)){
                    timestamp = limits[i].timestamp;
                    break;
                }
            }
        }
		return timestamp;
	}

    function getRound() public view returns(uint256){
        return _round;
    }

    function getListWithdrawalDate() public view returns(Limit[] memory) {
		return limits;
	}

    function getUserTotalInvested(address userAddress) public view returns(uint256) {
		return users[userAddress].totalInvested;
	}

    function getUserTokens(address userAddress) public view returns(uint256) {
		return users[userAddress].balance;
	}

    function getContractBalanceToken() public view returns (uint256) {
        require(_token != address(0),"Token not specified");
        IERC20 token = IERC20(_token);// Token
		return token.balanceOf(address(this));
	}

    function getContractBalanceBusd() public view returns (uint256) {
		return busd.balanceOf(address(this));
	}

    function getLeftToken() public view returns (uint256) {
        return _forSale.sub(_totalSold);
    }

    function getStartTime() public view returns (uint256) {
        return _START_TIME;
    }

    function getSaleDays() public view returns (uint256) {
        return _SALE_DAYS;
    }

    function getEndSale() public view returns (uint256) {
        return _START_TIME.add(_SALE_DAYS);
    }

    function getRate() public view returns (uint256) {
        return _RATE;
    }

    function getDivider() public view returns (uint256) {
        return _divider;
    }

    function getMinBusd() public view returns (uint256) {
        return _minBUSD;
    }

    function getBaseVar() public view returns (uint256) {
        return _basevar;
    }

    function getMaxBusdUser(address addressAccount) public view returns (uint256) {
        uint256 weight;
        for(uint256 i=0;i<8;i++){
            if(checkAddress(addressAccount,i)>0){
                weight = weight.add(plans[i].weight);
            }
        }
        return _basevar.mul(weight).div(10);
    }

    function getForSale() public view returns (uint256) {
        return _forSale;
    }

    function getStatus() public view returns (bool) {
        return _status;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getTotalSold() public view returns (uint256) {
        return _totalSold;
    }

    function setStartTime(uint256 _x) public {
        require(msg.sender == _owner);
        _START_TIME = _x;
    }

    function setSaleDays(uint256 _x) public {
        require(msg.sender == _owner);
        _SALE_DAYS = _x;
    }

    function setRate(uint256 _x) public {
        require(msg.sender == _owner);
        _RATE = _x;
    }

    function setDivider(uint256 _x) public {
        require(msg.sender == _owner);
        _divider = _x;
    }

    function setMinBusd(uint256 _x) public {
        require(msg.sender == _owner);
        _minBUSD = _x.mul(10 ** 18);
    }

    function setBaseVar(uint256 _x) public {
        require(msg.sender == _owner);
        _basevar = _x.mul(10 ** 18);
    }

    function setForSale(uint256 _x) public {
        require(msg.sender == _owner);
        _forSale = _x.mul(10 ** 18);
    }

    function setTotalSold(uint256 _x) public {
        require(msg.sender == _owner);
        _totalSold = _x.mul(10 ** 18);
    }

    function setStatus(bool _x) public {
        require(msg.sender == _owner);
        _status = _x;
    }

    function setOwner(address _x) public {
        require(msg.sender == _owner);
        _owner = _x;
    }

    function setToken(address _x) public {
        require(msg.sender == _owner);
        _token = _x;
    }

    function setLimits(uint256 _timestamp,uint256 _percent) public {
        require(msg.sender == _owner);
        limits.push(Limit({timestamp: _timestamp,percent: _percent}));
    }

    function editLimits(uint256 id, uint256 _timestamp,uint256 _percent) public {
        require(msg.sender == _owner);
        limits[id].timestamp = _timestamp;
        limits[id].percent = _percent;
    }

    function delLimits() public {
        require(msg.sender == _owner);
        delete limits[limits.length.sub(1)];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}