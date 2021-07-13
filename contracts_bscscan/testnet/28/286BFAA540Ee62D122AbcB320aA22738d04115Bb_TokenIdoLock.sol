// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {ERC20} from '../dependencies/open-zeppelin/ERC20.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author Aave
 **/
contract TokenIdoLock{

  address public tokenAdmin;
  address public tokenCoFounder;
  address public tokenShareHolder;
  address public tokenBounty;
  address public tokenSTO;
  address public tokenLockAddress;


  // uint public unlockTime1 = 1650412847;
  // uint public unlockTime2 = 1658275247;
  // uint public unlockTime3 = 1666224047;
  // uint public unlockTime4 = 1674172847;
  uint public unlockTime1 = 1626183300;
  uint public unlockTime2 = 1626183420;
  uint public unlockTime3 = 1626183540;
  uint public unlockTime4 = 1626183660;

  // uint256 public stoRelease = 200000000 ether;
  // uint256 public CoFounderRelease = 100000000 ether;
  // uint256 public shareHolderRelease = 200000000 ether;
  // uint256 public bountyRelease = 200000000 ether;

  uint256 public stoRelease = 2000 ether;
  uint256 public CoFounderRelease = 1000 ether;
  uint256 public shareHolderRelease = 2000 ether;
  uint256 public bountyRelease = 2000 ether;

  int public releaseSTOCount = 1;
  int public releaseCoFounderCount = 1;
  int public releaseShareHolderCount = 1;
  int public releaseBountyCount = 1;

  modifier checkReleaseSTO() {
      if (releaseSTOCount > 4) {
        revert();
      }
      if(releaseSTOCount == 1 && block.timestamp <= unlockTime1) {
          revert();
      } else if(releaseSTOCount == 2 && block.timestamp <= unlockTime2) {
          revert();
      } else if(releaseSTOCount == 3 && block.timestamp <= unlockTime3) {
          revert();
      } else if(releaseSTOCount == 4 && block.timestamp <= unlockTime4) {
          revert();
      }
      _;
  }

   modifier checkReleaseBounty() {
      if (releaseBountyCount > 4) {
        revert();
      }
      if(releaseBountyCount == 1 && block.timestamp <= unlockTime1) {
          revert();
      } else if(releaseBountyCount == 2 && block.timestamp <= unlockTime2) {
          revert();
      } else if(releaseBountyCount == 3 && block.timestamp <= unlockTime3) {
          revert();
      } else if(releaseBountyCount == 4 && block.timestamp <= unlockTime4) {
          revert();
      }
      _;
  }

   modifier checkReleaseShareHolder() {
      if (releaseShareHolderCount > 4) {
        revert();
      }
      if(releaseShareHolderCount == 1 && block.timestamp <= unlockTime1) {
          revert();
      } else if(releaseShareHolderCount == 2 && block.timestamp <= unlockTime2) {
          revert();
      } else if(releaseShareHolderCount == 3 && block.timestamp <= unlockTime3) {
          revert();
      } else if(releaseShareHolderCount == 4 && block.timestamp <= unlockTime4) {
          revert();
      }
      _;
  }

 modifier checkReleaseCoFounder() {
       if (releaseCoFounderCount > 4) {
        revert();
      }
      if(releaseCoFounderCount == 1 && block.timestamp <= unlockTime1) {
          revert();
      } else if(releaseCoFounderCount == 2 && block.timestamp <= unlockTime2) {
          revert();
      } else if(releaseCoFounderCount == 3 && block.timestamp <= unlockTime3) {
          revert();
      } else if(releaseCoFounderCount == 4 && block.timestamp <= unlockTime4) {
          revert();
      }
      _;
  }
  modifier onlyTokenAdmin() {
      require(msg.sender == tokenAdmin, "INVALID TOKEN ADMIN");
      _;
  }

  constructor(
    address _tokenContract,
    address _tokenCoFounder,
    address _tokenShareHolder,
    address _tokenBounty,
    address _tokenSTO
  )
  {
    tokenLockAddress =  _tokenContract;
    tokenAdmin = msg.sender;
    tokenCoFounder =  _tokenCoFounder;
    tokenShareHolder = _tokenShareHolder;
    tokenBounty = _tokenBounty;
    tokenSTO = _tokenSTO;
  }


  function claimSTOToken() public checkReleaseSTO returns (bool) {
    ERC20(tokenLockAddress).transfer(tokenSTO, stoRelease/4);
    releaseSTOCount++;
    return true;
  }

   function claimCoFounderToken() public checkReleaseCoFounder returns (bool) {
    ERC20(tokenLockAddress).transfer(tokenCoFounder, CoFounderRelease/4);
    releaseCoFounderCount++;
    return true;
  }

   function claimShareHolderToken() public checkReleaseShareHolder returns (bool) {
    ERC20(tokenLockAddress).transfer(tokenShareHolder, shareHolderRelease/4);
    releaseShareHolderCount++;
    return true;
  }

   function claimBountyToken() public checkReleaseBounty returns (bool) {
    ERC20(tokenLockAddress).transfer(tokenBounty, bountyRelease/4);
    releaseBountyCount++;
    return true;
  }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {Context} from './Context.sol';
import {IERC20} from '../../interfaces/IERC20.sol';
import {IERC20Detailed} from '../../interfaces/IERC20Detailed.sol';
import {SafeMath} from './SafeMath.sol';

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave
 **/
contract ERC20 is Context, IERC20, IERC20Detailed {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token
   **/
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token
   **/
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @return the decimals of the token
   **/
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @return the total supply of the token
   **/
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @return the balance of the token
   **/
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev executes a transfer of tokens from msg.sender to recipient
   * @param recipient the recipient of the tokens
   * @param amount the amount of tokens being transferred
   * @return true if the transfer succeeds, false otherwise
   **/
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev returns the allowance of spender on the tokens owned by owner
   * @param owner the owner of the tokens
   * @param spender the user allowed to spend the owner's tokens
   * @return the amount of owner's tokens spender is allowed to spend
   **/
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev allows spender to spend the tokens owned by msg.sender
   * @param spender the user allowed to spend msg.sender tokens
   * @return true
   **/
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev executes a transfer of token from sender to recipient, if msg.sender is allowed to do so
   * @param sender the owner of the tokens
   * @param recipient the recipient of the tokens
   * @param amount the amount of tokens being transferred
   * @return true if the transfer succeeds, false otherwise
   **/
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  /**
   * @dev increases the allowance of spender to spend msg.sender tokens
   * @param spender the user allowed to spend on behalf of msg.sender
   * @param addedValue the amount being added to the allowance
   * @return true
   **/
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev decreases the allowance of spender to spend msg.sender tokens
   * @param spender the user allowed to spend on behalf of msg.sender
   * @param subtractedValue the amount being subtracted to the allowance
   * @return true
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, 'ERC20: burn amount exceeds allowance');
    _approve(account, _msgSender(), currentAllowance - amount);
    _burn(account, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setName(string memory newName) internal {
    _name = newName;
  }

  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IERC20} from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}