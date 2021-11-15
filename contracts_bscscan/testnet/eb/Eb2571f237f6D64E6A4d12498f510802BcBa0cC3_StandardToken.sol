// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './contexts/OwnableContext.sol';
import './interfaces/ICarrier.sol';
import './libraries/SafeMath.sol';

contract StandardToken is OwnableContext {

    using SafeMath for uint256;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;


    constructor (string memory tokenName, string memory tokenSymbol, uint256 initialTrueSupply, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        

        _mint(_msgSender(), initialTrueSupply * (10**_decimals));
    }


    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function getOwner() external view returns (address) {
        return _owner;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipiant, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipiant, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipiant, uint256 amount) external returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer from: cannot transfer more than allowance"));
        _transfer(sender, recipiant, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 allowanceIncrease) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(allowanceIncrease));
        return true;
    }

    function decreaseAllowance(address spender, uint256 allowanceDecrease) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(allowanceDecrease, "Decrease allowance: cannot decrease allowance below zero"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer: cannot transfer to the 0 address");

        _balances[from] = _balances[from].sub(amount, "Transfer: amount exceeds senser's balance");
        _balances[to] = _balances[to].add(amount);
        
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve: cannot approve transfer from 0 address.");
        require(spender != address(0), "Approve: cannot approve transfer to 0 address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint: cannot mint to the 0 address");

        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), address(this), amount);

        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(this), to, amount);
    }


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract CallableContext {

    function _context() internal view returns (address) {
        return address(this);
    }
    

    function _msgSender() internal view returns (address) {
        return address(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }

    function _msgTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './CallableContext.sol';

contract OwnableContext is CallableContext {

    address internal _owner;


    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }


    modifier onlyOwner() {
        require(_msgSender() == _owner, "Only Owner: caller is not context owner");
        _;
    }


    event OwnershipTransferred(address previousOwner, address newOwner);


    function owner() external view returns (address) {
        return _owner;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != _owner, "Transfer Ownership: new owner is already owner");
        require(newOwner != address(0), "Transfer Ownership: new owner cannot be the 0 address");

        address previousOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(previousOwner, _owner);
    }

    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    function _renounceOwnership() internal {
        address previousOwner = _owner;
        _owner = address(0);

        emit OwnershipTransferred(previousOwner, _owner);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICarrier {

    function carry(address to, uint256 amount) external returns (bool);

}

pragma solidity ^0.8.6;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
  
}

