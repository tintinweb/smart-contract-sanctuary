/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4-solc-0.7/contracts/utils/Address.sol

pragma solidity ^0.7.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4-solc-0.7/contracts/math/SafeMath.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4-solc-0.7/contracts/token/ERC20/IERC20.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4-solc-0.7/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.7.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.7.3;

contract FundFlow {

  enum Status { FUG, PRS, FID, PEG, CAL, RED }// Funding, progress, finished, pending, cancel, release 
  struct Phase {
    uint    duration;         
    uint256 dateEnd;          // deadline have to upload file
    uint    widwable;         // amount crypto for creator
  }
  struct Project {
    address creator;
    uint    phNum;            // number phase
    uint    bakNum;           // number backer funded
    uint    bakAmt;           // money for each backer
    uint    deniedMax;        // number backer denied max
    uint    budget;           // budget = bakNum * bakAmt ( include TAX )
    uint    tax;
  }
  struct Result {
    bool    pass;             // success or fail
    string  file;             // save in S3 AWS
  }
  
  mapping(string  => Project)                     internal _pPro;
  mapping(string  => Status)                      internal _pSta;
  mapping(string  => Phase[])                     internal _pPhs;
  mapping(string  => Result[])                    internal _pRes;

  mapping(string  => mapping(uint => address[]))  internal _denied;
  mapping(string  => uint)                        internal _budget;
  mapping(string  => mapping(address => uint256)) internal _funds;         // backer address => projectId => block date
  mapping(string  => uint)                        internal _widwable;      // creator can withdraw amount
  mapping(string  => uint)                        internal _bkAmt;         // amount each banker refundable
  mapping(string  => mapping(address => uint256)) internal _refunds;       // projectCode => backer address => amount
  uint                                            internal _getTax;        // get TAX
  
  event EAction(string action, string indexed name, string project, address creator, address affector, uint bakNum, uint256 bakAmt, uint256 amount);
  event EFinal(string action, string indexed name, string project, address actor, string nft, uint widwable, uint backAmount);

  function createProject( string memory name_, address creator_, 
                          uint bakNum_, uint256 bakAmt_, 
                          uint deniedMax_, uint256 tax_ ,
                          uint256[] memory duration_, uint256[] memory widwable_ ) public {
    require(deniedMax_        <= bakNum_, "invalid denied number");
    require(duration_.length  == widwable_.length, "invalid phase length");
    require(_pPro[name_].tax  > 0, "exist project");
    require(_budget[name_]    <  1, "project is fundraising");

    Project storage pro = _pPro[name_];
    pro.creator         = creator_;
    pro.phNum           = duration_.length;
    pro.bakNum          = bakNum_;
    pro.bakAmt          = bakAmt_;
    pro.deniedMax       = deniedMax_;
    pro.budget          = bakNum_ * bakAmt_;
    pro.tax             = tax_;
    _pSta[name_]        = Status.FUG;
    
    uint256 pDateEndTmp  = block.timestamp;
    for(uint i = 0; i < duration_.length; i++) {
      require(duration_[i]  > 86000, "invalid duration");
      Phase memory pha;
      pha.duration      = duration_[i];
      pDateEndTmp       = pDateEndTmp + duration_[i];
      pha.dateEnd       = pDateEndTmp;
      pha.widwable      = widwable_[i];
      _pPhs[name_].push(pha);
    }
    _widwable[name_]    = 0;
    emit EAction("Create", name_, name_, msg.sender, creator_, bakNum_, bakAmt_, pro.budget);
  }

  function _next(string memory name_, string memory file_) private {
    uint phN                              =  _pRes[name_].length;
    require(phN                           <  _pPro[name_].phNum, "invalid phase");
    require(_pPhs[name_][phN].dateEnd     >= block.timestamp,"invalid phase time"); //TODO: check min date 
    require(_denied[name_][phN].length    <  _pPro[name_].deniedMax, "backers denied");
    Result memory res;
    res.pass              = true;
    res.file              = file_;
    _pRes[name_].push(res);
    _widwable[name_]      = _widwable[name_] + _pPhs[name_][phN].widwable;
    _budget[name_]        = _budget[name_]   - _pPhs[name_][phN].widwable;
    _pPhs[name_][phN+1].dateEnd = block.timestamp + _pPhs[name_][phN+1].duration;
  }
  
  function kickoff(string memory name_) public {
    require(_pSta[name_]             == Status.FUG, "invalid status");
    require(_pPro[name_].budget      == _budget[name_], "invalid budget");
    _next(name_, "");
    _pSta[name_]                     = Status.PRS;
    _getTax                          = _getTax + _pPro[name_].tax;
    _budget[name_]                   = _budget[name_] - _pPro[name_].tax;
    emit EAction("Kickoff", name_, name_, msg.sender, _pPro[name_].creator, _pPro[name_].tax, _widwable[name_], _budget[name_]);
  }
  
  function commit(string memory name_, string memory file_) public {
    require(_pSta[name_]             == Status.PRS, "invalid status");
    require(_pPro[name_].creator     == msg.sender, "invalid creator");
    _next(name_, file_);
    uint phN    = _pRes[name_].length;
    if(phN + 1  == _pPro[name_].phNum ) {
      _pSta[name_]                 = Status.FID;
    }   
    emit EFinal("Commit", name_, name_, msg.sender, file_, phN, _widwable[name_]);
  }
  
  function release(string memory name_, string memory nft_) public {
    require(_pPro[name_].creator   ==  msg.sender, "invalid creator");
    require(_pSta[name_]           ==  Status.FID, "invalid status");
    uint phN                       =   _pRes[name_].length;
    require(_denied[name_][phN].length < _pPro[name_].deniedMax, "backers denied");
    
    Result memory res;
    res.pass              = true;
    res.file              = nft_;
    _pRes[name_].push(res);
    _pSta[name_]          = Status.RED;
    _widwable[name_]      = _widwable[name_] + _budget[name_];
    _budget[name_]        = 0;    
    emit EFinal("Release", name_, name_, msg.sender, nft_, phN, _widwable[name_]);
  }
  
  function cancel(string memory name_, string memory note_) public  {
    require(_pSta[name_]    != Status.CAL && _pSta[name_] != Status.RED, "invalid status");
    Result memory res;
    res.pass                = false;
    res.file                = note_;
    _pRes[name_].push(res);
    _pSta[name_]            = Status.CAL;
    _bkAmt[name_]           = _budget[name_]/_pPro[name_].bakNum;
    emit EFinal("Cancel", name_, name_, msg.sender, note_, _widwable[name_], _bkAmt[name_]);
  }
  
}
// TODO : check tao project
// TODO : check date cua moi phase khi commit 
contract CrowdFunding is FundFlow {
  
  using SafeERC20 for IERC20;
  address public _token;
  address _owner;               // owner
  
  event Own(string action, address creator, uint tax);
  
  constructor(address token_) 
  {
    _owner  = msg.sender;
    _getTax = 0;
    _token  = token_;
  }
  
  modifier owner(){
    require(_owner  == msg.sender, "invalid owner");
    _;
  }
  
  function fund(string memory name_, address backer_, uint amount_) public {
    require(_pSta[name_]               == Status.FUG, "invalid status");
    require(_pPhs[name_][0].dateEnd    >= block.timestamp, "invalid funding time");
    require(_pPro[name_].budget        >  _budget[name_], "enough budget");
    require(_pPro[name_].bakAmt        == amount_, "amount incorrect");
    require(_funds[name_][backer_]  <  1, "already fundraising");
    require(_pPro[name_].creator       != backer_, "invalid backer");
    require(IERC20(_token).allowance(backer_, address(this)) >= amount_, "need approved");
    IERC20(_token).transferFrom(backer_, address(this), amount_);
    
    _budget[name_]                     = _budget[name_] + amount_;
    _funds[name_][backer_]             = amount_;
    emit EAction("Fund", name_, name_, msg.sender, backer_, amount_, _budget[name_], _pPro[name_].budget);
  }
  
  function deny(string memory name_) public {
    require(_funds[name_][msg.sender] == _pPro[name_].bakAmt, "invalid backer");
    require(_pSta[name_]              == Status.PRS || _pSta[name_] == Status.FID,"invalid status");
    require(_pRes[name_].length       >= 2, "invalid phase");
    uint phN                          = _pRes[name_].length;
    _denied[name_][phN].push(msg.sender);
    if(_denied[name_][phN].length     >= _pPro[name_].deniedMax)
      _pSta[name_]                    = Status.PEG;
    emit EAction("Deny", name_, name_, msg.sender, _pPro[name_].creator, phN, _budget[name_]/_pPro[name_].bakNum, _budget[name_]);
  }
  
  function refund(string memory name_) public {
    require(_pSta[name_]                ==  Status.CAL, "invalid status");
    require(_budget[name_]              >=  _bkAmt[name_], "invalid budget");
    require(_funds[name_][msg.sender]   >   0, "invalid backer");
    require(_refunds[name_][msg.sender] <   1, "already refund");
    
    _refunds[name_][msg.sender]         =  _bkAmt[name_];
    _bkAmt[name_]                       = 0;
    _budget[name_]                      =  _budget[name_] - _bkAmt[name_];
    IERC20(_token).safeTransfer(msg.sender, _refunds[name_][msg.sender]);
    
    emit EAction("Refund", name_, name_, msg.sender, _pPro[name_].creator, _pRes[name_].length, _widwable[name_], _bkAmt[name_]);
  }
  
  function withdraw(string memory name_) public {
    require(_pPro[name_].creator   == msg.sender, "invalid creator");
    require(_widwable[name_]        >   0, "invalid widwable");
    uint withdrawed                 = _widwable[name_];
    _widwable[name_]                = 0;
    IERC20(_token).safeTransfer(msg.sender, withdrawed);
    
    emit EAction("Withdraw", name_, name_, msg.sender, _pPro[name_].creator, _pRes[name_].length, withdrawed, 0);
  }
  
  function getPhase(string memory name_) public view returns (uint256) {
      require(_pRes[name_].length > 0, "invalid project");
      return _pRes[name_].length;
  }
  
  function getBudget(string memory name_) public view returns (uint256) {
      require(_pRes[name_].length > 0, "invalid project");
      return _budget[name_];
  }
  
  function getFund(string memory name_, address backer_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      return _funds[name_][backer_];
  }
  
  function getRefund(string memory name_, address backer_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      require(_funds[name_][backer_] > 0, "invalid backer");
      return _refunds[name_][backer_];
  }
  
  function getWithdraw(string memory name_, address creator_) public view returns (uint256) {
      require(_pPro[name_].tax > 0, "invalid project");
      require(_pPro[name_].creator   == creator_, "invalid creator");
      return _widwable[name_];
  }

  function getTax() public owner {
    uint backup = _getTax;
    _getTax     = 0;
    IERC20(_token).safeTransfer(msg.sender, _getTax);
    emit Own("Tax",msg.sender, backup);
  }
  
  function closeAll() public owner {
    uint bal    = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(msg.sender, bal);
    emit Own("Close",msg.sender, bal);
  }
  
}