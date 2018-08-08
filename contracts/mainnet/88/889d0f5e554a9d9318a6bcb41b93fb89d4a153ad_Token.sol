/*! zam.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */


pragma solidity 0.4.24;
	

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
	event Pause();
	event Unpause();

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
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}

	/**
	 * @dev called by the owner to unpause, returns to normal state
	 */
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender)
		public view returns (uint256);

	function transferFrom(address from, address to, uint256 value)
		public returns (bool);

	function approve(address spender, uint256 value) public returns (bool);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}


/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev Transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;


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
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
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
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
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
		return allowed[_owner][_spender];
	}

	/**
	 * @dev Increase the amount of tokens that an owner allowed to a spender.
	 * approve should be called when allowed[_spender] == 0. To increment
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _addedValue The amount of tokens to increase the allowance by.
	 */
	function increaseApproval(
		address _spender,
		uint256 _addedValue
	)
		public
		returns (bool)
	{
		allowed[msg.sender][_spender] = (
			allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	 * @dev Decrease the amount of tokens that an owner allowed to a spender.
	 * approve should be called when allowed[_spender] == 0. To decrement
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _subtractedValue The amount of tokens to decrease the allowance by.
	 */
	function decreaseApproval(
		address _spender,
		uint256 _subtractedValue
	)
		public
		returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	bool public mintingFinished = false;


	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	modifier hasMintPermission() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Function to mint tokens
	 * @param _to The address that will receive the minted tokens.
	 * @param _amount The amount of tokens to mint.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function mint(
		address _to,
		uint256 _amount
	)
		hasMintPermission
		canMint
		public
		returns (bool)
	{
		totalSupply_ = totalSupply_.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
	}

	/**
	 * @dev Function to stop minting new tokens.
	 * @return True if the operation was successful.
	 */
	function finishMinting() onlyOwner canMint public returns (bool) {
		mintingFinished = true;
		emit MintFinished();
		return true;
	}
}


/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

	uint256 public cap;

	constructor(uint256 _cap) public {
		require(_cap > 0);
		cap = _cap;
	}

	/**
	 * @dev Function to mint tokens
	 * @param _to The address that will receive the minted tokens.
	 * @param _amount The amount of tokens to mint.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function mint(
		address _to,
		uint256 _amount
	)
		public
		returns (bool)
	{
		require(totalSupply_.add(_amount) <= cap);

		return super.mint(_to, _amount);
	}

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

	event Burn(address indexed burner, uint256 value);

	/**
	 * @dev Burns a specific amount of tokens.
	 * @param _value The amount of token to be burned.
	 */
	function burn(uint256 _value) public {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		// no need to require value <= totalSupply, since that would imply the
		// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}
}


/**
 * @title Contract of managers&#39; control

 */
contract Manageable is Ownable {
    address[] public managers;

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager() { require(isManager(msg.sender)); _; }

	/**
	 * @dev Get the number of managers
	 * @return The number of added managers
	 */
    function countManagers() view public returns(uint) {
        return managers.length;
    }

	/**
	 * @dev Get list of managers
	 * @return List of added managers
	 */
    function getManagers() view public returns(address[]) {
        return managers;
    }

	/**
	 * @dev Check whether the address is in the list of managers
	 * @param _manager Manager&#39;s address
	 * @return logical type is whether the address in the list
)
	 */
    function isManager(address _manager) view public returns(bool) {
        for(uint i = 0; i < managers.length; i++) {
            if(managers[i] == _manager) {
                return true;
            }
        }
        return false;
    }

	/**
	 * @dev Adding a manager
	 * @param _manager The address of the manager to be added 
	 */
    function addManager(address _manager) onlyOwner public {
        require(_manager != address(0));
        require(!isManager(_manager));

        managers.push(_manager);

        emit ManagerAdded(_manager);
    }

	/**
	 * @dev Remove manager
	 * @param _manager Address of the manager to be removed
	 */
    function removeManager(address _manager) onlyOwner public {
        require(isManager(_manager));

        uint index = 0;
        for(uint i = 0; i < managers.length; i++) {
            if(managers[i] == _manager) {
                index = i;
            }
        }

        for(; index < managers.length - 1; index++) {
            managers[index] = managers[index + 1];
        }
        
        managers.length--;
        emit ManagerRemoved(_manager);
    }
}


/**
 * @title Contract of ZAM token
 */
contract Token is DetailedERC20, CappedToken, BurnableToken {
	/**
	 * @dev Token constructor
	 */
    constructor() CappedToken(85e16) DetailedERC20("zamzam", "ZAM", 8) public {
        
    }

	/**
	 * @dev Multi-transaction of tokens
	 * @param _to Addresses array
	 * @param _value Array of token amount for each address
	 * @return Boolean type of transaction success
	 */
    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        require(_to.length == _value.length);

        for(uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _value[i]);
        }

        return true;
    }
}


/**
 * @title Crowdsale contract of ZAM token
 */
contract Crowdsale is Manageable, Pausable {
    using SafeMath for uint;

    Token public token;
    bool public crowdsaleClosed = false;

    event ExternalPurchase(address indexed holder, string tx, string currency, uint256 currencyAmount, uint256 rateToEther, uint256 tokenAmount);
    event CrowdsaleClose();
   
	/**
	 * @dev Crowdsale contract constructor
	 */
    constructor() public {
        token = new Token();
    }

	/**
	 * @dev External purchase (managers only)
	 * @param _to The address for tokens accruing
	 * @param _tx Hash of the transaction in the blockchain in which tokens payment was made
	 * @param _currency The currency (blockchain) in which the payment was made
	 * @param _value Amount of payment in the currency
	 * @param _rate Exchange rate in USD
	 * @param _tokens Number of accrual tokens
	 */
    function externalPurchase(address _to, string _tx, string _currency, uint _value, uint256 _rate, uint256 _tokens) whenNotPaused onlyManager public {
        token.mint(_to, _tokens);
        emit ExternalPurchase(_to, _tx, _currency, _value, _rate, _tokens);
    }

	/**
	 * @dev Closing the crowdsale contract and transferring the rights of the token contract to the specified address
	 * @param _to Address for transfer of the rights
	 */
    function closeCrowdsale(address _to) onlyOwner public {
        require(!crowdsaleClosed);

        token.transferOwnership(_to);
        crowdsaleClosed = true;

        emit CrowdsaleClose();
    }
}