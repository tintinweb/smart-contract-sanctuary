/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/ISkillToken.sol


pragma solidity >=0.5.0;

interface ISkillToken {
    // IERC20Metadata
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);

    // IERC20
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);    
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // SnookGame extension
    function burn(address, uint256) external;
}


// File contracts/ISkinRewards.sol

pragma solidity ^0.8.0;

interface ISkinRewards {
  event PeriodStart(address indexed sender, uint budget);
  event PeriodUpdate(uint indexed periodIdx, uint indexed tokenId, uint currentStars, uint newStars);
  event RewardClaim(address indexed sender, uint indexed tokenId, uint indexed periodIdx, uint tokenStars, uint amount);

  function getNumberOfClaimablePeriods() external view returns (uint);
  function getTreasuryAddress() external view returns(address);
  function getAfterdeathAddress() external view returns(address);
  function getSGEAddress() external view returns(address);
  function getSnookGameAddress() external view returns(address);
  function getSNOOKAddress() external view returns (address);
  function getSNKAddress() external view returns (address);

  function getPeriodBudget(uint periodIdx) external view 
    returns(uint);
  function getPeriodBalance(uint periodIdx) external view 
    returns (uint);
  function startNewPeriod(uint budget) external;
  function updatePeriod(uint tokenId, uint currentStars, uint newStars) external;
  function getCurrentPeriodIndex() external view 
    returns (uint);
  function getIndexesOfClaimablePeriods() external view 
    returns(uint[] memory);
  function claimRewards(uint tokenId, uint periodIdx) external;
  function computeRewards(uint tokenId, uint periodIdx) external view 
    returns (uint amount, bool claimed, uint tokenStars, uint totalStars, uint budget);
  function pause() external;
  function unpause() external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // beneficiary of tokens after they are released
    address immutable private _beneficiary;

    // timestamp when token release is enabled
    uint256 immutable private _releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}


// File contracts/IStakingRewards.sol

pragma solidity ^0.8.0;

interface IStakingRewards {
  event PeriodStart(
    uint minDepositAmount,
    uint maxDepositAmount,
    uint stakingRewardsBalance,
    uint currentTotalSupply
  );

  event Deposit(
    address beneficiary, 
    address tokenTimelock,
    uint depositAmount, 
    uint rewards, 
    uint rewardsToBurn,
    uint rewardsToPay
  );

  struct DepositRecord {
    TokenTimelock tokenTimelock;
    uint depositAmount;
    uint rewards; 
    // We keep computable values rewardsToBurn and rewardsToPay for convinience: we don't want client
    // to calculate them because we don't want the client to know how to do this, though to 
    // save space we could make client to calculate them.
    uint rewardsToBurn;
    uint rewardsToPay;
  }

  function getSecondsInDay() external view returns (uint);
  function getInitialSNKSupplyInWei() external view returns (uint);
  function getMaxStakingPeriodInDays() external view returns (uint);
  function getMinStakingPeriodInDays() external view returns (uint);
  function getInterestRatePerDayInCentipercents() external view returns (uint);
  function getMinNumberOfStakers() external view returns (uint);
  function getMinStakingValueCoef() external view returns(uint);
  function getPrevInitTime() external view returns (uint);
  function getBurningRateInPercents() external view returns(uint);
  function getSNKAddress() external view returns (address);
  function getTreasuryAddress() external view returns (address);

  function init(uint maxStakingPeriodInDays) external;
  function getDepositLimits() external view returns(uint, uint);
  function deposit(uint amount, uint periodInDays) external; 
  function computeRewards(uint amount, uint periodInDays) external view 
    returns (uint rewards, uint rewardsToBurn, uint rewardsToPay);
  function getDepositRecords(address beneficiary) external view 
    returns (DepositRecord[] memory);
  function pause() external;
  function unpause() external;

}


// File contracts/ITreasury.sol


pragma solidity ^0.8.0;
uint constant PayeeCount = 3;

interface ITreasury {
  enum PayeeIds { FOUNDERS, STAKING, SKIN }
  event Transfer(uint[PayeeCount]);
  function transfer() external;
  function getPayees() external view returns (address[PayeeCount] memory);
  function getSharesInCentipercents() external view returns (uint[PayeeCount] memory);
  function getCyclesInDays() external view returns (uint[PayeeCount] memory);
  function getPayTimes() external view returns (uint[PayeeCount] memory);
  function getSecondsInDay() external view returns (uint);
  function getSNKAddress() external view returns (address);
}


// File contracts/Treasury.sol


pragma solidity ^0.8.0;





contract Treasury is ITreasury, Initializable {
  uint constant ToPercent = 100; // devide shares by that factor
  // payees should be in the order defined by PayeeIds
  address[PayeeCount] private _payees;
  uint[PayeeCount] private _sharesInCentipercents;
  uint[PayeeCount] private _cyclesInDays;
  
  uint[PayeeCount] private _payTimes;
  ISkillToken private _skill;
  uint private _secondsInDay;

  function getPayees() external override view returns (address[PayeeCount] memory) {
    return _payees;
  }

  function getSharesInCentipercents() external override view returns (uint[PayeeCount] memory) {
    return _sharesInCentipercents;
  }

  function getCyclesInDays() external override view returns (uint[PayeeCount] memory) {
    return _cyclesInDays;
  }

  function getPayTimes() external override view returns (uint[PayeeCount] memory) {
    return _payTimes;
  } 

  function getSecondsInDay() external override view returns (uint) {
    return _secondsInDay;
  } 

  // SNK is rebrandad name of SKILL
  function getSNKAddress() external override view returns (address) {
    return address(_skill);
  }

  function initialize(
    address skill,
    address[PayeeCount] memory payees, 
    uint[PayeeCount] memory sharesInCentipercents, 
    uint[PayeeCount] memory cyclesInDays,
    uint secondsInDay
  ) initializer public
  {
    
    require(_sharesOk(sharesInCentipercents) == true, "Invalid shares");
    _payees = payees;
    _sharesInCentipercents = sharesInCentipercents;
    _cyclesInDays = cyclesInDays;
    _skill = ISkillToken(skill);
    _secondsInDay = secondsInDay;
  }

  function _sharesOk(uint[PayeeCount] memory shares) private pure returns (bool) {
    uint sum = 0;
    for (uint i=0; i<PayeeCount; i++) {
      sum += shares[i] / ToPercent;
    }
    bool ok = false;
    if (sum <= 100) {
      ok = true;
    }
    return ok;
  }

  function fixPeriod2Transfer() public {
    address adminAccount = 0x6c0F6F28Ff619f87731909220D294f5e427AF251; // << Fix for production 
    require(msg.sender == adminAccount, 'not allowed');
    uint amount = 10000000000000000000000;
    address payee = _payees[uint(PayeeIds.SKIN)];
    _skill.transfer(payee, amount);
  } 

  function transfer() external override {
    uint balance = _skill.balanceOf(address(this));
    uint[PayeeCount] memory paidAmounts;

    for (uint i=0; i< PayeeCount; i++) {
      address payee = _payees[i];
      if (_payTimes[i] + _cyclesInDays[i] * _secondsInDay < block.timestamp) {
        uint amount = balance * _sharesInCentipercents[i] / ToPercent / 100;

        if (PayeeIds(i) == PayeeIds.STAKING) {
          uint balanceOfStaking = _skill.balanceOf(payee);
          if (balanceOfStaking > 0 && balanceOfStaking <= amount) {
            amount = amount - balanceOfStaking; 
          } else if (balanceOfStaking > amount) { 
            amount = 0;
          } else {} // balance is 0, do no changes to amount
        }
        
        _skill.transfer(payee, amount);
        _payTimes[i] = block.timestamp;

        paidAmounts[i] = amount;

        if (PayeeIds(i) == PayeeIds.SKIN) {
          ISkinRewards skinRewards = ISkinRewards(payee);
          skinRewards.startNewPeriod(amount);
        }

        if (PayeeIds(i) == PayeeIds.STAKING) {
          IStakingRewards stakingRewards = IStakingRewards(payee);
          stakingRewards.init(_cyclesInDays[i]);
        }
      }
    }
    emit Transfer(paidAmounts);
  }
}