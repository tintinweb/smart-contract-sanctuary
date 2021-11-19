pragma solidity 0.8.10;

import "../sale/CloudPresaleBSC.sol";


contract MockCloudPresaleBSC is CloudPresaleBSC{

    constructor(address _busd, address _treasury){
        initialize(_busd, _treasury, 0);
    }

    function setTimeMOCK(uint _start, uint _end) external{
        require(_start<_end, "Incorrect time provided");
        PRE_SALE_START=_start;
        PRE_SALE_END=_end;
    }

    function setCLOUDpoolMOCK(uint _pool) external{
        require(_pool>PRE_SALE_CLOUD_POOL, "Incorrect amount provided");
        PRE_SALE_CLOUD_POOL=_pool;
    }

    function clearMOCK() external{
        totalPurchased=0;
        purchased[_msgSender()];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract CloudPresaleBSC is OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * EVENTS
     **/
    event CLOUDPurchased(address indexed user, address indexed purchaseToken, uint256 cloudAmount);

    /**
     * CONSTANTS
     **/

    // *** PRESALE PARAMETERS START ***
    uint256 public constant PRECISION = 100000; //Up to 0.00001
    uint256 public PRE_SALE_START = 0;
    uint256 public PRE_SALE_END = 0;

    uint256 public PRE_SALE_CLOUD_POOL = 0;
    // *** PESALE PARAMETERS END ***

    /***
     * STORAGE
     ***/
    address internal BUSDToken;

    uint256 public maxTokensAmount;
    uint256 public maxGasPrice;

    mapping(address => uint256) public purchased;

    uint256 public totalPurchased;

    mapping(address => uint256) public rates;

    address internal treasury;

    /***
     * MODIFIERS
     ***/

    /**
     * @dev Throws if gas price exceeds gas limit.
     */
    modifier correctGas() {
        require(maxGasPrice == 0 || tx.gasprice <= maxGasPrice, "Gas price exceeds limit");
        _;
    }

    /**
     * @dev Throws if called with not supported token.
     */
    modifier supportedCoin(address _token) {
        require(_token == BUSDToken, "Token is not supported");
        _;
    }

    /**
     * @dev Throws if called when no ongoing pre-sale or public sale.
     */
    modifier onlySale() {
        require(_isPreSale(), "Sale stage is over");
        _;
    }

    /**
     * @dev Throws if sale stage is ongoing.
     */
    modifier notOnSale() {
        require(block.timestamp >= PRE_SALE_END || block.timestamp <= PRE_SALE_START, "Presale is ongoing");
        _;
    }

    /***
     * INITIALIZER AND SETTINGS
     ***/

    /**
     * @notice Initializes the contract with correct addresses settings
     * @param _treasury Address of the NFTClouds's treasury where funds from sale go to
     */
    function initialize(
        address _BUSDToken,
        address _treasury,
        uint256 _purchased
    ) public virtual initializer {
        require(_treasury != address(0), "Zero address");
        require(_BUSDToken != address(0), "Zero address");

        __Ownable_init();
        __Pausable_init();

        treasury = _treasury;
        BUSDToken = _BUSDToken;

        totalPurchased = _purchased;
    }

    /**
     * @notice Sets purchased amount for participant
     * @param _user address of participant
     * @param _amount amount for participant to be set as purchased
     */
    function adminAddPurchased(address _user, uint256 _amount) external onlyOwner onlySale {
        purchased[_user] = _amount;
    }

    /**
     * @notice Sets the rate for the chosen token based on the contracts precision
     * @param _token ERC20 token address or zero address for BNB
     * @param _rate Exchange rate based on precision (e.g. _rate = PRECISION corresponds to 1:1)
     */
    function adminSetRates(address _token, uint256 _rate) external onlyOwner {
        rates[_token] = _rate;
    }

    /**
     * @notice Allows owner to change the treasury address. Treasury is the address where all funds from sale go to
     * @param _treasury New treasury address
     */
    function adminSetTreasury(address _treasury) external onlyOwner notOnSale {
        treasury = _treasury;
    }

    /**
     * @notice Stops purchase functions. Owner only
     */
    function adminPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses purchase functions. Owner only
     */
    function adminUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows owner to change max allowed TFS token per address.
     * @param _maxCLOUD New max TFS amount
     */
    function adminSetMaxCLOUD(uint256 _maxCLOUD) external onlyOwner {
        maxTokensAmount = _maxCLOUD;
    }

    /***
     * PURCHASE FUNCTIONS
     ***/

    /**
     * @notice For purchase with BNB
     */
    receive() external payable virtual onlySale whenNotPaused {
        _purchaseCLOUDwithBNB();
    }

    /**
     * @notice For purchase with allowed stablecoin (BUSD)
     * @param ERC20token Address of the token to be paid in
     * @param ERC20amount Amount of the token to be paid in
     */
    function purchaseCLOUDwithERC20(address ERC20token, uint256 ERC20amount)
        external
        onlySale
        supportedCoin(ERC20token)
        whenNotPaused
    {
        require(ERC20amount > 0, "Zero amount");
        uint256 purchaseAmount = _calcPurchaseAmount(ERC20token, ERC20amount);
        require(purchaseAmount > 0, "Rates not set");
        if (_isPreSale()) {
            require(totalPurchased + purchaseAmount <= PRE_SALE_CLOUD_POOL, "Not enough CLOUD in presale pool");
            require(
                maxTokensAmount == 0 || purchased[_msgSender()] + purchaseAmount <= maxTokensAmount,
                "Can't buy more than max cap"
            );
            totalPurchased += purchaseAmount;
        } else {
            revert("Presale is over or has bot been started yet");
        }

        IERC20Upgradeable(ERC20token).safeTransferFrom(_msgSender(), treasury, ERC20amount); // send ERC20 to Treasury
        purchased[_msgSender()] += purchaseAmount;

        if (totalPurchased == PRE_SALE_CLOUD_POOL) {
            PRE_SALE_END = block.timestamp;
        }

        emit CLOUDPurchased(_msgSender(), ERC20token, purchaseAmount);
    }

    /**
     * @notice For purchase with BNB. BNB is left on the contract until withdrawn to treasury
     */
    function purchaseCLOUDwithBNB() external payable onlySale whenNotPaused {
        require(msg.value > 0, "No BNB sent");
        _purchaseCLOUDwithBNB();
    }

    function _purchaseCLOUDwithBNB() private {
        uint256 purchaseAmount = _calcPurchaseAmount(address(0), msg.value);
        require(purchaseAmount > 0, "Rates not set");

        if (_isPreSale()) {
            require(totalPurchased + purchaseAmount <= PRE_SALE_CLOUD_POOL, "Not enough CLOUD in presale pool");
            require(
                maxTokensAmount == 0 || purchased[_msgSender()] + purchaseAmount <= maxTokensAmount,
                "Can't buy more than max cap"
            );
            totalPurchased += purchaseAmount;
        } else {
            revert("Presale is over or has bot been started yet");
        }

        purchased[_msgSender()] += purchaseAmount;

        (bool success, ) = payable(treasury).call{value: msg.value}("");
        require(success, "Transfer failed");

        emit CLOUDPurchased(_msgSender(), address(0), purchaseAmount);
    }

    /**
     * @notice Function to get available on public sale amount of CLOUD
     * @return The amount of the token released.
     */
    function preSaleAvailableCLOUD() public view returns (uint256) {
        return PRE_SALE_CLOUD_POOL - totalPurchased;
    }

    /**
     * @notice Function for the administrator to withdraw token (except DHV)
     * @notice Withdrawals allowed only if there is no sale pending stage
     * @param ERC20token Address of ERC20 token to withdraw from the contract
     */
    function adminWithdrawERC20(address ERC20token) external onlyOwner notOnSale {
        uint256 tokenBalance = IERC20Upgradeable(ERC20token).balanceOf(address(this));
        IERC20Upgradeable(ERC20token).safeTransfer(treasury, tokenBalance);
    }

    /**
     * @notice Function for the administrator to withdraw BNB for refunds
     * @notice Withdrawals allowed only if there is no sale pending stage
     */
    function adminWithdraw() external onlyOwner notOnSale {
        require(address(this).balance > 0, "Nothing to withdraw");

        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Returns CLOUD amount for 1 external token
     * @param _token External toke (BUSD, 0 address for BNB)
     */
    function rateForToken(address _token) external view returns (uint256) {
        return _calcPurchaseAmount(_token, 10**18);
    }

    /***
     * INTERNAL HELPERS
     ***/

    /**
     * @dev Checks if presale stage is on-going.
     * @return True is presale is active
     */
    function _isPreSale() private view returns (bool) {
        return (block.timestamp >= PRE_SALE_START && block.timestamp < PRE_SALE_END);
    }

    /**
     * @dev Calculates DHV amount based on rate and token.
     * @param _token Supported ERC20 token
     * @param _amount Token amount to convert to CLOUD
     * @return CLOUD amount
     */
    function _calcPurchaseAmount(address _token, uint256 _amount) private view returns (uint256) {
        return (_amount * rates[_token]) / PRECISION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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