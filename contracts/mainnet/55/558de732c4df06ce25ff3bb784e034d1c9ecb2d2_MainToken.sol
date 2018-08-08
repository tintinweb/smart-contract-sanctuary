pragma solidity 0.4.21;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
 
// zeppelin-solidity: 1.9.0

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
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

/**
    * @title Safe Approve
    * @dev  `msg.sender` approves `_spender` to spend `_amount` tokens on
    *  its behalf. This is a modified version of the ERC20 approve function
    *  to be a little bit safer
    */
contract SafeApprove is StandardBurnableToken {

   /**
    *  @param _spender The address of the account able to transfer the tokens
    *  @param _value The value of tokens to be approved for transfer
    *  @return True if the approval was successful
    **/
  function approve(address _spender, uint256 _value) public  returns (bool) {
    //  To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender,0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    return super.approve(_spender, _value);
  }
}

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

/**
 * @title AdvancedOwnable
 * @dev The AdvancedOwnable contract provides advanced authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract AdvancedOwnable is Ownable {

  address public saleAgent;
  address internal managerAgent;

  /**
   * @dev The AdvancedOwnable constructor sets saleAgent and managerAgent.
   * @dev Until the owner has been given a new address, the address will be assigned to the owner.
   */
  function AdvancedOwnable() public {
    saleAgent=owner;
    managerAgent=owner;
  }
  modifier onlyOwnerOrManagerAgent {
    require(owner == msg.sender || managerAgent == msg.sender);
    _;
  }
  modifier onlyOwnerOrSaleAgent {
    require(owner == msg.sender || saleAgent == msg.sender);
    _;
  }
  function setSaleAgent(address newSaleAgent) public onlyOwner {
    require(newSaleAgent != address(0));
    saleAgent = newSaleAgent;
  }
  function setManagerAgent(address newManagerAgent) public onlyOwner {
    require(newManagerAgent != address(0));
    managerAgent = newManagerAgent;
  }

}

/**
   * @title blacklist
   * @dev The blacklist contract has a blacklist of addresses, and provides basic authorization control functions.
   * @dev This simplifies the implementation of "user permissions".
   */
contract BlackList is AdvancedOwnable {

    mapping (address => bool) internal blacklist;
    event BlacklistedAddressAdded(address indexed _address);
    event BlacklistedAddressRemoved(address indexed _address);

   /**
    * @dev Modifier to make a function callable only when the address is not in black list.
    */
   modifier notInBlackList() {
     require(!blacklist[msg.sender]);
     _;
   }

   /**
    * @dev Modifier to make a function callable only when the address is not in black list.
    */
   modifier onlyIfNotInBlackList(address _address) {
     require(!blacklist[_address]);
     _;
   }
   /**
    * @dev Modifier to make a function callable only when the address is in black list.
    */
   modifier onlyIfInBlackList(address _address) {
     require(blacklist[_address]);
     _;
   }
 /**
   * @dev add an address to the blacklist
   * @param _address address
   * @return true if the address was added to the blacklist,
   * false if the address was already in the blacklist
   */
   function addAddressToBlacklist(address _address) public onlyOwnerOrManagerAgent onlyIfNotInBlackList(_address) returns(bool) {
     blacklist[_address] = true;
     emit BlacklistedAddressAdded(_address);
     return true;
   }
 /**
   * @dev remove addresses from the blacklist
   * @param _address address
   * @return true if  address was removed from the blacklist,
   * false if address weren&#39;t in the blacklist in the first place
   */
  function removeAddressFromBlacklist(address _address) public onlyOwnerOrManagerAgent onlyIfInBlackList(_address) returns(bool) {
    blacklist[_address] = false;
    emit BlacklistedAddressRemoved(_address);
    return true;
  }
}

/**
   * @title BlackList Token
   * @dev Throws if called by any account that&#39;s in blackList.
   */
contract BlackListToken is BlackList,SafeApprove {

  function transfer(address _to, uint256 _value) public notInBlackList returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public notInBlackList returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public notInBlackList returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public notInBlackList returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public notInBlackList returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function burn(uint256 _value) public notInBlackList {
   super.burn( _value);
  }

  function burnFrom(address _from, uint256 _value) public notInBlackList {
   super.burnFrom( _from, _value);
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is AdvancedOwnable {
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
   * @dev Modifier to make a function callable only for owner and saleAgent when the contract is paused.
   */
   modifier onlyWhenNotPaused() {
     if(owner != msg.sender && saleAgent != msg.sender) {
       require (!paused);
     }
    _;
   }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwnerOrSaleAgent whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwnerOrSaleAgent whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Pausable token
 * @dev BlackListToken modified with pausable transfers.
 **/
contract PausableToken is Pausable,BlackListToken {

  function transfer(address _to, uint256 _value) public onlyWhenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyWhenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public onlyWhenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public onlyWhenNotPaused returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public onlyWhenNotPaused returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function burn(uint256 _value) public onlyWhenNotPaused {
   super.burn( _value);
  }

  function burnFrom(address _from, uint256 _value) public onlyWhenNotPaused {
   super.burnFrom( _from, _value);
  }

}

/**
 * @title SafeCheckToken
 * @dev More secure functionality.
 */
contract SafeCheckToken is PausableToken {


    function transfer(address _to, uint256 _value) public returns (bool) {
      // Do not send tokens to this contract
      require(_to != address(this));
      // Check  Short Address
      require(msg.data.length >= 68);
      // Check Value is not zero
      require(_value != 0);

      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      // Do not send tokens to this contract
      require(_to != address(this));
      // Check  Short Address
      require(msg.data.length >= 68);
      // Check  Address from is not zero
      require(_from != address(0));
      // Check Value is not zero
      require(_value != 0);

      return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
      // Check  Short Address
      require(msg.data.length >= 68);
      return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
      // Check  Short Address
      require(msg.data.length >= 68);
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
      // Check  Short Address
      require(msg.data.length >= 68);
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function burn(uint256 _value) public {
      // Check Value is not zero
      require(_value != 0);
      super.burn( _value);
    }

    function burnFrom(address _from, uint256 _value) public {
      // Check  Short Address
      require(msg.data.length >= 68);
      // Check Value is not zero
      require(_value != 0);
      super.burnFrom( _from, _value);
    }

}

//Interface for accidentally send ERC20 tokens
interface accidentallyERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

/**
 * @title AccidentallyTokens
 * @dev Owner can transfer out any accidentally sent ERC20 tokens.
 */
contract AccidentallyTokens is Ownable {

    function transferAnyERC20Token(address tokenAddress,address _to, uint _value) public onlyOwner returns (bool) {
      require(_to != address(this));
      require(tokenAddress != address(0));
      require(_to != address(0));
      return accidentallyERC20(tokenAddress).transfer(_to,_value);
    }
}

/**
 * @title MainToken
 * @dev  ERC20 Token contract, where all tokens are send to the Token Wallet Holder.
 */
contract MainToken is SafeCheckToken,AccidentallyTokens {

  address public TokenWalletHolder;

  string public constant name = "EQI";
  string public constant symbol = "EQI Token";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 880000000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives TokenWalletHolder all of existing tokens.
   */
  function MainToken(address _TokenWalletHolder) public {
    require(_TokenWalletHolder != address(0));
    TokenWalletHolder = _TokenWalletHolder;
    totalSupply_ = INITIAL_SUPPLY;
    balances[TokenWalletHolder] = INITIAL_SUPPLY;
    emit Transfer(address(this), msg.sender, INITIAL_SUPPLY);
  }

  /**
   * @dev  Don&#39;t accept ETH.
   */
  function () public payable {
    revert();
  }

}