pragma solidity ^0.4.21;


/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title MultiOwnable
 * @dev The MultiOwnable contract has multiple owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract MultiOwnable {
	
	address[] public owners;
	mapping(address => bool) public isOwner;
	
	event OwnerAddition(address indexed owner);
	event OwnerRemoval(address indexed owner);
	
	/**
	 * @dev The MultiOwnable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function MultiOwnable() public {
		isOwner[msg.sender] = true;
		owners.push(msg.sender);
	}
	
	/**
   * @dev Throws if called by any account other than the owner.
   */
	modifier onlyOwner() {
		require(isOwner[msg.sender]);
		_;
	}
	
	/**
	 * @dev Throws if called by an owner.
	 */
	modifier ownerDoesNotExist(address _owner) {
		require(!isOwner[_owner]);
		_;
	}
	
	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier ownerExists(address _owner) {
		require(isOwner[_owner]);
		_;
	}
	
	/**
	 * @dev Throws if called with a null address.
	 */
	modifier notNull(address _address) {
		require(_address != 0);
		_;
	}
	
	/**
	 * @dev Allows to add a new owner. Transaction has to be sent by an owner.
	 * @param _owner Address of new owner.
	 */
	function addOwner(address _owner)
	public
	onlyOwner
	ownerDoesNotExist(_owner)
	notNull(_owner)
	{
		isOwner[_owner] = true;
		owners.push(_owner);
		emit OwnerAddition(_owner);
	}
	
	/**
	 * @dev Allows to remove an owner. Transaction has to be sent by wallet.
	 * @param _owner Address of owner.
	 */
	function removeOwner(address _owner)
	public
	onlyOwner
	ownerExists(_owner)
	{
		isOwner[_owner] = false;
		for (uint i = 0; i < owners.length - 1; i++)
			if (owners[i] == _owner) {
				owners[i] = owners[owners.length - 1];
				break;
			}
		owners.length -= 1;
		emit OwnerRemoval(_owner);
	}
	
}

contract DestroyableMultiOwner is MultiOwnable {
	/**
	 * @notice Allows to destroy the contract and return the tokens to the owner.
	 */
	function destroy() public onlyOwner {
		selfdestruct(owners[0]);
	}
}

interface Token {
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract BrokerImp is MultiOwnable, DestroyableMultiOwner {
	using SafeMath for uint256;
	
	Token public token;
	uint256 public commission;
	address public broker;
	address public pool;
	
	event CommissionChanged(uint256 _previousCommission, uint256 _commision);
	event BrokerChanged(address _previousBroker, address _broker);
	event PoolChanged(address _previousPool, address _pool);
	
	/**
	 * @dev Constructor.
	 * @param _token The token address
	 * @param _pool The pool of tokens address
	 * @param _commission The percentage of the commission 0-100
	 * @param _broker The broker address
	 */
	function BrokerImp(address _token, address _pool, uint256 _commission, address _broker) public {
		require(_token != address(0));
		token = Token(_token);
		pool = _pool;
		commission = _commission;
		broker = _broker;
	}
	
	/**
	 * @dev Allows the owner make a reward.
	 * @param _beneficiary the beneficiary address
	 * @param _value the tokens reward in wei
	 */
	function reward(address _beneficiary, uint256 _value) public onlyOwner returns (bool) {
		uint256 hundred = uint256(100);
		uint256 beneficiaryPart = hundred.sub(commission);
		uint256 total = (_value.div(beneficiaryPart)).mul(hundred);
		uint256 brokerCommission = total.sub(_value);
		return (
		token.transferFrom(pool, _beneficiary, _value) &&
		token.transferFrom(pool, broker, brokerCommission)
		);
	}
	
	/**
	 * @dev Allows the owner to withdraw the balance of the tokens.
	 * @param _commission The percentage of the commission 0-100
	 */
	function changeCommission(uint256 _commission) public onlyOwner {
		emit CommissionChanged(commission, _commission);
		commission = _commission;
	}
	
	/**
	 * @dev Allows the owner to change the broker.
	 * @param _broker The broker address
	 */
	function changeBroker(address _broker) public onlyOwner {
		emit BrokerChanged(broker, _broker);
		broker = _broker;
	}
	
	/**
	 * @dev Allows the owner to change the pool of tokens.
	 * @param _pool The pool address
	 */
	function changePool(address _pool) public onlyOwner {
		emit PoolChanged(pool, _pool);
		pool = _pool;
	}
}