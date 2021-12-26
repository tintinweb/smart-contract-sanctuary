/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-15
*/

pragma solidity 0.5.16;

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract NovoContract is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  struct HolderInfo {
    address holderAddress;
    uint256 holderTimestamp;
  }

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (uint256 => HolderInfo) private _holders;
  mapping (uint256 => address) private _liquidity;
  mapping (address => uint256) private _th;

  uint256 private _totalSupply;
  uint256 private _targetSupply;
  uint256 private _totalHolders;
  uint256 private _totalLiquidity;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  bool private _burnStopped;

  event log_value(string message, uint256 value);

  constructor() public {
    _name = "TEST NOVO team coin";
    _symbol = "$TSTNOVO";
    _decimals = 9;
    _totalLiquidity = 0;
    _burnStopped = false;
    _totalSupply = 100000000000 * uint(10) ** _decimals;
    _targetSupply = 10000000000 * uint(10) ** _decimals;
    _balances[msg.sender] = _totalSupply;

    _totalHolders = 1;
    _holders[0] = HolderInfo(msg.sender, now);

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function targetSupply() external view returns (uint256) {
    return _targetSupply;
  }

  function totalHolders() external view returns (uint256) {
    return _totalHolders;
  }

  function totalLiquidity() external view returns (uint256) {
    return _totalLiquidity;
  }

  function burnStopped() external view returns (bool) {
    return _burnStopped;
  }

  function getHolderInfo(uint256 _index) external view returns (address, uint256) {
    return (_holders[_index].holderAddress, _holders[_index].holderTimestamp);
  }

  function getLiquidity(uint256 _index) external view returns (address) {
    return _liquidity[_index];
  }

  function addLiquidity(address liquidityAddress) external onlyOwner returns (uint256) {
    _liquidity[_totalLiquidity] = liquidityAddress;
    _totalLiquidity.add(1);
    return _totalLiquidity;
  }  

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "NOVO: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "NOVO: decreased allowance below zero"));
    return true;
  }

  function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
    uint256 xi = _x;
    uint256 res = 0;

    xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
    xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
    xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
    xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
    xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
    xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
    xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
    xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
    xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
    xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
    xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
    xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
    xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
    xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
    xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

    return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (uint(1) << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
  }
  
  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "NOVO: transfer from the zero address");
    require(recipient != address(0), "NOVO: transfer to the zero address");
    //check if recipient have less than 0.5% of totalSupply

    {
      uint256 i;

      for (i = 0; i < _totalLiquidity; i ++) {
        if (_liquidity[i] == recipient) break;
      }

      if (i == _totalLiquidity && recipient != owner()) {
        require(_balances[recipient].add(amount) < _totalSupply.div(200), "NOVO: recipient can't have more than 0.5% of total supply");
      }
    }
    
    uint256 fee = amount.div(100);

    //calculate fee
    {
      uint256 i;
      bool isSenderLiquidity = false;
      bool isRecipientLiquidity = false;

      for (i = 0; i < _totalLiquidity; i ++) {
        if (_liquidity[i] == sender) {
          isSenderLiquidity = true;
        }

        if (_liquidity[i] == recipient) {
          isRecipientLiquidity = true;
        }
      }

      if (isSenderLiquidity && !isRecipientLiquidity) {
        fee = amount.div(50);
      } else if (!isSenderLiquidity && isRecipientLiquidity) {
        fee = amount.div(25);
      }
    }

    require(_balances[sender] >= amount, "NOVO: transfer amount exceeds balance");
    _balances[sender] = _balances[sender].sub(amount.add(fee), "NOVO: transfer and fee amount exceeds balance");

    //burn 50% of fee until totalSupply touches targetSupply
    {
      if (_burnStopped == false) {
        uint256 burnAmount = fee.div(2);

        if (_totalSupply.sub(burnAmount) < _targetSupply) {
          burnAmount = _totalSupply.sub(_targetSupply);
          _burnStopped = true;
        }
        
        _burn(sender, burnAmount);

        fee = fee.sub(burnAmount);
      }
    }

    //send treasury fee and liquidity fee
    {
      uint256 i;
      uint256 treasuryFee = fee.div(4);
      uint256 liquidityFee = fee.div(2);
      
      _balances[owner()] = _balances[owner()].add(treasuryFee);

      if (_totalLiquidity != 0) {
        uint256 sumLiquidity = 0;
        uint256 sumLiquidityFee = 0;

        for (i = 0; i < _totalLiquidity; i ++) {
          sumLiquidity = sumLiquidity.add(_balances[_liquidity[i]]);
        }

        for (i = 0; i < _totalLiquidity; i ++) {
          if (i == _totalLiquidity - 1) {
            _balances[_liquidity[i]] = _balances[_liquidity[i]].add(liquidityFee.sub(sumLiquidityFee));
            break;
          }
          _balances[_liquidity[i]] = _balances[_liquidity[i]].add(_balances[_liquidity[i]].mul(liquidityFee).div(sumLiquidity));
          sumLiquidityFee = sumLiquidityFee.add(_balances[_liquidity[i]].mul(liquidityFee).div(sumLiquidity));
        }
      } else {
        _balances[owner()] = _balances[owner()].add(liquidityFee);
      }
    }

    //divide fee to holders
    {
      uint256 i;
      uint256 j;
      uint256 divideFee = fee.sub(fee.div(4)).sub(fee.div(2));
      uint256 sum = 0;
      uint256 sumFee = 0;
      uint256 lh = now.sub(_holders[0].holderTimestamp);

      emit log_value("lh", lh);

      for (i = 0; i < _totalHolders; i ++) {
        if (_holders[i].holderAddress == owner()) continue;
        
        for (j = 0; j < _totalLiquidity; j ++) {
          if (_holders[i].holderAddress == _liquidity[j]) break;
        }

        if (j < _totalLiquidity) continue;

        uint256 th = now.sub(_holders[i].holderTimestamp);
        uint256 bs_ts; // bs / ts
        uint256 th_lh; // th / lh
        uint256 bs_ts_th_lh; // bs / ts + th / lh
        address holderAddress = _holders[i].holderAddress;

        bs_ts = _balances[holderAddress].mul(uint(10) ** 9).div(_totalSupply);
        th_lh = th.mul(uint(10) ** 9).div(lh);
        bs_ts_th_lh = bs_ts.add(th_lh).mul(uint(2) ** 32).div(uint(10) ** 9); // 50 < A < 100

        uint256 expX = generalExp(bs_ts_th_lh, 32);

        sum = sum.add(bs_ts.mul(expX));
      }

      emit log_value("sum", sum);

      if (sum == 0) {
        _balances[owner()] = _balances[owner()].add(divideFee);
      } else {
        for (i = 0; i < _totalHolders; i ++) {
          if (_holders[i].holderAddress == owner()) continue;
          
          for (j = 0; j < _totalLiquidity; j ++) {
            if (_holders[i].holderAddress == _liquidity[j]) break;
          }

          if (j < _totalLiquidity) continue;

          address holderAddress = _holders[i].holderAddress;

          if (i == _totalHolders - 1) {
            _balances[holderAddress] = _balances[holderAddress].add(divideFee.sub(sumFee));
            break;
          }

          uint256 th = now.sub(_holders[i].holderTimestamp);
          uint256 bs_ts; // bs / ts
          uint256 th_lh; // th / lh
          uint256 bs_ts_th_lh; // bs / ts + th / lh

          bs_ts = _balances[holderAddress].mul(uint(10) ** 9).div(_totalSupply);
          th_lh = th.mul(uint(10) ** 9).div(lh);
          bs_ts_th_lh = bs_ts.add(th_lh).mul(uint(2) ** 32).div(uint(10) ** 9); // 50 < A < 100

          emit log_value("bs_ts", bs_ts);
          emit log_value("th", th);
          emit log_value("th_lh", th_lh);
          emit log_value("bs_ts_th_lh", bs_ts_th_lh);

          uint256 expX = generalExp(bs_ts_th_lh, 32);

          emit log_value("expX", expX);

          uint256 feeAmount = bs_ts.mul(expX).mul(divideFee).div(sum);

          emit log_value("feeAmount", feeAmount);

          sumFee = sumFee.add(feeAmount);
          _balances[holderAddress] = _balances[holderAddress].add(feeAmount);

          emit log_value("sumFee", sumFee);
          emit log_value("_balances[holderAddress]", _balances[holderAddress]);
        }
      }
    }    

    //add recipient to holders if not in holders
    {
      uint256 i;

      for (i = 0; i < _totalHolders; i ++) {
        if (_holders[i].holderAddress == recipient) break;
      }

      if (i == _totalHolders) {
        _holders[_totalHolders] = HolderInfo(recipient, now);
        _totalHolders = _totalHolders.add(1);
      }

      _balances[recipient] = _balances[recipient].add(amount);
    }

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "NOVO: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "NOVO: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "NOVO: approve from the zero address");
    require(spender != address(0), "NOVO: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "NOVO: burn amount exceeds allowance"));
  }
}