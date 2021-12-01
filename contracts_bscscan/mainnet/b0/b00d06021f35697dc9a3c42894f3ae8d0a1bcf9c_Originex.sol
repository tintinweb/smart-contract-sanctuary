/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {

	function totalSupply() external view returns(uint256);

	function balanceOf(address account) external view returns(uint256);

	function transfer(address recipient, uint256 amount) external returns(bool);

	function allowance(address owner, address spender) external view returns(uint256);

	function approve(address spender, uint256 amount) external returns(bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns(bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

	function tryAdd(uint256 a, uint256 b) internal pure returns(bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	
	function trySub(uint256 a, uint256 b) internal pure returns(bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}


	function tryMul(uint256 a, uint256 b) internal pure returns(bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}


	function tryDiv(uint256 a, uint256 b) internal pure returns(bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	
	function tryMod(uint256 a, uint256 b) internal pure returns(bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}


	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		return a + b;
	}

	
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		return a - b;
	}


	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		return a * b;
	}


	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return a / b;
	}

	
	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		return a % b;
	}

	
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}


	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}


	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}
abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	constructor() {
		_setOwner(_msgSender());
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view virtual returns(address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	/**
	 * @dev Leaves the contract without owner. It will not be possible to call
	 * `onlyOwner` functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

contract Originex is IERC20, Ownable {

	using SafeMath
	for uint;
	string private _name = "Originex";
	string private _symbol = "OGNX";
	uint8 private _decimals = 18;
	uint private _totalSupply = 21000000 * (10 ** uint256(_decimals));


	mapping(address => uint256) internal _balances;
	mapping(address => mapping(address => uint256)) internal _allowed;

	event Mint(address indexed minter, address indexed account, uint256 amount);
	event Burn(address indexed burner, address indexed account, uint256 amount);

	constructor() {
		_balances[msg.sender] = _totalSupply;
	}

	function name() public view virtual returns(string memory) {
		return _name;
	}

	function symbol() public view virtual returns(string memory) {
		return _symbol;
	}

	function decimals() public view virtual returns(uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns(uint256) {
		return _totalSupply;
	}


	function transfer(
		address _to,
		uint256 _value
	) public
	override returns(bool) {
		require(_to != address(0), 'BEP20: to address is not valid');
		require(_value <= _balances[msg.sender], 'BEP20: insufficient balance');

		_balances[msg.sender] = SafeMath.sub(_balances[msg.sender], _value);
		_balances[_to] = SafeMath.add(_balances[_to], _value);

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function balanceOf(
		address _owner
	) public override view returns(uint256 balance) {
		return _balances[_owner];
	}

	function approve(
		address _spender,
		uint256 _value
	) public override
	returns(bool) {
		_allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	) public override
	returns(bool) {
		require(_from != address(0), 'BEP20: from address is not valid');
		require(_to != address(0), 'BEP20: to address is not valid');
		require(_value <= _balances[_from], 'BEP20: insufficient balance');
		require(_value <= _allowed[_from][msg.sender], 'BEP20: from not allowed');

		_balances[_from] = SafeMath.sub(_balances[_from], _value);
		_balances[_to] = SafeMath.add(_balances[_to], _value);
		_allowed[_from][msg.sender] = SafeMath.sub(_allowed[_from][msg.sender], _value);

		emit Transfer(_from, _to, _value);

		return true;
	}

	function allowance(
		address _owner,
		address _spender
	) public view override
	returns(uint256) {
		return _allowed[_owner][_spender];
	}

	function increaseApproval(
		address _spender,
		uint _addedValue
	) public
	returns(bool) {
		_allowed[msg.sender][_spender] = SafeMath.add(_allowed[msg.sender][_spender], _addedValue);

		emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

		return true;
	}

	function decreaseApproval(
		address _spender,
		uint _subtractedValue
	) public
	returns(bool) {
		uint oldValue = _allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			_allowed[msg.sender][_spender] = 0;
		} else {
			_allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
		}

		emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

		return true;
	}



	function burnFrom(
		address _from,
		uint _amount
	) public
	onlyOwner {
		require(_from != address(0), 'BEP20: from address is not valid');
		require(_balances[_from] >= _amount, 'BEP20: insufficient balance');

		_balances[_from] = _balances[_from].sub(_amount);
		_totalSupply = _totalSupply.sub(_amount);

		emit Burn(msg.sender, _from, _amount);
	}

}