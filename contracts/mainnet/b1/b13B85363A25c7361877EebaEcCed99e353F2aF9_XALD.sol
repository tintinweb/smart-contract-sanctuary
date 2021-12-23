/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/math/[email protected]

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/interfaces/IXALD.sol

pragma solidity ^0.7.6;

interface IXALD is IERC20 {
  function stake(address _recipient, uint256 _aldAmount) external;

  function unstake(address _account, uint256 _xALDAmount) external;

  function rebase(uint256 epoch, uint256 profit) external;

  function getSharesByALD(uint256 _aldAmount) external view returns (uint256);

  function getALDByShares(uint256 _sharesAmount) external view returns (uint256);
}


// File contracts/token/XALD.sol

pragma solidity ^0.7.6;

contract XALD is IXALD {
  using SafeMath for uint256;

  event MintShare(address recipient, uint256 share);
  event BurnShare(address account, uint256 share);
  event Rebase(uint256 epoch, uint256 profit);

  /**
   * @dev xALD balances are dynamic and are calculated based on the accounts' shares
   * and the total amount of staked ALD Token. Account shares aren't normalized, so
   * the contract also stores the sum of all shares to calculate each account's token
   * balance which equals to:
   *
   *   _shares[account] * _totalSupply / _totalShares
   */
  mapping(address => uint256) private _shares;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _totalShares;

  address public staking;

  address private _initializer;

  modifier onlyStaking() {
    require(msg.sender == staking, "XALD: only staking contract");
    _;
  }

  constructor() {
    _initializer = msg.sender;
  }

  function initialize(address _staking) external {
    require(_initializer == msg.sender, "XALD: only initializer");
    require(_staking != address(0), "XALD: not zero address");

    staking = _staking;
    _initializer = address(0);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return "staked ALD Token";
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "xALD";
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   */
  function decimals() public pure returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Returns the total shares of sALD.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address _account) public view override returns (uint256) {
    return getALDByShares(_shares[_account]);
  }

  /**
   * @return the amount of shares owned by `_account`.
   */
  function sharesOf(address _account) public view returns (uint256) {
    return _shares[_account];
  }

  /**
   * @dev See {IERC20-transfer}.
   */
  function transfer(address _recipient, uint256 _amount) public override returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return _allowances[_owner][_spender];
  }

  /**
   * @dev See {IERC20-approve}.
   */
  function approve(address _spender, uint256 _amount) public override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   */
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public override returns (bool) {
    uint256 currentAllowance = _allowances[_sender][msg.sender];
    require(currentAllowance >= _amount, "XALD: transfer amount exceeds allowance");

    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, currentAllowance.sub(_amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(msg.sender, _spender, _allowances[msg.sender][_spender].add(_addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][_spender];
    require(currentAllowance >= _subtractedValue, "XALD: decreased allowance below zero");

    _approve(msg.sender, _spender, currentAllowance.sub(_subtractedValue));
    return true;
  }

  function stake(address _recipient, uint256 _aldAmount) external override onlyStaking {
    uint256 _sharesAmount = getSharesByALD(_aldAmount);
    _totalSupply = _totalSupply.add(_aldAmount);
    _mintShares(_recipient, _sharesAmount);
  }

  function unstake(address _account, uint256 _xALDAmount) external override onlyStaking {
    uint256 _sharesAmount = getSharesByALD(_xALDAmount);
    _totalSupply = _totalSupply.sub(_xALDAmount);
    _burnShares(_account, _sharesAmount);
  }

  function rebase(uint256 epoch, uint256 profit) external override onlyStaking {
    _totalSupply = _totalSupply.add(profit);

    emit Rebase(epoch, profit);
  }

  function getSharesByALD(uint256 _aldAmount) public view override returns (uint256) {
    uint256 totalPooledALD = _totalSupply;
    if (totalPooledALD == 0) {
      return _aldAmount;
    } else {
      return _aldAmount.mul(_totalShares).div(totalPooledALD);
    }
  }

  function getALDByShares(uint256 _sharesAmount) public view override returns (uint256) {
    uint256 totalShares_ = _totalShares;
    if (totalShares_ == 0) {
      return 0;
    } else {
      return _sharesAmount.mul(_totalSupply).div(totalShares_);
    }
  }

  /**
   * @dev Moves `_amount` tokens from `_sender` to `_recipient`.
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal {
    uint256 _sharesToTransfer = getSharesByALD(_amount);
    _transferShares(_sender, _recipient, _sharesToTransfer);
    emit Transfer(_sender, _recipient, _amount);
  }

  /**
   * @dev Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
   */
  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), "XALD: approve from the zero address");
    require(_spender != address(0), "XALD: approve to the zero address");

    _allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  /**
   * @dev Moves `_sharesAmount` shares from `_sender` to `_recipient`.
   */
  function _transferShares(
    address _sender,
    address _recipient,
    uint256 _sharesAmount
  ) internal {
    require(_sender != address(0), "XALD: transfer from the zero address");
    require(_recipient != address(0), "XALD: transfer to the zero address");

    uint256 currentSenderShares = _shares[_sender];
    require(_sharesAmount <= currentSenderShares, "XALD: transfer amount exceeds balance");

    _shares[_sender] = currentSenderShares.sub(_sharesAmount);
    _shares[_recipient] = _shares[_recipient].add(_sharesAmount);
  }

  /**
   * @dev Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
   *
   * This doesn't increase the token total supply.
   */
  function _mintShares(address _recipient, uint256 _sharesAmount) internal {
    require(_recipient != address(0), "XALD: mint to the zero address");

    _totalShares = _totalShares.add(_sharesAmount);

    _shares[_recipient] = _shares[_recipient].add(_sharesAmount);

    emit MintShare(_recipient, _sharesAmount);
  }

  /**
   * @dev Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
   *
   * This doesn't decrease the token total supply.
   */
  function _burnShares(address _account, uint256 _sharesAmount) internal {
    require(_account != address(0), "XALD: burn from the zero address");

    uint256 accountShares = _shares[_account];
    require(_sharesAmount <= accountShares, "XALD: burn amount exceeds balance");

    _totalShares = _totalShares.sub(_sharesAmount);

    _shares[_account] = accountShares.sub(_sharesAmount);

    emit BurnShare(_account, _sharesAmount);
  }
}