/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-03-30
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/GroupLockup.sol

pragma solidity ^0.4.18;



contract GroupLockup is Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) public lockup_list; //users lockup list
	mapping(uint256 => bool) public lockup_list_flag;
	address[] public user_list; //users address list

	event UpdateLockupList(address indexed owner, address indexed user_address, uint256 lockup_date);
	event UpdateLockupTime(address indexed owner, uint256 indexed old_lockup_date, uint256 new_lockup_date);
	event LockupTimeList(uint256 indexed lockup_date, bool active);

	/**
	* @dev Function to get lockup list
	* @param user_address address 
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getLockupTime(address user_address)public view returns (uint256){
		return lockup_list[user_address];
	}

	/**
	* @dev Function to check token locked date that is reach or not
	* @param lockup_date uint256 
	* @return A bool that indicates if the operation was successful.
	*/
	function isLockup(uint256 lockup_date) public view returns(bool){
		return (now < lockup_date);
	}

	/**
	* @dev Function get user's lockup status
	* @param user_address address
	* @return A bool that indicates if the operation was successful.
	*/
	function inLockupList(address user_address)public view returns(bool){
		if(lockup_list[user_address] == 0){
			return false;
		}
		return true;
	}

	/**
	* @dev Function update lockup status for purchaser, if user in the lockup list, they can only transfer token after lockup date
	* @param user_address address
	* @param lockup_date uint256 this user's token time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address user_address, uint256 lockup_date)onlyOwner public returns(bool){
		if(lockup_date == 0){
			delete lockup_list[user_address];

			for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
				if(user_list[user_list_index] == user_address){
					delete user_list[user_list_index];
					break;
				}
			}
		}else{
			bool user_is_exist = inLockupList(user_address);

			if(!user_is_exist){
				user_list.push(user_address);
			}

			lockup_list[user_address] = lockup_date;

			//insert lockup time into lockup time list, if this lockup time is the new one
			if(!lockup_list_flag[lockup_date]){
				lockup_list_flag[lockup_date] = true;
				emit LockupTimeList(lockup_date, true);
			}
			
		}
		emit UpdateLockupList(msg.sender, user_address, lockup_date);

		return true;
	}

	/**
	* @dev Function update lockup time
	* @param old_lockup_date uint256 old group lockup time
	* @param new_lockup_date uint256 new group lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupTime(uint256 old_lockup_date, uint256 new_lockup_date)onlyOwner public returns(bool){
		require(old_lockup_date != 0);
		require(new_lockup_date != 0);
		require(new_lockup_date != old_lockup_date);

		address user_address;
		uint256 user_lockup_time;

		//update the user's lockup time who was be setted as old lockup time
		for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
			if(user_list[user_list_index] != 0){
				user_address = user_list[user_list_index];
				user_lockup_time = getLockupTime(user_address);
				if(user_lockup_time == old_lockup_date){
					lockup_list[user_address] = new_lockup_date;
					emit UpdateLockupList(msg.sender, user_address, new_lockup_date);
				}
			}
		}

		//delete the old lockup time from lockup time list, if this old lockup time is existing in the lockup time list
		if(lockup_list_flag[old_lockup_date]){
			lockup_list_flag[old_lockup_date] = false;
			emit LockupTimeList(old_lockup_date, false);
		}

		//insert lockup time into lockup time list, if this lockup time is the new one
		if(!lockup_list_flag[new_lockup_date]){
			lockup_list_flag[new_lockup_date] = true;
			emit LockupTimeList(new_lockup_date, true);
		}

		emit UpdateLockupTime(msg.sender, old_lockup_date, new_lockup_date);
		return true;
	}
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

pragma solidity ^0.4.21;




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.21;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.21;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

pragma solidity ^0.4.21;




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

// File: contracts/ERC223/ERC223Token.sol

pragma solidity ^0.4.18;


contract ERC223Token is MintableToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}

// File: contracts/ERC223/ERC223ContractInterface.sol

pragma solidity ^0.4.18;

contract ERC223ContractInterface{
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}

// File: contracts/DEAPCoin.sol

pragma solidity ^0.4.18;





contract DEAPCoin is ERC223Token{
	using SafeMath for uint256;

	string public constant name = 'DEAPCOIN';
	string public constant symbol = 'DEP';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 30000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_SALE_SUPPLY = 12000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_UNSALE_SUPPLY = INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

	address public owner_wallet;
	address public unsale_owner_wallet;

	GroupLockup public group_lockup;

	event BatchTransferFail(address indexed from, address indexed to, uint256 value, string msg);

	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	constructor(address _sale_owner_wallet, address _unsale_owner_wallet, GroupLockup _group_lockup) public {
		group_lockup = _group_lockup;
		owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;

		mint(owner_wallet, INITIAL_SALE_SUPPLY);
		mint(unsale_owner_wallet, INITIAL_UNSALE_SUPPLY);

		finishMinting();
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function sendTokens(address _to, uint256 _value) onlyOwner public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[owner_wallet]);

		bytes memory empty;
		
		// SafeMath.sub will throw if there is not enough balance.
		balances[owner_wallet] = balances[owner_wallet].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(owner_wallet, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bytes memory empty;

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	* @param _data The data info.
	*/
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, _data);
	    }

	    emit Transfer(msg.sender, _to, _value);
		emit TransferERC223(msg.sender, _to, _value, _data);
		return true;
	}	


	/**
	* @dev transfer token to mulitipule user
	* @param _from which wallet's token will be taken.
	* @param _users The address list to transfer to.
	* @param _values The amount list to be transferred.
	*/
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner public returns (bool) {

		address to;
		uint256 value;
		bool isUserAddress;
		bool canTransfer;
		string memory transferFailMsg;

		for(uint i = 0; i < _users.length; i++) {

			to = _users[i];
			value = _values[i];
			isUserAddress = false;
			canTransfer = false;
			transferFailMsg = "";

			// can not send token to contract address
		    //コントラクトアドレスにトークンを発送できない検証
		    assembly {
		      isUserAddress := iszero(extcodesize(to))
		    }

		    //data check
			if(!isUserAddress){
				transferFailMsg = "try to send token to contract";
			}else if(value <= 0){
				transferFailMsg = "try to send wrong token amount";
			}else if(to == address(0)){
				transferFailMsg = "try to send token to empty address";
			}else if(value > balances[_from]){
				transferFailMsg = "token amount is larger than giver holding";
			}else{
				canTransfer = true;
			}

			if(canTransfer){
			    balances[_from] = balances[_from].sub(value);
			    balances[to] = balances[to].add(value);
			    emit Transfer(_from, to, value);
			}else{
				emit BatchTransferFail(_from, to, value, transferFailMsg);
			}

        }

        return true;
	}
}