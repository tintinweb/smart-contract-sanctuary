/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity =0.4.26;
//please subscribe to my YouTube channel https://www.youtube.com/channel/UCV9E16whB0EczgYDy8yHzFw
contract ERC20NG{
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed from, address indexed to, uint256 amount);
	uint256 public totalSupply = 10000000 szabo;
	uint256 public totalStakedTokens = 25000 szabo;
	uint8 public constant decimals = 12;
	string public constant name = "EUBIng Token";
	uint256 constant magnitude = 10025000 szabo;
	mapping(address => uint256) public stakingBalance;
	mapping(address => int256) private _magnifiedDividendCorrections;
	uint256 private magnifiedDividendsPerShare;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	function balanceOf(address owner) external view returns (uint256){
		return _balances[owner];
	}
	function allowance(address owner, address spender) external view returns (uint256){
		return _allowances[owner][spender];
	}
	function toInt256Safe(uint256 a) private pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0, "SafeCast: Cast Overflow");
		return b;
	}
	function toUint256Safe(int256 a) private pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	}
	function safeSub(int256 a, int256 b) private pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a), "SafeMath: Subtraction Overflow");
		return c;
	}

	function safeAdd(int256 a, int256 b) private pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath: Addition Overflow");
		return c;
	}
	function transfer(address to, uint256 amount) external returns (bool){
		uint256 reusable = _balances[msg.sender];
		if(reusable < amount){
			return false;
		} else if(amount != 0){
			_balances[msg.sender] = reusable - amount;
			if(to == address(0)){
				totalSupply -= amount;
			} else if(to == address(this)){
				stakingBalance[msg.sender] += amount;
				totalStakedTokens += amount;
				uint256 reusable1 = magnifiedDividendsPerShare;
				uint256 reusable2 = amount * reusable1;
				require(reusable2 / amount == reusable1, "SafeMath: Multiplication Overflow");
				_magnifiedDividendCorrections[msg.sender] = safeSub(_magnifiedDividendCorrections[msg.sender], toInt256Safe(reusable2));
			} else{
				_balances[to] += amount;
			}
		}
		emit Transfer(msg.sender, to, amount);
		return true;
	}
	function transferFrom(address from, address to, uint256 amount) external returns (bool){
		uint256 reusable = _allowances[from][msg.sender];
		if(reusable < amount){
			return false;
		} else if(to == address(this)){
			_allowances[from][msg.sender] = reusable - amount;
			reusable = _balances[from];
			if(reusable < amount){
				return false;
			} else if(amount != 0){
				_balances[from] = reusable - amount;
				if(to == address(0)){
					totalSupply -= amount;
				} else if(to == address(this)){
					stakingBalance[from] += amount;
					totalStakedTokens += amount;
					uint256 reusable1 = magnifiedDividendsPerShare;
					uint256 reusable2 = amount * reusable1;
					require(reusable2 / amount == reusable1, "SafeMath: Multiplication Overflow");
					_magnifiedDividendCorrections[from] = safeSub(_magnifiedDividendCorrections[from], toInt256Safe(reusable2));
				} else{
					_balances[to] += amount;
				}
				emit Transfer(from, to, amount);
				return true;
			}
		}
	}
	function approve(address to, uint256 amount) external returns (bool){
		_allowances[msg.sender][to] = amount;
		emit Approval(msg.sender, to, amount);
		return true;
	}
	function increaseAllowance(address to, uint256 amount) external returns (bool){
		uint256 temp = _allowances[msg.sender][to];
		temp += amount;
		require(temp >= amount, "SafeMath: Addition Overflow");
		_allowances[msg.sender][to] = temp;
		emit Approval(msg.sender, to, temp);
		return true;
	}
	function decreaseAllowance(address to, uint256 amount) external returns (bool){
		uint256 temp = _allowances[msg.sender][to];
		if(temp < amount){
			return false;
		} else{
			_allowances[msg.sender][to] = temp - amount;
			emit Approval(msg.sender, to, temp);
			return true;
		}
	}
	event DividendsDistributed(address indexed from, uint256 weiAmount);
	event DividendWithdrawn(address indexed from, uint256 weiAmount);
	function() external payable{
		uint256 temp1 = msg.value * magnitude;
		require(temp1 / magnitude == msg.value, "SafeMath: Multiplication Overflow");
		temp1 /= totalStakedTokens;
		uint256 temp2 = magnifiedDividendsPerShare;
		temp1 += temp2;
		require(temp1 >= temp2, "SafeMath: Addition Overflow");
		magnifiedDividendsPerShare = temp1;
		emit DividendsDistributed(msg.sender, msg.value);
	}
	function SafeDistributeDividends(uint256 maxStakedTokens) external payable{
		uint256 cachedStakedTokens = totalStakedTokens;
		require(maxStakedTokens >= cachedStakedTokens, "EUBIng frontrunning protection have rejected this transaction!");
		uint256 temp1 = msg.value * magnitude;
		require(temp1 / magnitude == msg.value, "SafeMath: Multiplication Overflow");
		temp1 /= cachedStakedTokens;
		uint256 temp2 = magnifiedDividendsPerShare;
		temp1 += temp2;
		require(temp1 >= temp2, "SafeMath: Addition Overflow");
		magnifiedDividendsPerShare = temp1;
		emit DividendsDistributed(msg.sender, msg.value);
	}
	function dividendOf(address owner) external view returns (uint256){
		uint256 temp1 = magnifiedDividendsPerShare;
		if(temp1 == 0){
			return 0;
		} else{
			uint256 temp2 = stakingBalance[owner];
			//Jessie's commissions
			if(owner == 0x83da448aE434c29Af349508d03bE2a50D5d37cbc){
				temp2 += 25000 szabo;
			}
			uint256 temp3 = temp1 * temp2;
			require(temp3 / temp1 == temp2, "SafeMath: Multiplication Overflow");
			return toUint256Safe(toInt256Safe(temp3) + _magnifiedDividendCorrections[owner]) / magnitude;
		}
	}
	function withdrawDividend() external{
		uint256 temp1 = magnifiedDividendsPerShare;
		if(temp1 != 0){
			uint256 temp2 = stakingBalance[msg.sender];
			//Jessie's commissions
			if(msg.sender == 0x83da448aE434c29Af349508d03bE2a50D5d37cbc){
				temp2 += 25000 szabo;
			}
			uint256 temp3 = temp1 * temp2;
			require(temp3 / temp1 == temp2, "SafeMath: Multiplication Overflow");
			int256 temp4 = _magnifiedDividendCorrections[msg.sender];
			temp3 = toUint256Safe(safeAdd(toInt256Safe(temp3), temp4)) / magnitude;
			_magnifiedDividendCorrections[msg.sender] = safeSub(temp4, toInt256Safe(temp3 * magnitude));
			if(msg.sender.call.value(temp3)()){
				emit DividendWithdrawn(msg.sender, temp3);
			} else{
				revert("EUBIng: can't send ether");
			}
		}
	}
	function withdrawStakedToken(uint256 amount) external returns (bool){
		uint256 reusable1 = stakingBalance[msg.sender];
		if(amount > reusable1 || amount == 0){
			return false;
		} else{
			totalStakedTokens -= amount;
			stakingBalance[msg.sender] = reusable1 - amount;
			_balances[msg.sender] += amount;
			reusable1 = magnifiedDividendsPerShare;
			uint256 reusable2 = amount * reusable1;
			require(reusable2 / amount == reusable1, "SafeMath: Multiplication Overflow");
			_magnifiedDividendCorrections[msg.sender] = safeAdd(_magnifiedDividendCorrections[msg.sender], toInt256Safe(reusable2));
			emit Transfer(address(this), msg.sender, amount);
			return true;
		}
	}
	function withdrawAllStakedTokens() external returns (bool){
		uint256 amount = stakingBalance[msg.sender];
		if(amount == 0){
			return false;
		} else{
			totalStakedTokens -= amount;
			stakingBalance[msg.sender] = 0;
			_balances[msg.sender] += amount;
			uint256 reusable1 = magnifiedDividendsPerShare;
			uint256 reusable2 = amount * reusable1;
			require(reusable2 / amount == reusable1, "SafeMath: Multiplication Overflow");
			_magnifiedDividendCorrections[msg.sender] = safeAdd(_magnifiedDividendCorrections[msg.sender], toInt256Safe(reusable2));
			emit Transfer(address(this), msg.sender, amount);
			return true;
		}
	}
	constructor() public{
		_balances[msg.sender] = 10000000 szabo;
		//Jessie's commissions
		//_burned[0x83da448aE434c29Af349508d03bE2a50D5d37cbc] = 25000 szabo;
	}
}