pragma solidity ^0.4.24;

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {

	/**
	* @dev Multiplies two numbers, reverts on overflow.
	*/
	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (_a == 0) {
			return 0;
		}

		uint256 c = _a * _b;
		require(c / _a == _b);

		return c;
	}

	/**
	* @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
	*/
	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = _a / _b;
		// assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

		return c;
	}

	/**
	* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b <= _a);
		uint256 c = _a - _b;

		return c;
	}

	/**
	* @dev Adds two numbers, reverts on overflow.
	*/
	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		require(c >= _a);

		return c;
	}
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
	address internal _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/*
	* @dev The Ownable constructor sets the original `owner` o the contract to the sender account
	*/
	constructor() public {
		_owner = msg.sender;
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	/**
	* @dev Allows the current owner to transfer control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function transferOwnership(address newOwner) onlyOwner() public {
		require(newOwner != _owner);
		_transferOwnership(newOwner);
	}

	/**
	* @dev Transfers control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function getOwner() public constant returns(address) {
		return (_owner);
	}
}

/**
* @title Pausable
* @dev Base contract which allows children to implement an emergency stop mechanism.
*/
contract Pausable is Ownable {
	event Paused();
	event Unpaused();

	bool public paused = false;


	/**
	* @dev Modifier to make a function callable only when the contract is not paused.
	*/
	modifier whenNotPaused() {
			require(!paused);
		_;
	}

	/**
	* @dev Modifier to make a function callable only when the contract is paused.
	*/
	modifier whenPaused() {
		require(paused);
		_;
	}

	/**
	* @dev called by the owner to pause, triggers stopped state
	*/
	function pause() public onlyOwner whenNotPaused {
		paused = true;
		emit Paused();
	}

	/**
	* @dev called by the owner to unpause, returns to normal state
	*/
	function unpause() public onlyOwner whenPaused {
		paused = false;
		emit Unpaused();
	}
}

/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
interface IERC20 {
	function totalSupply()
		external view returns (uint256);

	function balanceOf(address _who)
		external view returns (uint256);

	function allowance(address _owner, address _spender)
		external view returns (uint256);

	function transfer(address _to, uint256 _value)
		external returns (bool);

	function approve(address _spender, uint256 _value)
		external returns (bool);

	function transferFrom(address _from, address _to, uint256 _value)
		external returns (bool);

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 value
	);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}


/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract ERC20 is IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) internal balances_;

	mapping (address => mapping (address => uint256)) internal allowed_;

	uint256 internal totalSupply_;

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256) {
		return balances_[_owner];
	}

	/**
	* @dev Function to check the amount of tokens that an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* @return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(
		address _owner,
		address _spender
	 )
		public
		view
		returns (uint256)
	{
		return allowed_[_owner][_spender];
	}

	/**
	* @dev Transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_value <= balances_[msg.sender]);
		require(_to != address(0));

		balances_[msg.sender] = balances_[msg.sender].sub(_value);
		balances_[_to] = balances_[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	* Beware that changing an allowance with this method brings the risk that someone may use both the old
	* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed_[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		returns (bool)
	{
		require(_value <= balances_[_from]);
		require(_value <= allowed_[_from][msg.sender]);
		require(_to != address(0));

		balances_[_from] = balances_[_from].sub(_value);
		balances_[_to] = balances_[_to].add(_value);
		allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Internal function that mints an amount of the token and assigns it to
	* an account. This encapsulates the modification of balances such that the
	* proper events are emitted.
	* @param _account The account that will receive the created tokens.
	* @param _amount The amount that will be created.
	*/
	function _mint(address _account, uint256 _amount) internal {
		require(_account != 0);
		totalSupply_ = totalSupply_.add(_amount);
		balances_[_account] = balances_[_account].add(_amount);
		emit Transfer(address(0), _account, _amount);
	}
}


/**
* @title Pausable token
* @dev ERC20 modified with pausable transfers.
**/
contract ERC20Pausable is ERC20, Pausable {

	function transfer(
		address _to,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.transfer(_to, _value);
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}

	function approve(
		address _spender,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.approve(_spender, _value);
	}
}



contract BetMatchToken is ERC20Pausable {
	string public constant name = "DEVXBMx";
	string public constant symbol = "XBMx";
	uint8 public constant decimals = 18;

	uint256 public constant INITIAL_SUPPLY = 2000000000 * (10 ** uint256(decimals));

	constructor () public {
		totalSupply_ = INITIAL_SUPPLY;
		balances_[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}
}