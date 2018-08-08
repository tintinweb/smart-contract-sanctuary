pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
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
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
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
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract StarTokenInterface is MintableToken {
    // Cheatsheet of inherit methods and events
    // function transferOwnership(address newOwner);
    // function allowance(address owner, address spender) constant returns (uint256);
    // function transfer(address _to, uint256 _value) returns (bool);
    // function transferFrom(address from, address to, uint256 value) returns (bool);
    // function approve(address spender, uint256 value) returns (bool);
    // function increaseApproval (address _spender, uint _addedValue) returns (bool success);
    // function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success);
    // function finishMinting() returns (bool);
    // function mint(address _to, uint256 _amount) returns (bool);
    // event Approval(address indexed owner, address indexed spender, uint256 value);
    // event Mint(address indexed to, uint256 amount);
    // event MintFinished();

    // Custom methods and events
    function toggleTransfer() returns (bool);
    function toggleTransferFor(address _for) returns (bool);
    event ToggleTransferAllowance(bool state);
    event ToggleTransferAllowanceFor(address indexed who, bool state);


}

contract AceToken is StarTokenInterface {
    using SafeMath for uint;
    using SafeMath for uint256;
    
    // ERC20 constants
    string public constant name = "ACE Token";
    string public constant symbol = "ACE";
    uint public constant decimals = 0;

    // Minting constants
    uint256 public constant MAXSOLD_SUPPLY = 99000000;
    uint256 public constant HARDCAPPED_SUPPLY = 165000000;
    
    bool public transferAllowed = false;
    mapping (address=>bool) public specialAllowed;

    event ToggleTransferAllowance(bool state);
    event ToggleTransferAllowanceFor(address indexed who, bool state);

    modifier allowTransfer() {
        require(transferAllowed || specialAllowed[msg.sender]);
        _;
    }

    /**
    * @dev transfer token for a specified address if transfer is open
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) allowTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    
    /**
    * @dev Transfer tokens from one address to another if transfer is open
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) allowTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Change current state of transfer allowence to opposite
     */
    function toggleTransfer() onlyOwner returns (bool) {
        transferAllowed = !transferAllowed;
        ToggleTransferAllowance(transferAllowed);
        return transferAllowed;
    }

    /**
    * @dev allow transfer for the given address against global rules
    * @param _for addres The address of special allowed transfer (required for smart contracts)
     */
    function toggleTransferFor(address _for) onlyOwner returns (bool) {
        specialAllowed[_for] = !specialAllowed[_for];
        ToggleTransferAllowanceFor(_for, specialAllowed[_for]);
        return specialAllowed[_for];
    }

    /**
    * @dev Function to mint tokens for investor
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to emit.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        require(_amount > 0);
        
        // create 2 extra token for each 3 sold
        uint256 extra = _amount.div(3).mul(2);
        uint256 total = _amount.add(extra);

        totalSupply = totalSupply.add(total);

        // Prevent to emit more than handcap!
        assert(totalSupply <= HARDCAPPED_SUPPLY);
    
        balances[_to] = balances[_to].add(_amount);
        balances[owner] = balances[owner].add(extra);

        Mint(_to, _amount);
        Mint(owner, extra);

        Transfer(0x0, _to, _amount);
        Transfer(0x0, owner, extra);

        return true;
    }

    function increaseApproval (address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}