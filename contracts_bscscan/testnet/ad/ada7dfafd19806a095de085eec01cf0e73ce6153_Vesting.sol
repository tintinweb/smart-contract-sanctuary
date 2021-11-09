/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
   * @dev Returns the amount of tokens owned by `_owner`.
   */
  function balanceOf(address _owner) external view returns (uint256 balance);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address _to, uint256 _value) external returns (bool success);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `_value` as the allowance of `_spender` over the caller's tokens.
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
  function approve(address _spender, uint256 _value) external returns (bool success);

  /**
   * @dev Moves `_value` tokens from `_from` to `_to` using the
   * allowance mechanism. `_value` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  /**
   * @dev Emitted when `_value` tokens are moved from one account (`_from`) to
   * another (`_to`).
   *
   * Note that `_value` may be zero.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Emitted when the allowance of a `_spender` for an `_owner` is set by
   * a call to {approve}. `_value` is the new allowance.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Vesting is Ownable {

    // Allocation distribution of the total supply.
    uint256 public constant E18                       = 10 ** 18;
    uint256 public constant SEED_ALLOCATION           = 5_000_000  * E18;
    uint256 public constant PRIVATE_ALLOCATION        = 5_000_000  * E18;
    uint256 public constant PUBLIC_ALLOCATION         = 1_250_000  * E18;
    uint256 public constant TEAM_ALLOCATION           = 9_250_000  * E18;
    uint256 public constant COMMUNITY_ALLOCATION      = 12_000_000 * E18;
    uint256 public constant LIQUIDITY_POOL_ALLOCATION = 9_500_000  * E18;
    uint256 public constant TREASURY_ALLOCATION       = 8_000_000  * E18;

    // Addresses that contain the funds for the given allocation.
    address public constant SEED      = 0x640F9A10254e0C28fA046B8b394a238Acf864641;
    address public constant PRIVATE   = 0x4B56Fe0DF8c5E330A65D6f8D6c6f341911b5FaB0;
    address public constant PUBLIC    = 0x8AD13271A702e91735132312E7ddD4AbeE96E37C;
    address public constant TEAM      = 0x127701ba09218882c7186974Fe5541dE53564915;
    address public constant COMMUNITY = 0xC8a3e44Cf503800d13C7300FF03AEB42731374FE;
    address public constant LQ_POOL   = 0x4b83d6E79993aF15aAEe182300268Cb0c8A6f2dC;
    address public constant TREASURY  = 0xeF9458C304Dc3888b574113F8AFF2bb88efF561D;

    uint256 public constant VESTING_END_AT = 1767119400;  // Wed Dec 31 2025 00:00:00 GMT+0530

    address public vestingToken;   // BEP20 token that get vested.

    event TokenSet(address vestingToken);
    event Pulled(address indexed beneficiary, uint256 amount);

    struct Schedule {
        // Name of the template
        bytes32 templateName;
        // Tokens that were already claimed
        uint256 claimedTokens;
        // Start time of the schedule
        uint256 startTime;
        // Total amount of tokens
        uint256 allocation;
        // Schedule duration (How long the schedule will last)
        uint256 duration;
        // Schedule frequency
        uint256 frequency;
        // Cliff of the schedule.
        uint256 cliff;
        // Percentage allocation for the frequency period.
        uint256 allocationAtFrequency;
        // Percentage allocation for the cliff.
        uint256 cliffAllocation;
    }

    mapping (address => Schedule[]) public schedules;

    constructor() {
        // For Seed allocation
        _createSchedule(SEED, Schedule({
            templateName         :  bytes32("Seed"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  SEED_ALLOCATION,
            duration             :  25920000,     // 10 Months (10 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (1 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  1000,         // 10 %
            cliffAllocation      :  uint256(0)
        }));

        // For Private allocation
        _createSchedule(PRIVATE, Schedule({
            templateName         :  bytes32("Private"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  PRIVATE_ALLOCATION,
            duration             :  23328000,     // 9 Months (9 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month  (1 * 30 * 24 * 60 * 60)
            cliff                :  2592000,      // 1 Month cliff.
            allocationAtFrequency:  1000,         // 10 %
            cliffAllocation      :  2000          // 20 %
        }));

        // For Public allocation
        _createSchedule(PUBLIC, Schedule({
            templateName         :  bytes32("Public"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  PUBLIC_ALLOCATION,
            duration             :  10368000,     // 4 Months (4 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month  (1 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),   
            allocationAtFrequency:  2500,         // 10 %
            cliffAllocation      :  uint256(0)
        }));

        // For Team allocation
        _createSchedule(TEAM, Schedule({
            templateName         :  bytes32("Team"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  TEAM_ALLOCATION,
            duration             :  54432000,     // 21 Months (21 * 30 * 24 * 60 * 60)
            frequency            :  7776000,      // 3 Month   (1 * 30 * 24 * 60 * 60)
            cliff                :  31104000,     // 12 Month cliff.
            allocationAtFrequency:  2500,         // 25 % 
            cliffAllocation      :  2500          // 25 %
        }));

        // For Community allocation -- 1
        _createSchedule(COMMUNITY, Schedule({
            templateName         :  bytes32("Community_1"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  24 * COMMUNITY_ALLOCATION / 100,   // 24 % of the total community allocation.
            duration             :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (01 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  833,          // 8.33 % Rest of the dust will send back to the user at the end of the schedule. 
            cliffAllocation      :  uint256(0)
        }));

        // For Community allocation -- 2
        _createSchedule(COMMUNITY, Schedule({
            templateName         :  bytes32("Community_2"),
            claimedTokens        :  uint256(0),
            startTime            :  1661884200,   // Wed Aug 31 2022 00:00:00 GMT+0530
            allocation           :  36 * COMMUNITY_ALLOCATION / 100,   // 36 % of the total community allocation.
            duration             :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (01 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  833,          // 8.33 % Rest of the dust will send back to the user at the end of the schedule. 
            cliffAllocation      :  uint256(0)
        }));

        // For Community allocation -- 3
        _createSchedule(COMMUNITY, Schedule({
            templateName         :  bytes32("Community_3"),
            claimedTokens        :  uint256(0),
            startTime            :  1693420200,   // Wed Aug 31 2023 00:00:00 GMT+0530
            allocation           :  40 * COMMUNITY_ALLOCATION / 100,   // 40 % of the total community allocation.
            duration             :  31104000,     // 12 Months (12 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (01 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  833,          // 8.33 % Rest of the dust will send back to the user at the end of the schedule. 
            cliffAllocation      :  uint256(0)
        }));

        // For Liquidity Pool allocation  -- 1
        _createSchedule(LQ_POOL, Schedule({
            templateName         :  bytes32("Liquidity_pool_1"),
            claimedTokens        :  uint256(0),
            startTime            :  1630348200,   // Tue Aug 31 2021 00:00:00 GMT+0530
            allocation           :  10 * LIQUIDITY_POOL_ALLOCATION / 100, // 10 % of the total liquidity pool allocation.
            duration             :  5184000,      // 2 Months (2 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month  (1 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  5000,         // 50 % 
            cliffAllocation      :  uint256(0)
        }));

        // For Liquidity Pool allocation  -- 2
        _createSchedule(LQ_POOL, Schedule({
            templateName         :  bytes32("Liquidity_pool_2"),
            claimedTokens        :  uint256(0),
            startTime            :  1635618600,   // Sun Oct 31 2021 00:00:00 GMT+0530
            allocation           :  90 * LIQUIDITY_POOL_ALLOCATION / 100,
            duration             :  116640000,    // 45 Months (45 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (1 * 30 * 24 * 60 * 60)
            cliff                :  uint256(0),
            allocationAtFrequency:  222,          // 2.22 % 
            cliffAllocation      :  uint256(0)
        }));

        // For Treasury allocation
        _createSchedule(TREASURY, Schedule({
            templateName         :  bytes32("Treasury"),
            claimedTokens        :  uint256(0),
            startTime            :  1661884200,   // Wed Aug 31 2022 00:00:00 GMT+0530
            allocation           :  TREASURY_ALLOCATION,
            duration             :  134784000,    // 52 Months (52 * 30 * 24 * 60 * 60)
            frequency            :  2592000,      // 1 Month   (1 * 30 * 24 * 60 * 60)
            cliff                :  31104000,     // 12 Month cliff.
            allocationAtFrequency:  250,          // 2.5 % 
            cliffAllocation      :  uint256(0)    // 0 %
        }));
    }

    /**
     * @dev Allow owner to set the token address that get vested.
     * @param tokenAddress Address of the BEP-20 token.
     */
    function setToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Vesting: ZERO_ADDRESS_NOT_ALLOWED");
        require(vestingToken == address(0), "Vesting: ALREADY_SET");
        require(IBEP20(tokenAddress).balanceOf(address(this)) > uint256(0), "Vesting: INSUFFICIENT_BALANCE");
        vestingToken = tokenAddress;
        emit TokenSet(tokenAddress);
    }

    /**
     * @dev Allow owner to skim the token from the contract.
     * @param tokenAddress Address of the BEP-20 token.
     * @param amount       Amount of token that get skimmed out of the contract.
     * @param destination  Whom token amount get transferred to.
     */
    function skim(address tokenAddress, uint256 amount, address destination) external onlyOwner {
        require(block.timestamp > VESTING_END_AT, "Vesting: NOT_ALLOWED");
        require(destination != address(0),        "Vesting: ZERO_ADDRESS_NOT_ALLOWED");
        SafeERC20.safeTransfer(IERC20(tokenAddress), destination, amount);
    }

    /**
     * @dev Allow the respective addresses pull the vested tokens.
     */
    function pull() external {
        Schedule[] memory _schedules = schedules[msg.sender];
        require(_schedules.length != uint256(0), "Vesting: NOT_AUTORIZE");
        uint256 amount = 0;
        for (uint8 i = 0; i < _schedules.length; i++) {
            uint256 vestedAmount = 0;
            if (_schedules[i].startTime > block.timestamp || _schedules[i].claimedTokens == _schedules[i].allocation) {
                continue;
            }
            if (_schedules[i].startTime + _schedules[i].duration <= block.timestamp) {
                vestedAmount = _schedules[i].allocation;
            } else {
                if (_schedules[i].cliff != uint256(0) && _schedules[i].startTime + _schedules[i].cliff <= block.timestamp) {
                    vestedAmount = _schedules[i].cliffAllocation * _schedules[i].allocation / 10_000;
                }
                if (block.timestamp > _schedules[i].startTime + _schedules[i].cliff) {
                    uint256 timeDelta            = block.timestamp - _schedules[i].startTime - _schedules[i].cliff;
                    uint256 noOfPeriods          = timeDelta / _schedules[i].frequency;
                    uint256 unitPeriodAllocation = _schedules[i].allocationAtFrequency * _schedules[i].allocation / 10_000;
                    vestedAmount += unitPeriodAllocation * noOfPeriods;
                } 
            }
            uint256 claimAmountPerSchedule = vestedAmount - _schedules[i].claimedTokens;
            schedules[msg.sender][i].claimedTokens += claimAmountPerSchedule;
            amount += claimAmountPerSchedule;
        }
        require(amount > uint256(0), "Vesting: NO_VESTED_TOKENS");
        SafeERC20.safeTransfer(IERC20(vestingToken), msg.sender, amount);
        emit Pulled(msg.sender, amount);
    }

    function _createSchedule(address _beneficiary, Schedule memory _schedule) internal {
        schedules[_beneficiary].push(_schedule);
    }

}