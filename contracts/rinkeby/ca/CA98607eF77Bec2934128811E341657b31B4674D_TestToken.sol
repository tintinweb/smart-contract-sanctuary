/*
  This ERC20 compliant contract should not be used as an actual
  cryptocurrency, and should only be used strictly in a development
  and testing environment. Public use of this contract as a store of
  value is not recommended."
*/

pragma solidity ^0.5.0;

import "./math/SafeMath.sol";
import "./token/IERC20.sol";

/// @title ERC20 Token Implementation for testing purposes
contract TestToken is IERC20 {
  using SafeMath for uint256;


  //
  // Token Parameters
  //
  string public name = "TestToken";
  string public symbol = "TEST";
  uint8 public decimals = 0;


  //
  // Members
  //
  uint256 private total_balance = 0;
  address private contract_owner;


  //
  // Collections
  //
  mapping (address => uint256) private token_balance_mapping;
  mapping (address => mapping (address => uint256)) private token_allowance_mapping;


  //
  // Constructor
  //
  constructor(address _contract_owner) public {
    contract_owner = _contract_owner;
  }


  //
  // ERC20 Implmentation
  //


  function totalSupply() external view returns (uint256) {
    return total_balance;
  }


  function balanceOf(address _owner) external view returns (uint256) {
    return token_balance_mapping[_owner];
  }


  function allowance(address owner, address spender)
    external view returns (uint256) {
    return token_allowance_mapping[owner][spender];
  }


  function transfer(address to, uint256 value) external returns (bool) {
    if (token_balance_mapping[msg.sender] < value || to == address(0)) {
      return false;
    }
  
    token_balance_mapping[msg.sender] = token_balance_mapping[msg.sender].sub(value);
    token_balance_mapping[to] = token_balance_mapping[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }


  function approve(address spender, uint256 value)
    external returns (bool) {
    if (spender == address(0)) {
      return false;
    }

    token_allowance_mapping[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }


  function transferFrom(address from, address to, uint256 value)
    external returns (bool) {
    if (token_allowance_mapping[from][to] < value ||
        token_balance_mapping[from] < value ||
        to == address(0)) {
      return false;
    }
  
    token_allowance_mapping[from][to] = token_allowance_mapping[from][to].sub(value);
    token_balance_mapping[from] = token_balance_mapping[from].sub(value);
    token_balance_mapping[to] = token_balance_mapping[to].add(value);
  
    return true;
  }


  //
  // Methods
  //
    
  function mint(address to, uint256 value)
    external returns(bool) {
    if (to == address(0)) {
      return false;
    }
  
    total_balance = total_balance.add(value);
    token_balance_mapping[to] = token_balance_mapping[to].add(value);

    return true;
  }
}

pragma solidity ^0.5.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from,
                 address indexed to,
                 uint256 value);

  event Approval(address indexed owner,
                 address indexed spender,
                 uint256 value);
}

