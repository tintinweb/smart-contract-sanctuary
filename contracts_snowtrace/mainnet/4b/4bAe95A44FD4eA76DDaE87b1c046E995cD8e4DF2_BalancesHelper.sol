// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../token/ERC20Token.sol";
import "../libs/SafeMathLib.sol";


/**
 * @title Balances helper
 *
 * @author Jegor Sidorenko <[email protected]>
 * @author Stanisław Głogowski <[email protected]>
 */
contract BalancesHelper {
  using SafeMathLib for uint256;

  // external functions

  /**
   * @notice Checks the token balances of accounts for multiple tokens.
   * @dev Pass 0x0 as a "token" address to get ETH balance.
   *
   * Possible error throws:
   * - extremely large arrays for account and or tokens (gas cost too high)
   *
   * @param accounts array of accounts addresses
   * @param tokens array of tokens addresses
   * @return a one-dimensional that's user.length * tokens.length long. The
   * array is ordered by all of the 0th accounts token balances, then the 1th
   * user, and so on.
   */
  function getBalances(
    address[] calldata accounts,
    address[] calldata tokens
  )
    external
    view
    returns (uint[] memory)
  {
    uint[] memory result = new uint[](accounts.length.mul(tokens.length));

    for (uint i = 0; i < accounts.length; i++) {
      for (uint j = 0; j < tokens.length; j++) {
        uint index = j.add(tokens.length.mul(i));

        if (tokens[j] != address(0x0)) {
          result[index] = _getBalance(accounts[i], tokens[j]);
        } else {
          result[index] = accounts[i].balance;
        }
      }
    }

    return result;
  }

  // private functions

  function _getBalance(
    address account,
    address token
  )
    private
    view
    returns (uint256)
  {
    uint256 result = 0;
    uint256 tokenCode;

    /// @dev check if token is actually a contract
    // solhint-disable-next-line no-inline-assembly
    assembly { tokenCode := extcodesize(token) } // contract code size

    if (tokenCode > 0) {
      /// @dev is it a contract and does it implement balanceOf
      // solhint-disable-next-line avoid-low-level-calls
      (bool methodExists,) = token.staticcall(abi.encodeWithSelector(
        ERC20Token(token).balanceOf.selector,
        account
      ));

      if (methodExists) {
        result = ERC20Token(token).balanceOf(account);
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Safe math library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol
 */
library SafeMathLib {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;

    require(c >= a, "SafeMathLib: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMathLib: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);

    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;

    require(c / a == b, "SafeMathLib: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMathLib: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);

    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMathLib: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);

    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/SafeMathLib.sol";


/**
 * @title ERC20 token
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol
 */
contract ERC20Token {
  using SafeMathLib for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowances;

  // events

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

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // external functions

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (bool)
  {
    _transfer(_getSender(), to, value);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    address sender = _getSender();

    _transfer(from, to, value);
    _approve(from, sender, allowances[from][sender].sub(value));

    return true;
  }

  function approve(
    address spender,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    _approve(_getSender(), spender, value);

    return true;
  }

  // external functions (views)

  function balanceOf(
    address owner
  )
    virtual
    external
    view
    returns (uint256)
  {
    return balances[owner];
  }

  function allowance(
    address owner,
    address spender
  )
    virtual
    external
    view
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  // internal functions

  function _transfer(
    address from,
    address to,
    uint256 value
  )
    virtual
    internal
  {
    require(
      from != address(0),
      "ERC20Token: cannot transfer from 0x0 address"
    );
    require(
      to != address(0),
      "ERC20Token: cannot transfer to 0x0 address"
    );

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(from, to, value);
  }

  function _approve(
    address owner,
    address spender,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot approve from 0x0 address"
    );
    require(
      spender != address(0),
      "ERC20Token: cannot approve to 0x0 address"
    );

    allowances[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function _mint(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot mint to 0x0 address"
    );
    require(
      value > 0,
      "ERC20Token: cannot mint 0 value"
    );

    balances[owner] = balances[owner].add(value);
    totalSupply = totalSupply.add(value);

    emit Transfer(address(0), owner, value);
  }

  function _burn(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot burn from 0x0 address"
    );

    balances[owner] = balances[owner].sub(
      value,
      "ERC20Token: burn value exceeds balance"
    );

    totalSupply = totalSupply.sub(value);

    emit Transfer(owner, address(0), value);
  }

  // internal functions (views)

  function _getSender()
    virtual
    internal
    view
    returns (address)
  {
    return msg.sender;
  }
}