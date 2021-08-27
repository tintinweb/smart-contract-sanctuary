/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-20
 */

// Hodls.finance Platform Token BEP20
//
// Web: https://hodls.money/
// Telegram announcement channel: https://t.me/sct_notice
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
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
   *
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
   *
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
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
   *
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
   *
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;


      bytes32 accountHash
     = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(
      data
    );
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @dev Hodls.money
 * Max Supply : 3500 HODL
 * Fee Rate : 4.4%
 * Burn Rate : 4.4%
 * Team Fee : 1.2%
 */
contract Hodls1 is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _rOwned; // 현재 코인 보유수량
  mapping(address => uint256) private _tOwned; // excluded 된 account가 가진 보유수량
  mapping(address => mapping(address => uint256)) private _allowances; // Transfer Allowance

  mapping(address => bool) private _isExcluded; // Fee 분배 제외 계정 여부
  address[] private _excluded; // Fee 분배 `제외 계정 Array

  string private constant _NAME = "DL1";
  string private constant _SYMBOL = "DL1";
  uint8 private constant _DECIMALS = 8;

  uint256 private constant _MAX = ~uint256(0); // 숫자로 나타낼 수 있는 최대 수(Max 값)
  uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS); // Decimal Factor
  uint256 private constant _GRANULARITY = 100;

  // Total Amount
  uint256 private _tTotal = 3500 * _DECIMALFACTOR;
  // _MAX에서 _tTotal 나머지를 뺀수(아주 큰수)
  // 아주 큰 수에서 _tTotal 나머지를 뺀 수는 항상 _tTotal 값으로 나누어 짐.. 그렇기 떄문에 이렇게 계산을 한다.
  uint256 private _rTotal = (_MAX - (_MAX % _tTotal));

  uint256 private _tFeeTotal; // Total Fee Amount
  uint256 private _tBurnTotal; // Total Burn Amount

  // Fee 총합은 1000(10%)
  uint256 private constant _TAX_FEE = 440;
  uint256 private constant _BURN_FEE = 440;
  uint256 private constant _TEAM_FEE = 120;

  uint256 private constant _MAX_TX_SIZE = 3500 * _DECIMALFACTOR;

  // address private _owner;    // ownable.sol에 정의
  address private _teamAddress = 0x9a1789bDCbB549FcC19EE559921De904f09c6132;
  address private _ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  uint256 private _startBlock; // 시작블럭번호
  uint256 private _unlockBlock; // 락업 해제 블럭 번호
  uint256 private _oneYearBlocks = 10512000; // 365 days

  mapping(address => bool) private _isLocked; // Lockup 계정 여부
  address[] private _lockupList; // Lockup 대상 Addresses 이 계정들은 1년 이내에 전송 불가

  bool private _isAppliedFee = false; // Fee On/Off
  bool private _isAppliedBurn = false; // Burn On/Off
  bool private _isAppliedTeamFee = false; // Team Fee On/Off

  /**
   * @dev Hodls.money
   * Max Supply : 3500 HODL
   * Fee Rate : 4.4%
   * Burn Rate : 4.4%
   * Team Fee : 1.2%
   */
  struct TransferInfo {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tBurn;
    uint256 rTeam;
    uint256 tTeam;
  }

  constructor() {
    _startBlock = block.number;
    _unlockBlock = _startBlock + _oneYearBlocks; // Lockup 해제 블럭 설정

    _rOwned[_msgSender()] = _rTotal;
    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  /**
   * @dev Balance of HODL
   * In case of excluded account, use tOwned
   * In case of excluded account, use reflected _rOwned
   */
  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  /**
   * @dev Get reflected quantity
   */
  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  /**
   * @dev Get reflection rate
   */
  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  /**
   * @dev Get Current Supply(rTotal, tTotal)
   * The excluded account(_excluded) quantity is subtracted.
   */
  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  /**
   * @dev Transfer Token
   */
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Transfer Token from account to account
   * 기능적으로는 없어도 될 것 같은데, 참고 토큰 코드에 있어서 일단 포함시켜봅니다.
   * 일반적으로 transferFrom이 사용 되는 경우와
   * 아래와 같이 _approve에 _allowances[sender][_msgSender()] 처럼
   * _allowances의 두번째 값이 recipient가 아닌 _msgSender()이 사용 된 이유가
   * 이해가 안가는 상황입니다.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "BEP20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  /**
   * @dev Increase Allowance
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Decrease Allowance
   */
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
        "BEP20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Returns whether the account is excluded.
   */
  function isExcluded(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  /**
   * @dev Returns total amount of fee
   */
  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  /**
   * @dev Returns total amount of burning
   */
  function totalBurn() public view returns (uint256) {
    return _tBurnTotal;
  }

  /**
   * @dev Returns excluded account list
   */
  function getExcludeList() public view returns (address[] memory) {
    return _excluded;
  }

  /**
   * @dev Returns locked up account list
   */
  function getLockupList() public view returns (address[] memory) {
    return _lockupList;
  }

  /**
   * @dev Returns reflection value by tAmount
   */
  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      TransferInfo memory transferInfo = _getValues(tAmount);
      return transferInfo.rAmount;
    } else {
      TransferInfo memory transferInfo = _getValues(tAmount);
      return transferInfo.rTransferAmount;
    }
  }

  /**
   * @dev Exclude excluded account
   */
  function excludeAccount(address account) external onlyOwner() {
    require(account != _ROUTER_ADDRESS, "We can not exclude router address.");
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  /**
   * @dev Include exclude account
   */
  function includeAccount(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is already included");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  /**
   * @dev Include lock up account
   * It doesn't exist lock up release function
   * Registered account can be transferred after unlock blocknumber
   */
  function includeLockupAccount(address account) external onlyOwner() {
    require(!_isLocked[account], "Account is already locked up");
    _isLocked[account] = true;
    _lockupList.push(account);
  }

  /**
   * @dev Allow transmission amount from account to account
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Transfer token from account to account
   * Call different transfer functions depending on whether the account is excluded
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    if (_isLocked[sender]) {
      require(block.number > _unlockBlock, "Sender is locked yet");
    }

    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (sender != owner() && recipient != owner())
      require(
        amount <= _MAX_TX_SIZE,
        "Transfer amount exceeds the maxTxAmount."
      );

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }
  }

  /**
   * @dev Set whether to apply fee
   */
  function setFee(bool isAppliedFee) external onlyOwner() {
    _isAppliedFee = isAppliedFee;
  }

  /**
   * @dev Set whether to apply burn
   */
  function setBurn(bool isAppliedBurn) external onlyOwner() {
    _isAppliedBurn = isAppliedBurn;
  }

  /**
   * @dev Set whether to apply teamfee
   */
  function setTeamFee(bool isAppliedTeamFee) external onlyOwner() {
    _isAppliedTeamFee = isAppliedTeamFee;
  }

  /**
   * @dev Return whether to apply fee
   */
  function getFeeApplied() public view returns (bool) {
    return _isAppliedFee;
  }

  /**
   * @dev Return whether to apply burn
   */
  function getBurnApplied() public view returns (bool) {
    return _isAppliedBurn;
  }

  /**
   * @dev Return whether to apply teamfee
   */
  function getTeamFeeApplied() public view returns (bool) {
    return _isAppliedTeamFee;
  }

  /**
   * @dev Set teamfee address
   */
  function setTeamAddress(address teamAddress) public onlyOwner() {
    _teamAddress = teamAddress;
  }

  /**
   * @dev Transfer from normal account to excluded account
   */
  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    TransferInfo memory transferInfo = _getValues(tAmount);
    uint256 rBurn = transferInfo.tBurn.mul(currentRate);
    _rOwned[_teamAddress] = _rOwned[_teamAddress].add(transferInfo.rTeam);
    _rOwned[sender] = _rOwned[sender].sub(transferInfo.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(transferInfo.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(transferInfo.rTransferAmount);
    _reflectFee(rBurn, transferInfo);
    emit Transfer(sender, recipient, transferInfo.tTransferAmount);
  }

  /**
   * @dev Transfer from excluded account to normal account
   */
  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    TransferInfo memory transferInfo = _getValues(tAmount);
    uint256 rBurn = transferInfo.tBurn.mul(currentRate);
    _rOwned[_teamAddress] = _rOwned[_teamAddress].add(transferInfo.rTeam);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(transferInfo.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(transferInfo.rTransferAmount);
    _reflectFee(rBurn, transferInfo);
    emit Transfer(sender, recipient, transferInfo.tTransferAmount);
  }

  /**
   * @dev Transfer from excluded account to excluded account
   */
  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    TransferInfo memory transferInfo = _getValues(tAmount);
    uint256 rBurn = transferInfo.tBurn.mul(currentRate);
    _rOwned[_teamAddress] = _rOwned[_teamAddress].add(transferInfo.rTeam);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(transferInfo.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(transferInfo.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(transferInfo.rTransferAmount);
    _reflectFee(rBurn, transferInfo);
    emit Transfer(sender, recipient, transferInfo.tTransferAmount);
  }

  /**
   * @dev Transfer from normal account to normal account
   */
  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 currentRate = _getRate();
    TransferInfo memory transferInfo = _getValues(tAmount);
    uint256 rBurn = transferInfo.tBurn.mul(currentRate);
    _rOwned[_teamAddress] = _rOwned[_teamAddress].add(transferInfo.rTeam);
    _rOwned[sender] = _rOwned[sender].sub(transferInfo.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(transferInfo.rTransferAmount);
    _reflectFee(rBurn, transferInfo);
    emit Transfer(sender, recipient, transferInfo.tTransferAmount);
  }

  /**
   * @dev Set global variables(rTotal, TotalFee, TotalBurn, tTotal)
   */
  function _reflectFee(uint256 rBurn, TransferInfo memory transferInfo)
    private
  {
    _rTotal = _rTotal.sub(transferInfo.rFee).sub(rBurn);
    _tFeeTotal = _tFeeTotal.add(transferInfo.tFee);
    _tBurnTotal = _tBurnTotal.add(transferInfo.tBurn);
    _tTotal = _tTotal.sub(transferInfo.tBurn);
  }

  /**
   * @dev Returns an TransferInfo(various values about transmission).
   */
  function _getValues(uint256 tAmount)
    private
    view
    returns (TransferInfo memory)
  {
    TransferInfo memory transferInfo = _getTValues(
      tAmount,
      _TAX_FEE,
      _BURN_FEE,
      _TEAM_FEE
    );
    uint256 currentRate = _getRate();
    _getRValues(tAmount, transferInfo, currentRate);
    return transferInfo;
  }

  /**
   * @dev Returns transfer info about tValues(real amount)
   */
  function _getTValues(
    uint256 tAmount,
    uint256 taxFee,
    uint256 burnFee,
    uint256 teamFee
  ) private view returns (TransferInfo memory) {
    uint256 tFee = _isAppliedFee
      ? ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100)
      : 0; // _GRANULARITY = 100
    uint256 tBurn = _isAppliedBurn
      ? ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100)
      : 0;
    uint256 tTeam = _isAppliedTeamFee
      ? ((tAmount.mul(teamFee)).div(_GRANULARITY)).div(100)
      : 0;
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tTeam);
    TransferInfo memory transferInfo = TransferInfo(
      0,
      0,
      0,
      tTransferAmount,
      tFee,
      tBurn,
      0,
      tTeam
    );
    return transferInfo;
  }

  /**
   * @dev Returns transfer info about rValues(reflection amount)
   */
  function _getRValues(
    uint256 tAmount,
    TransferInfo memory transferInfo,
    uint256 currentRate
  ) private pure returns (TransferInfo memory) {
    transferInfo.rAmount = tAmount.mul(currentRate);
    transferInfo.rFee = transferInfo.tFee.mul(currentRate);
    uint256 rBurn = transferInfo.tBurn.mul(currentRate);
    transferInfo.rTeam = transferInfo.tTeam.mul(currentRate);
    transferInfo.rTransferAmount = transferInfo
    .rAmount
    .sub(transferInfo.rFee)
    .sub(rBurn)
    .sub(transferInfo.rTeam);
    return transferInfo;
  }

  /**
   * @dev Returns the fee value
   */
  function _getTaxFee() private pure returns (uint256) {
    return _TAX_FEE;
  }

  /**
   * @dev Returns the maximum transfer quantity
   */
  function _getMaxTxAmount() private pure returns (uint256) {
    return _MAX_TX_SIZE;
  }

  /**
   * @dev Returns the token name
   */
  function name() public pure returns (string memory) {
    return _NAME;
  }

  /**
   * @dev Returns the token symbol
   */
  function symbol() public pure returns (string memory) {
    return _SYMBOL;
  }

  /**
   * @dev Returns the token decimals
   */
  function decimals() public pure returns (uint8) {
    return _DECIMALS;
  }

  /**
   * @dev Returns the total supply
   */
  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  /**
   * @dev Returns allowance amount from owner to spender
   */
  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev Set allowance amount from msgSender to spender
   */
  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }
}