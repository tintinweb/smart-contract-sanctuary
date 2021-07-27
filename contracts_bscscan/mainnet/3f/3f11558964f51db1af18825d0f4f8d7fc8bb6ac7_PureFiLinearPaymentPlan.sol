/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT

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




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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




interface IPureFiFarming{
    function depositTo(uint16 _pid, uint256 _amount, address _beneficiary) external;
    function deposit(uint16 _pid, uint256 _amount) external;
    function withdraw(uint16 _pid, uint256 _amount) external;
    function claimReward(uint16 _pid) external;
    function exit(uint16 _pid) external;
    function emergencyWithdraw(uint16 _pid) external;
    function getContractData() external view returns (uint256, uint256, uint64);
    function getPoolLength() external view returns (uint256);
    function getPool(uint16 _index) external view returns (address, uint256, uint64, uint64, uint64, uint256, uint256);
    function getUserInfo(uint16 _pid, address _user) external view returns (uint256, uint256, uint256);
}













/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}










/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}









/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}




 abstract contract PureFiPaymentPlan is Initializable, OwnableUpgradeable, PausableUpgradeable {

  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct Vesting{
    uint8 paymentPlan; //payment plan ID
    uint64 startDate; //payment plan initiation date. Can be 0 if PaymentPlan refers to exact unlock timestamps.
    uint256 totalAmount; //total amount of tokens vested for a person
    uint256 withdrawnAmount; //amount withdrawn by user
  }

  mapping (address => Vesting) internal vestedTokens;

  IERC20Upgradeable public token;
  uint256 public totalVestedAmount; // total amount of vested tokens under this contract control.
  address public farmingContract;
  uint8 public farmingContractPool;

  event Withdrawal(address indexed who, uint256 amount);
  event PaymentPlanAdded(uint256 index);
  event TokensVested(address indexed beneficiary, uint8 paymentPlan, uint64 startDate, uint256 amount);
  
  function initialize(
        address _token
    ) public initializer {
        __Ownable_init();
        __Pausable_init_unchained();

       require(_token != address(0),"incorrect token address");
       token = IERC20Upgradeable(_token);
    }

  function pause() onlyOwner public {
      super._pause();
  }
   
  function unpause() onlyOwner public {
      super._unpause();
  }

  function setFarmingContract(address _farmingContract, uint8 _farmingContractPool) onlyOwner public {
    farmingContract = _farmingContract;
    farmingContractPool = _farmingContractPool;
  }

  function vestTokens(uint8 _paymentPlan, uint64 _startDate, uint256 _amount, address _beneficiary) public onlyOwner whenNotPaused{
    require(vestedTokens[_beneficiary].totalAmount == 0, "This address already has vested tokens");
    require(_isPaymentPlanExists(_paymentPlan), "Incorrect payment plan index");
    require(_amount > 0, "Can't vest 0 tokens");
    require(token.balanceOf(address(this)) >= totalVestedAmount + _amount, "Not enough tokens for this vesting plan");
    vestedTokens[_beneficiary] = Vesting(_paymentPlan, _startDate, _amount, 0);
    totalVestedAmount += _amount;
    emit TokensVested(_beneficiary, _paymentPlan, _startDate, _amount);
  }

  function withdrawAvailableTokens() public whenNotPaused {
    (, uint256 available) = withdrawableAmount(msg.sender);
    _prepareWithdraw(available);
    token.safeTransfer(msg.sender, available);
  }

  function withdrawAndStakeAvailableTokens() public whenNotPaused {
    require(farmingContract != address(0),"Farming contract is not defined");
    (, uint256 available) = withdrawableAmount(msg.sender);
    _prepareWithdraw(available);
    //stake on farming contract instead of withdrawal
    token.safeApprove(farmingContract, available);
    IPureFiFarming(farmingContract).depositTo(farmingContractPool, available, msg.sender);
  }

  function withdraw(uint256 _amount) public whenNotPaused {
    _prepareWithdraw(_amount);
    token.safeTransfer(msg.sender, _amount);
  }

  function withdrawAndStake(uint256 _amount) public whenNotPaused{
    require(farmingContract != address(0),"Farming contract is not defined");
    _prepareWithdraw(_amount);
    //stake on farming contract instead of withdrawal
    token.safeApprove(farmingContract, _amount);
    IPureFiFarming(farmingContract).depositTo(farmingContractPool, _amount, msg.sender);
  }

  function _prepareWithdraw(uint256 _amount) private {
    require(vestedTokens[msg.sender].totalAmount > 0,"No tokens vested for this address");
    (, uint256 available) = withdrawableAmount(msg.sender);
    require(_amount <= available, "Amount exeeded current withdrawable amount");
    require(available > 0, "Nothing to withdraw");
    vestedTokens[msg.sender].withdrawnAmount += _amount;
    totalVestedAmount -= _amount;
    emit Withdrawal(msg.sender, _amount);
  } 
  
  /**
  * @param _beneficiary - address of the user who has his/her tokens vested on the contract
  * returns:
  * 0. next payout date for the user (0 if tokens are fully paid out)
  * 1. amount of tokens that user can withdraw as of now
  */
  function withdrawableAmount(address _beneficiary) public virtual view returns (uint64, uint256);

  /**
  * @param _beneficiary - address of the user who has his/her tokens vested on the contract
  * returns:
  * 0. payment plan ID
  * 1. vesting start date. no claims before start date allowed
  * 2. next unlock date. the date user can claim more tokens
  * 3. total amount of tokens vested
  * 4. withdrawn tokens amount (already claimed tokens, essentially) 
  * 5. amount of tokens that user can withdraw as of now
  */
  function vestingData(address _beneficiary) public view returns (uint8, uint64, uint64, uint256, uint256, uint256) {
    (uint64 nextUnlockDate, uint256 available) = withdrawableAmount(_beneficiary);
    return (vestedTokens[_beneficiary].paymentPlan, vestedTokens[_beneficiary].startDate, nextUnlockDate, vestedTokens[_beneficiary].totalAmount, vestedTokens[_beneficiary].withdrawnAmount, available);
  }

  function _isPaymentPlanExists(uint8 _id) internal virtual view returns (bool);

}
contract PureFiLinearPaymentPlan is PureFiPaymentPlan {

  struct PaymentPlan{
    uint64 cliff;
    uint64 period;
    uint64 initiallyUnlockedPercent;
    uint64 periodPayoutPercent; 
  }

  PaymentPlan[] internal paymentPlans;
  
  uint256 public constant PERCENT_100 = 100_000000; // 100% with extra denominator

  function addPaymentPlan(uint64 _cliff, uint64 _period, uint64 _initialPayoutPercent, uint64 _periodPayoutPercent) public onlyOwner whenNotPaused {
    require(_periodPayoutPercent > 0, "Incorrect _periodPayoutPercent");
    require(_period > 0, "Incorrect _period");
    paymentPlans.push(PaymentPlan(_cliff, _period, _initialPayoutPercent, _periodPayoutPercent));

    emit PaymentPlanAdded(paymentPlans.length - 1);
  }

  function withdrawableAmount(address _beneficiary) public override view returns (uint64, uint256) {
    require(vestedTokens[_beneficiary].totalAmount > 0,"No tokens vested for this address");
    uint64 paymentPlanStartDate = vestedTokens[_beneficiary].startDate;
    uint64 userCliff = paymentPlans[vestedTokens[_beneficiary].paymentPlan].cliff;

    uint256 unlockedPercent;
    uint64 nextUnlockDate;
    if(block.timestamp < paymentPlanStartDate){
      unlockedPercent = 0;
      nextUnlockDate = paymentPlanStartDate;
    } else if(block.timestamp >= paymentPlanStartDate && block.timestamp < paymentPlanStartDate + userCliff){
      unlockedPercent = paymentPlans[vestedTokens[_beneficiary].paymentPlan].initiallyUnlockedPercent;
      nextUnlockDate = paymentPlanStartDate + userCliff;
    } else {
      unlockedPercent = paymentPlans[vestedTokens[_beneficiary].paymentPlan].initiallyUnlockedPercent;
      uint256 multiplier = (block.timestamp - userCliff - paymentPlanStartDate) / paymentPlans[vestedTokens[_beneficiary].paymentPlan].period;
      unlockedPercent += multiplier * paymentPlans[vestedTokens[_beneficiary].paymentPlan].periodPayoutPercent; 
      if(unlockedPercent > PERCENT_100){
        unlockedPercent = PERCENT_100;
        nextUnlockDate = 0;
      }else{
        nextUnlockDate = paymentPlanStartDate + userCliff + uint64(multiplier + 1) * paymentPlans[vestedTokens[_beneficiary].paymentPlan].period;
      }
    }

    uint256 amountUnlocked = vestedTokens[_beneficiary].totalAmount * unlockedPercent / PERCENT_100;

    uint256 available = 0;
    if (vestedTokens[_beneficiary].withdrawnAmount < amountUnlocked){
      available = amountUnlocked - vestedTokens[_beneficiary].withdrawnAmount;
    } else {
      //overflow
      available = 0;
    }

    return (nextUnlockDate, available);
  }

  function paymentPlanData(uint256 _paymentPlan) public view returns (uint64, uint64, uint64, uint64){
    return (paymentPlans[_paymentPlan].cliff,
            paymentPlans[_paymentPlan].period,
            paymentPlans[_paymentPlan].initiallyUnlockedPercent,
            paymentPlans[_paymentPlan].periodPayoutPercent);
  }

  function _isPaymentPlanExists(uint8 _id) internal override view returns (bool){
    return (_id < paymentPlans.length);
  }
}