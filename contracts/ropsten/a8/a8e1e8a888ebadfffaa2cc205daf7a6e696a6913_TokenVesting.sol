pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address _who) public view returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;


	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);


	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor() public {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Allows the current owner to relinquish control of the contract.
	 * @notice Renouncing to ownership will leave the contract without an owner.
	 * It will not be possible to call the functions with the `onlyOwner`
	 * modifier anymore.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address _newOwner) public onlyOwner {
		_transferOwnership(_newOwner);
	}

	/**
	 * @dev Transfers control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function _transferOwnership(address _newOwner) internal {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}








/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address _owner, address _spender)
	public view returns (uint256);

	function transferFrom(address _from, address _to, uint256 _value)
	public returns (bool);

	function approve(address _spender, uint256 _value) public returns (bool);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
	function safeTransfer(
		ERC20Basic _token,
		address _to,
		uint256 _value
	)
	internal
	{
		require(_token.transfer(_to, _value));
	}

	function safeTransferFrom(
		ERC20 _token,
		address _from,
		address _to,
		uint256 _value
	)
	internal
	{
		require(_token.transferFrom(_from, _to, _value));
	}

	function safeApprove(
		ERC20 _token,
		address _spender,
		uint256 _value
	)
	internal
	{
		require(_token.approve(_spender, _value));
	}
}
/* solium-disable security/no-block-members */








/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (_a == 0) {
			return 0;
		}

		c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		// assert(_b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = _a / _b;
		// assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
		return _a / _b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_b <= _a);
		return _a - _b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		c = _a + _b;
		assert(c >= _a);
		return c;
	}
}



/**
* @title TokenVesting
* @dev A token holder contract that can release its token balance gradually like a
* typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
* owner.
*/
contract TokenVesting is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	event Released(uint256 amount);
	event Revoked();

	ERC20 public token;
	address public beneficiary;
	uint256 public total;
	uint256 public cliff;
	uint256 public start;
	uint256 public step;
	uint256 public step_amount;
	uint256 public duration;
	bool public revocable;

	mapping (address => uint256) public released;
	mapping (address => bool) public revoked;

	/**
	* @dev Creates a vesting contract that vests its balance of any ERC20 token to the
	* _beneficiary, gradually in a linear fashion until _start + _duration. By then all
	* of the balance will have vested.
	* @param _beneficiary address of user to receive funds
	* @param _token contract address of the ERC20 token
	* @param _vest_amount total amount of tokens to hold in the vesting contract
	* @param _start unix timestamp when vesting should begin
	* @param _cliff amount of steps in which tokens will begin to vest (cliff * steps)
	* @param _step duration in seconds of each step after the cliff to release tokens
	* @param _step_amount amount of tokens to release for after each step
	* @param _duration duration in seconds of the period in which the tokens will vest
	* @param _revocable whether the vesting is revocable or not
	*/
	constructor(
		address _beneficiary,
		address _token,
		uint256 _vest_amount,
		uint256 _start,
		uint256 _cliff,
		uint256 _step,
		uint256 _step_amount,
		uint256 _duration,
		bool _revocable
	)
	public
	{
		require(_beneficiary != address(0));
		require(_token != address(0));
		require(_vest_amount > 0);
		require(_cliff <= _duration);
		require(_step > 0);
		token = ERC20(_token);
		require(token.balanceOf(msg.sender) >= _vest_amount);

		beneficiary = _beneficiary;
		total = _vest_amount;
		revocable = _revocable;
		duration = _duration;
		step = _step;
		step_amount = _step_amount;
		cliff = _cliff.mul(step);
		start = _start;
	}

	/**
	* @notice Transfers available vested tokens to sender
	*/
	function release() public {
		require(!revoked[beneficiary]);
		uint256 available = tokensAvailable();
		require(available > 0);

		released[beneficiary] = released[beneficiary].add(available);

		token.safeTransfer(beneficiary, available);

		emit Released(available);
	}

	/**
	* @notice Allows the owner to revoke the vesting. Tokens already vested
	* remain in the contract, the rest are returned to the owner.
	*/
	function revoke() public onlyOwner {
		require(revocable);
		require(!revoked[beneficiary]);

		uint256 refund = total.sub(released[beneficiary]);

		revoked[beneficiary] = true;

		token.safeTransfer(owner, refund);

		emit Revoked();
	}

	/**
	 * @dev Calculates cliffs end timestamp
	 */
	function endCliff() public view returns (uint256) {
		return start.add(cliff);
	}

	/**
	 * @dev Calculates the step based on unix timestamp
	 */
	function timeToStep() public view returns (uint256) {
		uint256 remainder = block.timestamp.sub(endCliff());
		if (remainder <= 0) {
			return 0;
		} else {
			return remainder.div(step);
		}
	}

	/**
	 * @dev Returns current token balance in contract
	 */
	function balance() public view returns (uint256) {
		return token.balanceOf(this);
	}

	/**
	 * @dev Calculates the amount of tokens available for withdrawal based on today
	 */
	function tokensAvailable() public view returns (uint256) {
		if (block.timestamp <= endCliff()) {
			return 0;
		} else if (block.timestamp >= duration) {
			return total.sub(released[beneficiary]);
		} else {
			return timeToStep().mul(step_amount).sub(released[beneficiary]);
		}
	}

}