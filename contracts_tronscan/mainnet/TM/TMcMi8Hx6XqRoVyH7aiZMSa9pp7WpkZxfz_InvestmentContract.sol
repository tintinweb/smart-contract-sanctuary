//SourceUnit: Contract.sol

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ERC20 {
	function basisPointsRate() external view returns (uint);
	function transferFrom(address from, address to, uint value) external;
}


contract InvestmentContract is Ownable {
	using SafeMath for uint;

	event Deposit(address indexed addr, uint8 package, uint value);
	event Withdraw(address indexed addr, uint8 package, uint value);
	event UpdateProfit(address indexed addr, uint8 package, uint value, bool loss);
	event Subscriptions(address indexed addr, uint8 package, bool subscribed);
	event PoolWalletChange(address oldAddress, address newAddress);
	event NewFee(uint fee);

	mapping (address => uint[5]) private userBalances;

	ERC20 private USDT;

	uint[3] public subscribers;

	uint public fee;

	uint private poolWalletBalance = 0;
	address public poolWallet;

	modifier checkPackage(uint8 _package) {
		require(_package < 3, "Error: Unknown package/wallet");
		_;
	}

	modifier checkWallet(uint8 _wid) {
		require(_wid < 5, "Error: Unknown package/wallet");
		_;
	}

	constructor(address _pool, address _token) public {
		USDT = ERC20(_token);
		subscribers = [0, 0, 0];
		poolWallet = _pool;
	}

	function isAdmin() external view returns (bool) {
		return msg.sender == owner();
	}

	function setFee(uint _fee) external onlyOwner {
		fee = _fee;
		emit NewFee(_fee);
	}

	function changePoolWallet(address _addr) external onlyOwner {
		address prev = poolWallet;
		poolWallet = _addr;
		emit PoolWalletChange(prev, _addr);
	}

	function balance(address _addr) external view returns (uint) {
		uint[5] memory balances = userBalances[_addr];
		uint bl = balances[0].add(balances[1]).add(balances[2]).add(balances[3]).add(balances[4]);
		return bl;
	}

	function balance(address _addr, uint8 _wid) public view checkWallet(_wid) returns (uint) {
		return userBalances[_addr][_wid];
	}

	function subscriptions(address _addr) external view returns (bool low, bool medium, bool high){
		return (balance(_addr, 0) > 0, balance(_addr, 1) > 0, balance(_addr, 2) > 0);
	}

	function deposit(uint8 _package, uint _value) external checkPackage(_package) {
		USDT.transferFrom(msg.sender, poolWallet, _value);
		uint dep_fees = (_value.mul(USDT.basisPointsRate())).div(10000);
		uint actualValue = _value.sub(dep_fees);
		uint currentBalance = userBalances[msg.sender][_package];
		userBalances[msg.sender][_package] = currentBalance.add(actualValue);
		poolWalletBalance = poolWalletBalance.add(actualValue);
		if(currentBalance == 0){
			subscribers[_package] = subscribers[_package].add(1);
			emit Subscriptions(msg.sender, _package, true);
		}
		emit Deposit(msg.sender, _package, _value);
	}

	function tranfer(uint8 _src, uint8 _dst, uint _value) external checkPackage(_dst) {
		require(_src == 3 || _src == 4, "Error: Source can only be 3 or 4");
		uint currentBalance = userBalances[msg.sender][_dst];
		userBalances[msg.sender][_src] = userBalances[msg.sender][_src].sub(_value);
		userBalances[msg.sender][_dst] = currentBalance.add(_value);
		if(currentBalance == 0){
			subscribers[_dst] = subscribers[_dst].add(1);
			emit Subscriptions(msg.sender, _dst, true);
		}
		emit Deposit(msg.sender, _dst, _value);
	}

	function withdraw(address _addr, uint8 _wid, uint _value) external onlyOwner checkWallet(_wid) {
		USDT.transferFrom(poolWallet, _addr, _value.sub(fee));
		userBalances[_addr][_wid] = userBalances[_addr][_wid].sub(_value);
		poolWalletBalance = poolWalletBalance.sub(_value.sub(fee));
		if(userBalances[_addr][_wid] == 0 && _wid < 3){
			subscribers[_wid] = subscribers[_wid].sub(1);
			emit Subscriptions(_addr, _wid, false);
		}
		emit Withdraw(_addr, _wid, _value);
	}

	function increaseBalance(address _addr, uint _value, uint8 _wid) external onlyOwner checkWallet(_wid) {
		uint currentBalance = userBalances[_addr][_wid];
		userBalances[_addr][_wid] = currentBalance.add(_value);
		if(currentBalance == 0 && _wid < 3){
			subscribers[_wid] = subscribers[_wid].add(1);
			emit Subscriptions(msg.sender, _wid, true);
		}
		emit UpdateProfit(_addr, _wid, _value, false);
	}

	function decreaseBalance(address _addr, uint _value, uint8 _wid) external onlyOwner checkWallet(_wid) {
		userBalances[_addr][_wid] = userBalances[_addr][_wid].sub(_value);
		if(userBalances[_addr][_wid] == 0 && _wid < 3){
			subscribers[_wid] = subscribers[_wid].sub(1);
			emit Subscriptions(msg.sender, _wid, false);
		}
		emit UpdateProfit(_addr, _wid, _value, true);
	}

}