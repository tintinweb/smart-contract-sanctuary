//SourceUnit: lpmint.sol

pragma solidity ^0.5.0;


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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
	
	function decimals() external view returns (uint8);
	
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}

contract OUTTOKEN {
	using SafeMath for uint256;
	IERC20 outtoken = IERC20(0x41a9e0a5e067524e2dc6dd9460022f0cbbbb631141);
	uint256 public outAmountDay;
	uint256 public outAmountSecond;
	
	mapping (address => uint256) private _rewardMap;
	mapping (address => uint256) private _rewardShareMap;
	mapping (address => uint256) private _withdrawMap;
	
	function _initOuttoken(uint256 _outAmountDay) internal{
		outAmountDay = _outAmountDay.mul(10000000000);
		outAmountSecond = outAmountDay.div(86400);
	}
	
	function getHaveRewardOutToken(address account) public view returns (uint256){
		return _rewardMap[account];
	}
	
	function getHaveWithdrawOutToken(address account) public view returns (uint256){
		return _withdrawMap[account];
	}
	
	function getShareRewardOuttoken(address account) public view returns (uint256){
		return _rewardShareMap[account];
	}
	
	function _withdrawOutToken(address account,uint256 amount) internal {
		_withdrawMap[account] = _withdrawMap[account].add(amount);
		outtoken.transfer(account,amount);
	}
	
	function _rewardOutToken(address user,uint256 amount) internal{
		_rewardMap[user] = _rewardMap[user].add(amount);
	}
	
	function _rewardShareOutToken(address parent,uint256 amount) internal{
		_rewardShareMap[parent] = _rewardShareMap[parent].add(amount);
	}
}

contract INTOKEN {

	using SafeMath for uint256;
	IERC20 intoken;
	uint256 public totalSupply;
	mapping (address => uint256) private _balances;
	
	function _initIntoken() internal{
		intoken = IERC20(0x412d66e679d2db5400fe2bcdff261b8c1a7f895a2d);
	}
	
	function _dispositInToken(uint256 amount) internal returns(bool){
		intoken.transferFrom(msg.sender,address(this),amount);
		totalSupply = totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		return true;
	}
	
	function balanceOfIntoken(address account) public view returns (uint256){
		return _balances[account];
	}
	
	function _withdrawInToken(uint256 amount) internal returns(bool){
		totalSupply = totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		intoken.transfer(msg.sender,amount);
		return true;
	}
}

contract REWARDPOOL {
	using SafeMath for uint256;
	struct Pool {
        uint256 startTime;
		uint256 endTime;
		uint256 unit;
    }
	Pool[] pools;
	uint256 private index;
	
	function _initPool() internal{
		pools.push(Pool(now,0,0));
	}
	
	function _createPool(uint256 unit) internal returns(uint256){
		Pool storage per = pools[index];
		per.endTime = now;
		index = index+1;
		pools.push(Pool(now,0,unit));
		return index;
	}
	
	function getPoolReward(uint256 num,uint256 start) public view returns (uint256){
		require(start<=index);
		uint256 reward;
		if(start < index){
			for(uint256 i=start;i<index;i++){
				Pool memory p = pools[i];
				reward = reward.add(num.mul(p.unit).mul(p.endTime.sub(p.startTime)));
			}
		}
		Pool memory p = pools[index];
		reward = reward.add(num.mul(p.unit).mul(now.sub(p.startTime)));
		return reward.div(10000000000);
	}
	
	function getPoolIndex() public view returns (uint256){
		return index;
	}
	
	function getRewardNow() public view returns (uint256,uint256){
		Pool memory p = pools[index];
		return (p.startTime,p.unit);
	}
	
	function getUserStartTime(uint256 num) public view returns (uint256){
		if(num == 0){
			return 0;
		}
		Pool memory p = pools[num];
		return p.startTime;
	}
}

contract MINT is INTOKEN, OUTTOKEN, REWARDPOOL {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
	mapping (address => uint256) private _startIndex;
	mapping (address => address) private _shareship;
	
	uint256 public _MAXINDEX = 10**10;
	
	address public manager;
    constructor () public{
        _initIntoken();
		_initOuttoken(360*1000000);
		_initPool();
    }
	
	modifier onlyManager() {
		require(msg.sender == manager);
		_;
	}
	function changeManager(address newManager) public onlyManager {
		require(newManager != address(0));
		manager = newManager;
	}
	
	function setAmountDay(uint256 _outAmountDay) public onlyManager returns (bool){
		_initOuttoken(_outAmountDay);
		return true;
	}
	
	
	function getUnit() public view returns (uint256){
		if(totalSupply == 0){
			return 0;
		}
		return outAmountSecond.div(totalSupply);
	}
	
	function getStartIndex(address user) public view returns (uint256){
		return _startIndex[user];
	}
	
	function setShareship(address parent) public returns (bool){
		require(parent != address(0),'not bee 0 address');
		require(_shareship[msg.sender] == address(0),'have set');
		_shareship[msg.sender] = parent;
		return true;
	}
	
	function getshare(address user) public view returns(address){
		return _shareship[user];
	}
	
	//1,质押
	//2,前期质押结算
	//3,增加新的pool
	function dipositInToken(uint256 amount) public returns(bool){
		require(amount>0);
		uint256 inTokenBalance = balanceOfIntoken(msg.sender);
		if(inTokenBalance>0){
			uint256 start = _startIndex[msg.sender];
			uint256 reward = getPoolReward(inTokenBalance,start);
			_rewardOutToken(msg.sender,reward);
		}
		_dispositInToken(amount);
		uint256 poolIndex = _createPool(getUnit());
		_startIndex[msg.sender] = poolIndex;
		return true;
	}
	
	//1,赎回
	//2,前期质押结算
	//3,增加新的pool
	function withdrawInToken(uint256 amount) public returns(bool){
		require(amount>0);
		uint256 inTokenBalance = balanceOfIntoken(msg.sender);
		if(inTokenBalance>0){
			uint256 start = _startIndex[msg.sender];
			uint256 reward = getPoolReward(inTokenBalance,start);
			_rewardOutToken(msg.sender,reward);
		}
		_withdrawInToken(amount);
		uint256 poolIndex = _createPool(getUnit());
		if(inTokenBalance>amount){
			_startIndex[msg.sender] = poolIndex;
		}else{
			_startIndex[msg.sender] = _MAXINDEX;
		}
		return true;
	}
	
	//1,提取奖励
	//2,结算的够不够
	//3,结算的不够看整体
	function withdrawOutTokenV1(uint256 amount) public returns(bool){
		uint256 haveReward = getHaveRewardOutToken(msg.sender);
		uint256 havewithdraw = getHaveWithdrawOutToken(msg.sender);
		uint256 withdrawOutTokenOver = havewithdraw.add(amount);
		if(haveReward < withdrawOutTokenOver){
			haveReward = getRewardOuttoken(msg.sender);
		}
		haveReward = haveReward.add(getShareRewardOuttoken(msg.sender));
		require(haveReward >= withdrawOutTokenOver,'v1');
		_withdrawOutToken(msg.sender,amount);
		address parent = _shareship[msg.sender];
		if( parent != address(0)){
			_rewardShareOutToken(parent,amount.div(10));
		}
		return true;
	}
	
	function withdrawOutTokenV2(uint256 amount) public returns(bool){
		uint256 haveReward = getRewardOuttoken(msg.sender);
		uint256 havewithdraw = getHaveWithdrawOutToken(msg.sender);
		haveReward = haveReward.add(getShareRewardOuttoken(msg.sender));
		require(haveReward >= havewithdraw.add(amount),'v2');
		_withdrawOutToken(msg.sender,amount);
		address parent = _shareship[msg.sender];
		if( parent != address(0)){
			_rewardShareOutToken(parent,amount.div(10));
		}
		return true;
	}
	
	function exit() public returns(bool){
		uint256 inTokenBalance = balanceOfIntoken(msg.sender);
		if(inTokenBalance>0){
			withdrawInToken(inTokenBalance);
		}
		uint256 reward = getRewardOuttoken(msg.sender);
		uint256 shareReward = getShareRewardOuttoken(msg.sender);
		uint256 havewithdraw = getHaveWithdrawOutToken(msg.sender);
		uint256 allReward = reward.add(shareReward);
		if(allReward>havewithdraw){
			uint256 amount = allReward.sub(havewithdraw);
			_withdrawOutToken(msg.sender,amount);
			address parent = _shareship[msg.sender];
			if( parent != address(0)){
				_rewardShareOutToken(parent,amount.div(10));
			}
		}
		return true;
	}
	
	//查询挖矿具体数量(已经结算和未结算)
	function getRewardOuttoken(address user) public view returns (uint256){
		uint256 start = _startIndex[user];
		if(start == 0){
			return 0;
		}else{
			uint256 haveReard = getHaveRewardOutToken(user);
			uint256 inTokenBalance = balanceOfIntoken(user);
			if(inTokenBalance>0){
				haveReard = haveReard.add(getPoolReward(inTokenBalance,start));
			}
			return haveReard;
		}
	}
	
	function getUserData(address user) public view returns (address,uint256,uint256,uint256,uint256,uint256){
		uint256 mintReward = getRewardOuttoken(user);
		uint256 shareReward = getShareRewardOuttoken(user);
		uint256 havewithdraw = getHaveWithdrawOutToken(user);
		uint256 inTokenBalance = balanceOfIntoken(user);
		uint256 unitNow = getUnit().mul(inTokenBalance);
		return (_shareship[user],unitNow,inTokenBalance,mintReward,shareReward,havewithdraw);
	}
}