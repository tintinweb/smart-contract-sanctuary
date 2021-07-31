/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

contract MockIbBNB is IBEP20 {

    using SafeMath for uint256;

    address public owner;

    uint256 public PERIOD_DAY = 1 days;
    uint256 public SUPPLY_APY = 1e11; // 10% 
    uint256 public timeOfUpdateInterest = 0;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalBalance;

    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;

    constructor(string memory name_, string memory symbol_) public {
        owner = msg.sender;
        name = name_;
        symbol = symbol_;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public override view returns (uint256) {
        return _balances[_addr];
    }
    function getOwner() external override view returns (address) {
        return owner;
    }
    function allowance(address _owner, address _spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function changeSupplyAPY(uint256 _value) public {
      SUPPLY_APY = _value;
    }
    function approve(address _spender, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        require(_spender != address(0), "INVALID_SPENDER");

        _allowances[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);

        return true;
    }
    function deposit(uint256 amountToken) external payable {
      require(msg.value == amountToken, 'INVALID_AMOUNT');
      _updateTotalBalance();
      uint256 _pool = totalToken();
      uint256 _amountMint = 0;
      if (_totalSupply == 0) {
        _amountMint = msg.value;
      } else {
        _amountMint = (msg.value.mul(_totalSupply)).div(_pool); 
      }
      _balances[msg.sender] = _balances[msg.sender].add(_amountMint);
      _totalSupply = _totalSupply.add(_amountMint);
      _totalBalance = _totalBalance.add(msg.value);
      emit Transfer(address(0), msg.sender, _amountMint);
    }
    function withdraw(uint256 share) external {
      require(share > 0 && share >= _balances[msg.sender], 'INVALID_AMOUNT');
      _updateTotalBalance();
      uint256 amount = share.mul(totalToken()).div(totalSupply());
      _balances[msg.sender] = _balances[msg.sender].sub(share);
      _totalSupply = _totalSupply.sub(share);
      address(uint160(msg.sender)).transfer(amount);
      _totalBalance = _totalBalance.sub(amount, 'INVALID_TOTAL_BALANCE');
      emit Transfer(msg.sender, address(0), amount);
    }
    function transfer(address _to, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        require(_amount > 0, 'INVALID_AMOUNT');
        require(_balances[msg.sender] >= _amount, 'INVALID_BALANCE');

        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        _balances[_to]        = _balances[_to].add(_amount);
        /*------------------------ emit event ------------------------*/
        emit Transfer(msg.sender, _to, _amount);
        /*----------------------- response ---------------------------*/
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        require(_amount > 0, 'INVALID_AMOUNT');
        require(_balances[_from] >= _amount, 'INVALID_BALANCE');
        require(_allowances[_from][msg.sender] >= _amount, 'INVALID_PERMISSION');
        
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_amount);
        
        _balances[_from]    = _balances[_from].sub(_amount);
        _balances[_to]      = _balances[_to].add( _amount);
        /*------------------------ emit event ------------------------*/
        emit Transfer(_from, _to, _amount);
        /*----------------------- response ---------------------------*/
        return true;
    }
    function _updateTotalBalance() private {
      _totalBalance = totalToken();
      timeOfUpdateInterest = block.timestamp;
    }
    function totalToken() public view returns(uint256) {
      return _totalBalance.add(getReward());
    }

    function getReward() public view returns(uint256) {
      if (_totalBalance <= 0) {
        return 0;
      }
      if (timeOfUpdateInterest <= 0) {
        return 0;
      }
      // apy = (_reward * PERIOD_DAY * 365 * 1e12 / (block.timestamp - timeOfUpdateInterest)) / _totalBalance
      // => apy * _totalBalance = _reward * PERIOD_DAY * 365 * 1e12 / (block.timestamp - timeOfUpdateInterest)
      // => apy * _totalBalance * (block.timestamp - timeOfUpdateInterest) = _reward * PERIOD_DAY * 365 * 1e12
      // => _reward = apy * _totalBalance * (block.timestamp - timeOfUpdateInterest) / (PERIOD_DAY * 365 * 1e12)
      return SUPPLY_APY.mul(_totalBalance).mul(block.timestamp.sub(timeOfUpdateInterest)).div(PERIOD_DAY.mul(365).mul(1e12));
    }
}