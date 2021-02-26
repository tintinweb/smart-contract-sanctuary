/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// File: contracts/Token.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Token {
  /// @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}

  /// @param owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address owner) public view returns (uint256 balance) {}

  /// @notice send `value` token to `to` from `msg.sender`
  /// @param to The address of the recipient
  /// @param value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address to, uint256 value) public returns (bool success) {}

  /// @notice send `value` token to `to` from `from` on the condition it is approved by `from`
  /// @param from The address of the sender
  /// @param to The address of the recipient
  /// @param value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address from, address to, uint256 value) public returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 value) public returns (bool success) {}

  /// @param owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address owner, address _spender) public view returns (uint256 remaining) {}

  /// @param amount The amount of token to be burned
  /// @return Whether the burn was successful or not
  function burn(uint256 amount) public returns (bool success) {}

  event Burn(uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed _spender, uint256 value);
}

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath mul error");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

library Math {
  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

// File: contracts/StandardToken.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;



contract StandardToken is Token {
  using SafeMath for uint256;
  using Math for uint256;

  uint256 _totalSupply;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256 supply) {
    return _totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    //Default assumes totalSupply can't be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
    //Replace the if with this one instead.
    //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[_to] = balances[_to].add(_value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    return false;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    //same as above. Replace this line with the following if you want to protect against wrapping uints.
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[_from] >= _value && _value > 0 && allowed[_from][msg.sender] >= _value) {
      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      return true;
    }

    return false;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function burn(uint256 _amount) public returns (bool success) {
    require(msg.sender == address(0), "ERC20: only zero address can burn");
    require(balances[msg.sender] > _amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    emit Burn(_amount);
    return true;
  }
}

// File: contracts/TIC_TOKEN.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


contract TicToken is StandardToken {
  /*
  NOTE:
  The following variables are OPTIONAL vanities. One does not have to include them.
  They allow one to customise the token contract & in no way influences the core functionality.
  Some wallets/interfaces might not even bother to look at this information.
  */
  string public name;                   //fancy name: eg Simon Bucks
  uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
  string public symbol;                 //An identifier: eg SBX
  string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.

  //
  // CHANGE THESE VALUES FOR YOUR TOKEN
  //

  //make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of FashionToken

  constructor() public {
    balances[msg.sender] = 1000000000000000000000000000; // Give the creator all initial tokens (100000 for example)
    _totalSupply = 1000000000000000000000000000;          // Update total supply (100000 for example)
    name = "TIC Finance";             // Set the name for display purposes
    decimals = 18;                                 // Amount of decimals for display purposes
    symbol = "TIC";                               // Set the symbol for display purposes
  }
}