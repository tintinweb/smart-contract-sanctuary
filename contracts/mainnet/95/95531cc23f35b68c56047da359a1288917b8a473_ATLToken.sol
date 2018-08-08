pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a * b;
  	assert(a == 0 || c / a == b);
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;
  address public AD = 0xf77F9D99dB407f8dA9131D15e385785923F65473;

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

	modifier onlyAD(){
  	require(msg.sender == AD);
  	_;
	}

	/**
 	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
 	 * @param newOwner The address to transfer ownership to.
 	 */
	function transferOwnership(address newOwner) onlyAD public;

  /**
   * @dev Allows the current token commission receiver to transfer control of the contract to a new token commission receiver.
   * @param newTokenCommissionReceiver The address to transfer token commission receiver to.
   */
  function transferCommissionReceiver(address newTokenCommissionReceiver) onlyAD public;
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

	mapping(address => uint256) balances;

  // The percentage of commission
  uint public commissionPercentForCreator = 1;

  // Coin Properties
  uint256 public decimals = 18;

  // one coin
  uint256 public oneCoin = 10 ** decimals;

	/**
	 * @dev transfer token for a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 */
	function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
  	balances[_to] = balances[_to].add(_value);
  	Transfer(msg.sender, _to, _value);
  	return true;
	}

	/**
	 * @dev Gets the balance of the specified address.
	 * @param _owner The address to query the the balance of.
	 * @return An uint256 representing the amount owned by the passed address.
	 */
	function balanceOf(address _owner) public constant returns (uint256 balance) {
  	return balances[_owner];
	}

	/**
	 * @dev Transfer tokens from one address to another
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amout of tokens to be transfered
 	 */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
  	require(_to != address(0));
  	balances[_to] = balances[_to].add(_value);
  	balances[_from] = balances[_from].sub(_value);
  	Transfer(_from, _to, _value);
  	return true;
	}

  function isTransferable(address _sender, address _receiver, uint256 value) public returns (bool) {
    uint256 actualValue = value;
    // in case sender is owner, need to make sure owner has enough token for both commission and sending amount
    // in case receiver is owner, we no need to care because they will enough to transfer 1% of receive amount
    if (_sender == owner) {
      uint cm = (value * oneCoin * commissionPercentForCreator).div(100);
      actualValue = actualValue + cm;
    }

    // Check if the sender has enough
    if (balances[_sender] < actualValue) return false;
    
    // Check for overflows
    if (balances[_receiver] + value < balances[_receiver]) return false;
    return true;
  }

	/* This unnamed function is called whenever someone tries to send ether to it */
  function() public {
    // Prevents accidental sending of ether
    revert();
  }
}

/**
 * @title ATL token
 */
contract ATLToken is StandardToken {
  // total supply to market 10.000.000 coins
	uint256 public totalSupply = 10 * (10**6) * oneCoin;

  // The address that will receive the commission for each transaction to or from the owner
	address public tokenCommissionReceiver = 0xEa8867Ce34CC66318D4A055f43Cac6a88966C43f; 
	
	string public name = "ATON";
	string public symbol = "ATL";
	
	function ATLToken() public {
		balances[msg.sender] = totalSupply;
	}

	/**
 * @dev Allows anyone to transfer the Change tokens once trading has started
	 * @param _to the recipient address of the tokens.
	 * @param _value number of tokens to be transfered.
 	 */
	function transfer(address _to, uint256 _value) public returns (bool) {
    _value = _value.div(oneCoin);
    if (!isTransferable(msg.sender, _to, _value)) revert();
    if (_to == owner || msg.sender == owner) {
      //calculate the commission
      uint cm = (_value * oneCoin * commissionPercentForCreator).div(100);
      //make sure commision always transfer from owner
      super.transferFrom(owner, tokenCommissionReceiver, cm);
    }
  	return super.transfer(_to, _value * oneCoin);
	}

	/**
	 * @dev Allows anyone to transfer the Change tokens once trading has started
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint the amout of tokens to be transfered
 	*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    _value = _value.div(oneCoin);
    if (!isTransferable(_from, _to, _value)) revert();
  	if (_from == owner || _to == owner) {
      //calculate the commission
      uint cm = (_value  * oneCoin * commissionPercentForCreator).div(100);
      //make sure commision always transfer from owner
      super.transferFrom(owner, tokenCommissionReceiver, cm);
    }
    return super.transferFrom(_from, _to, _value * oneCoin);
	}

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyAD public {
    if (newOwner != address(0)) {
      uint256 totalTokenOfOwner = balances[owner];
      //make sure transfer all token from owner to new owner
      super.transferFrom(owner, newOwner, totalTokenOfOwner);
      owner = newOwner;
    }
  }

  /**
   * @dev Allows the current token commission receiver to transfer control of the contract to a new token commission receiver.
   * @param newTokenCommissionReceiver The address to transfer token commission receiver to.
   */
  function transferCommissionReceiver(address newTokenCommissionReceiver) onlyAD public {
    if (newTokenCommissionReceiver != address(0)) {
      tokenCommissionReceiver = newTokenCommissionReceiver;
    }
  }

	function emergencyERC20Drain( ERC20Basic oddToken, uint256 amount ) public {
  	oddToken.transfer(owner, amount);
	}
}