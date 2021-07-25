/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/core/IPermissions.sol

pragma solidity ^0.8.4;

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
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


// File contracts/token/IFei.sol

pragma solidity ^0.8.4;

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IFei is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address account, address incentive) external;

    // ----------- Getters -----------

    function incentiveContract(address account) external view returns (address);
}


// File contracts/core/ICore.sol

pragma solidity ^0.8.4;


/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event FeiUpdate(address indexed _fei);
    event TribeUpdate(address indexed _tribe);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event TribeAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setFei(address token) external;

    function setTribe(address token) external;

    function setGenesisGroup(address _genesisGroup) external;

    function allocateTribe(address to, uint256 amount) external;

    // ----------- Genesis Group only state changing api -----------

    function completeGenesisGroup() external;

    // ----------- Getters -----------

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);

    function genesisGroup() external view returns (address);

    function hasGenesisGroupCompleted() external view returns (bool);
}


// File contracts/refs/ICoreRef.sol

pragma solidity ^0.8.4;

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    // ----------- Governor only state changing api -----------

    function setCore(address newCore) external;

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);

    function feiBalance() external view returns (uint256);

    function tribeBalance() external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
}


// File contracts/refs/CoreRef.sol
pragma solidity ^0.8.4;


/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private _core;

    /// @notice CoreRef constructor
    /// @param coreAddress Fei Core to reference
    constructor(address coreAddress) {
        _core = ICore(coreAddress);
    }

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) ||
            _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyFei() {
        require(msg.sender == address(fei()), "CoreRef: Caller is not FEI");
        _;
    }

    /// @notice set new Core reference address
    /// @param newCore the new core address
    function setCore(address newCore) external override onlyGovernor {
        require(newCore != address(0), "CoreRef: zero address");
        address oldCore = address(_core);
        _core = ICore(newCore);
        emit CoreUpdate(oldCore, newCore);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function fei() public view override returns (IFei) {
        return _core.fei();
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function tribe() public view override returns (IERC20) {
        return _core.tribe();
    }

    /// @notice fei balance of contract
    /// @return fei amount held
    function feiBalance() public view override returns (uint256) {
        return fei().balanceOf(address(this));
    }

    /// @notice tribe balance of contract
    /// @return tribe amount held
    function tribeBalance() public view override returns (uint256) {
        return tribe().balanceOf(address(this));
    }

    function _burnFeiHeld() internal {
        fei().burn(feiBalance());
    }

    function _mintFei(uint256 amount) internal {
        fei().mint(address(this), amount);
    }
}


// File contracts/staking/IRewarder.sol

pragma solidity ^0.8.0;

interface IRewarder {
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
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


// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/staking/TribalChief.sol

pragma solidity ^0.8.0;





/// @notice migration functionality has been removed as this is only going to be used to distribute staking rewards

/// @notice The idea for this TribalChief contract is to be the owner of tribe token
/// that is deposited into this contract.
/// @notice This contract was forked from sushiswap and has been modified to distribute staking rewards in tribe.
/// All legacy code that relied on MasterChef V1 has been removed so that this contract will pay out staking rewards in tribe.
/// The assumption this code makes is that this MasterChief contract will be funded before going live and offering staking rewards.
/// This contract will not have the ability to mint tribe.
contract TribalChief is CoreRef, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;

    /// @notice Info of each users's reward debt and virtual amount
    /// stored in a single pool
    struct UserInfo {
        int128 rewardDebt;
        uint128 virtualAmount;
    }

    /// @notice Info for a deposit
    /// `amount` amount of tokens the user has provided.
    /// `virtualAmount` The virtual amount deposited. Calculated like so (multiplier * amount) / scale_factor
    /// assumption here is that we will never go over 2^128 -1
    /// on any user deposits
    struct DepositInfo {
        uint128 amount;
        uint64 unlockBlock;
        uint64 multiplier;
    }

    /// @notice Info of each pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of Tribe to distribute per block.
    struct PoolInfo {
        uint128 accTribePerShare;
        uint128 virtualTotalSupply;
        uint64 lastRewardBlock;
        uint64 allocPoint;
        bool unlocked; // this will allow an admin to unlock the pool if need be.
        // Defaults to false so that users have to respect the lockup period
    }

    /// @notice Info of each pool rewards multipliers available.
    /// map a pool id to a block lock time to a rewards multiplier
    mapping (uint256 => mapping (uint64 => uint64)) public rewardMultipliers;

    /// @notice Data needed for governor to create a new lockup period
    /// and associated reward multiplier
    struct RewardData {
        uint64 lockLength;
        uint64 rewardMultiplier;
    }

    /// @notice Address of Tribe contract.
    IERC20 public immutable TRIBE;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the token for each pool.
    IERC20[] public stakedToken;
    /// @notice Address of each `IRewarder` contract.
    IRewarder[] public rewarder;
    
    /// @notice Info of each users reward debt and virtual amount.
    /// One object is instantiated per user per pool
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice Info of each user that stakes tokens.
    mapping (uint256 => mapping (address => DepositInfo[])) public depositInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint128 public totalAllocPoint;

    /// the amount of tribe distributed per block
    uint256 private tribalChiefTribePerBlock = 1e20;
    /// variable has been made constant to cut down on gas costs
    uint256 private constant ACC_TRIBE_PRECISION = 1e12;
    /// exponent for rewards multiplier
    uint256 public constant SCALE_FACTOR = 1e18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 indexed depositID);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed stakedToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogPoolMultiplier(uint256 indexed pid, uint64 indexed lockLength, uint256 indexed multiplier);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accTribePerShare);
    /// @notice tribe withdraw event
    event TribeWithdraw(uint256 amount);
    event NewTribePerBlock(uint256 indexed amount);
    event PoolLocked(bool indexed locked, uint256 indexed pid);

    /// @param _core The Core contract address.
    /// @param _tribe The TRIBE token contract address.
    constructor(address _core, IERC20 _tribe) CoreRef(_core) {
        TRIBE = _tribe;
    }

    /// @notice Allows governor to change the amount of tribe per block
    /// make sure to call the update pool function before hitting this function
    /// this will ensure that all of the rewards a user earned previously get paid out
    /// @param newBlockReward The new amount of tribe per block to distribute
    function updateBlockReward(uint256 newBlockReward) external onlyGovernor {
        tribalChiefTribePerBlock = newBlockReward;
        emit NewTribePerBlock(newBlockReward);
    }

    /// @notice locks the pool so the users cannot withdraw until they have 
    /// locked for the lockup period
    /// @param _pid pool ID
    function lockPool(uint256 _pid) external onlyGovernor {
        PoolInfo storage pool = poolInfo[_pid];
        pool.unlocked = false;

        emit PoolLocked(true, _pid);
    }

    /// @notice unlocks the pool so that users can withdraw before their tokens
    /// have been locked for the entire lockup period
    /// @param _pid pool ID
    function unlockPool(uint256 _pid) external onlyGovernor {
        PoolInfo storage pool = poolInfo[_pid];
        pool.unlocked = true;

        emit PoolLocked(false, _pid);
    }

    /// @notice changes the pool multiplier
    /// have been locked for the entire lockup period
    /// @param _pid pool ID
    /// @param lockLength lock length to change
    /// @param newRewardsMultiplier updated rewards multiplier
    function governorAddPoolMultiplier(
        uint256 _pid,
        uint64 lockLength, 
        uint64 newRewardsMultiplier
    ) external onlyGovernor {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentMultiplier = rewardMultipliers[_pid][lockLength];
        // if the new multplier is greater than the current multiplier,
        // then, you need to unlock the pool to allow users to withdraw
        // so they can receive this larger reward
        if (newRewardsMultiplier > currentMultiplier) {
            pool.unlocked = true;
            // emit this event if we end up unlocking this pool
            emit PoolLocked(false, _pid);
        }
        rewardMultipliers[_pid][lockLength] = newRewardsMultiplier;

        emit LogPoolMultiplier(_pid, lockLength, newRewardsMultiplier);
    }

    /// @notice sends tokens back to governance treasury. Only callable by governance
    /// @param amount the amount of tokens to send back to treasury
    function governorWithdrawTribe(uint256 amount) external onlyGovernor {
        TRIBE.safeTransfer(address(core()), amount);
        emit TribeWithdraw(amount);
    }

    /// @notice Returns the number of pools.
    function numPools() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Returns the number of user deposits in a single pool.
    function openUserDeposits(uint256 pid, address user) public view returns (uint256) {
        return depositInfo[pid][user].length;
    }

    /**
     * @dev Returns the downcasted int128 from uint256, reverting on
     * overflow (when the input is greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toSigned128(uint256 a) internal pure returns (int128) {
        // cast uint256 to int256
        int256 b = a.toInt256();
        // cast down from int256 to int128
        int128 c = b.toInt128();
        return c;
    }

    function signed128ToUint256(int128 a) internal pure returns (uint256 c) {
        int256 b = int256(a);
        c = uint256(b);
    }

    /// @notice Add a new token to the pool. Can only be called by the owner.
    /// @param allocPoint AP of the new pool.
    /// @param _stakedToken Address of the ERC-20 token to stake.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param rewardData Reward Multiplier data 
    function add(
        uint128 allocPoint,
        IERC20 _stakedToken,
        IRewarder _rewarder,
        RewardData[] calldata rewardData
    ) external onlyGovernor {
        require(allocPoint > 0, "pool must have allocation points to be created");
        uint256 lastRewardBlock = block.number;
        totalAllocPoint += allocPoint;
        stakedToken.push(_stakedToken);
        rewarder.push(_rewarder);

        uint256 pid = poolInfo.length;

        require(rewardData.length != 0, "must specify rewards");
        // loop over all of the arrays of lock data and add them to the rewardMultipliers mapping
        for (uint256 i = 0; i < rewardData.length; i++) {
            // if locklength is 0 and multiplier is not equal to scale factor, revert
            if (rewardData[i].lockLength == 0) {
                require(rewardData[i].rewardMultiplier == SCALE_FACTOR, "invalid multiplier for 0 lock length");
            } else {
                // else, assert that multplier is greater than or equal to scale factor
                require(rewardData[i].rewardMultiplier >= SCALE_FACTOR, "invalid multiplier, must be above scale factor");
            }

            rewardMultipliers[pid][rewardData[i].lockLength] = rewardData[i].rewardMultiplier;
            emit LogPoolMultiplier(
                pid,
                rewardData[i].lockLength,
                rewardData[i].rewardMultiplier
            );
        }

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint.toUint64(),
            virtualTotalSupply: 0, // virtual total supply starts at 0 as there is 0 initial supply
            lastRewardBlock: lastRewardBlock.toUint64(),
            accTribePerShare: 0,
            unlocked: false
        }));
        emit LogPoolAddition(pid, allocPoint, _stakedToken, _rewarder);
    }

    /// @notice Update the given pool's TRIBE allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint128 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyGovernor {
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        require(totalAllocPoint > 0, "total allocation points cannot be 0");
        // if we are making this pool have more allocation points,
        // then we are going to unlock the pool so that users can redeposit and get the higher rewards
        if (poolInfo[_pid].allocPoint < _allocPoint) {
            poolInfo[_pid].unlocked = true;
            // emit this event if we end up unlocking this pool
            emit PoolLocked(false, _pid);
        }
        poolInfo[_pid].allocPoint = _allocPoint.toUint64();

        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }

        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Reset the given pool's TRIBE allocation to 0 and unlock the pool. Can only be called by the governor or guardian.
    /// @param _pid The index of the pool. See `poolInfo`.    
    function resetRewards(uint256 _pid) public onlyGuardianOrGovernor {
        // set the pool's allocation points to zero
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint);
        poolInfo[_pid].allocPoint = 0;
        
        // unlock all staked tokens in the pool
        poolInfo[_pid].unlocked = true;

        // erase any IRewarder mapping
        rewarder[_pid] = IRewarder(address(0));

        emit PoolLocked(false, _pid);
    }

    function _getPendingRewards(uint256 _pid, address _user) private view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accTribePerShare = pool.accTribePerShare;

        if (block.number > pool.lastRewardBlock && pool.virtualTotalSupply != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 tribeReward = (blocks * tribePerBlock() * pool.allocPoint) / totalAllocPoint;
            accTribePerShare = accTribePerShare + ((tribeReward * ACC_TRIBE_PRECISION) / pool.virtualTotalSupply);
        }

        // use the virtual amount to calculate the users share of the pool and their pending rewards
        return signed128ToUint256(
            (toSigned128(user.virtualAmount * accTribePerShare) / toSigned128(ACC_TRIBE_PRECISION)) - user.rewardDebt
        );
    }

    /// @notice View function to see all pending TRIBE on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending TRIBE reward for a given user.
    function allPendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        return _getPendingRewards(_pid, _user);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Calculates and returns the `amount` of TRIBE per block.
    function tribePerBlock() public view returns (uint256) {
        return tribalChiefTribePerBlock;
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 virtualSupply = pool.virtualTotalSupply;
            if (virtualSupply > 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 tribeReward = (blocks * tribePerBlock() * pool.allocPoint) / totalAllocPoint;
                pool.accTribePerShare = (pool.accTribePerShare + ((tribeReward * ACC_TRIBE_PRECISION) / virtualSupply)).toUint128();
            }
            pool.lastRewardBlock = block.number.toUint64();
            emit LogUpdatePool(pid, pool.lastRewardBlock, virtualSupply, pool.accTribePerShare);
        }
    }

    /// @notice Deposit tokens to earn TRIBE allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount The token amount to deposit.
    /// @param lockLength The length of time you would like to lock tokens
    function deposit(uint256 pid, uint128 amount, uint64 lockLength) public nonReentrant whenNotPaused {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage userPoolData = userInfo[pid][msg.sender];
        DepositInfo memory poolDeposit;

        uint64 multiplier = rewardMultipliers[pid][lockLength];
        require(multiplier >= SCALE_FACTOR, "invalid lock length");

        // Effects
        poolDeposit.amount = amount;
        poolDeposit.unlockBlock = (lockLength + block.number).toUint64();
        // set the multiplier here so that on withdraw we can easily reset the
        // multiplier and remove the appropriate amount of virtual liquidity
        poolDeposit.multiplier = multiplier;

        // virtual amount is calculated by taking the users total deposited balance and multiplying
        // it by the multiplier then adding it to the aggregated virtual amount
        uint128 virtualAmountDelta = ((amount * multiplier) / SCALE_FACTOR).toUint128();
        userPoolData.virtualAmount += virtualAmountDelta;
        // update reward debt after virtual amount is set by multiplying virtual amount delta by tribe per share
        userPoolData.rewardDebt += toSigned128(virtualAmountDelta * pool.accTribePerShare) / toSigned128(ACC_TRIBE_PRECISION);

        // pool virtual total supply needs to increase here
        pool.virtualTotalSupply += virtualAmountDelta;

        // add the new user struct into storage
        depositInfo[pid][msg.sender].push(poolDeposit);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, msg.sender, 0, userPoolData.virtualAmount);
        }

        stakedToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, depositInfo[pid][msg.sender].length - 1);
    }

    /// @notice Withdraw staked tokens from pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the tokens.
    function withdrawAllAndHarvest(uint256 pid, address to) external nonReentrant {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // gather and pay out users rewards
        _harvest(pid, msg.sender);
        uint128 unlockedTotalAmount = 0;
        uint128 virtualLiquidityDelta = 0;

        // iterate over all deposits this user has.
        // aggregate the deltas
        uint64 processedDeposits = 0;
        for (uint256 i = 0; i < depositInfo[pid][msg.sender].length; i++) {
            DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][i];
            // if the user has locked the tokens for at least the 
            // lockup period or the pool has been unlocked, allow 
            // user to withdraw their principle, otherwise skip this action
            if (poolDeposit.unlockBlock > block.number && pool.unlocked == false) {
                continue;
            }
            // if we get past continue, it means that we are going to process this deposit
            processedDeposits++;

            // gather the virtual and regular amount delta
            unlockedTotalAmount += poolDeposit.amount;
            virtualLiquidityDelta += ( (poolDeposit.amount * poolDeposit.multiplier) / SCALE_FACTOR ).toUint128();

            // zero out the user object as their amount will be withdrawn and all pending tribe will be paid out
            poolDeposit.unlockBlock = 0;
            poolDeposit.multiplier = 0;
            poolDeposit.amount = 0;
        }

        // Effects
        if (processedDeposits == depositInfo[pid][msg.sender].length) {
            // remove the array of deposits and userInfo struct if we were able to withdraw from all deposits
            // if we removed all liquidity, then we can just delete all the data we stored on this user
            // in both depositinfo and userinfo, which means that their reward debt, and virtual liquidity
            // are all zero'd.
            delete depositInfo[pid][msg.sender];
            delete userInfo[pid][msg.sender];
        } else {
            // if we didn't end up being able to withdraw all of the liquidity from all of our deposits
            // then we will just update for the amounts that we did remove
            // batched changes are done at the end of the function so that we don't
            // write to these storage slots multiple times
            user.virtualAmount -= virtualLiquidityDelta;
            // set the reward debt to the new virtual amount
            user.rewardDebt = toSigned128(user.virtualAmount * pool.accTribePerShare) / toSigned128(ACC_TRIBE_PRECISION);
        }

        // regardless of whether or not we removed all of this users liquidity from the pool, we will need to
        // subtract the virtual liquidity delta from the pool virtual total supply
        pool.virtualTotalSupply -= virtualLiquidityDelta;

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, to, 0, user.virtualAmount);
        }

        stakedToken[pid].safeTransfer(to, unlockedTotalAmount);

        emit Withdraw(msg.sender, pid, unlockedTotalAmount, to);
    }

    /// @notice Withdraw tokens from pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount Token amount to withdraw.
    /// @param to Receiver of the tokens.
    function withdrawFromDeposit(
        uint256 pid,
        uint128 amount,
        address to,
        uint256 index
    ) public nonReentrant {
        require(depositInfo[pid][msg.sender].length > index, "invalid index");
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][index];
        UserInfo storage user = userInfo[pid][msg.sender];

        // if the user has locked the tokens for at least the 
        // lockup period or the pool has been unlocked by the governor,
        // allow user to withdraw their principle
        require(poolDeposit.unlockBlock <= block.number || pool.unlocked == true, "tokens locked");

        uint128 virtualAmountDelta = ( ( amount * poolDeposit.multiplier ) / SCALE_FACTOR ).toUint128();

        // Effects
        poolDeposit.amount -= amount;
        user.rewardDebt = user.rewardDebt - toSigned128(virtualAmountDelta * pool.accTribePerShare) / toSigned128(ACC_TRIBE_PRECISION);
        user.virtualAmount -= virtualAmountDelta;
        pool.virtualTotalSupply -= virtualAmountDelta;

        // Interactions
        stakedToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Helper function to harvest users tribe rewards
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of TRIBE rewards.
    function _harvest(uint256 pid, address to) private {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // assumption here is that we will never go over 2^128 -1
        int256 accumulatedTribe = ( (user.virtualAmount * pool.accTribePerShare ) / ACC_TRIBE_PRECISION ).toInt256();

        // this should never happen
        require(accumulatedTribe >= 0 || (accumulatedTribe - user.rewardDebt) < 0, "negative accumulated tribe");

        uint256 pendingTribe = (accumulatedTribe - user.rewardDebt).toUint256();

        // if pending tribe is ever negative, revert as this can cause an underflow when we turn this number to a uint
        require(pendingTribe.toInt256() >= 0, "pendingTribe is less than 0");

        // Effects
        user.rewardDebt = accumulatedTribe.toInt128();

        // Interactions
        if (pendingTribe != 0) {
            TRIBE.safeTransfer(to, pendingTribe);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward( pid, msg.sender, to, pendingTribe, user.virtualAmount);
        }

        emit Harvest(msg.sender, pid, pendingTribe);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of TRIBE rewards.
    function harvest(uint256 pid, address to) public nonReentrant {
        updatePool(pid);
        _harvest(pid, to);
    }

    //////////////////////////////////////////////////////////////////////////////
    // ----> if you call emergency withdraw, you are forfeiting your rewards <----
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the deposited tokens.
    function emergencyWithdraw(uint256 pid, address to) public nonReentrant {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];

        uint128 totalUnlocked = 0;
        uint128 virtualLiquidityDelta = 0;
        for (uint256 i = 0; i < depositInfo[pid][msg.sender].length; i++) {
            DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][i];

            // if the user has locked the tokens for at least the 
            // lockup period or the pool has been unlocked, allow 
            // user to withdraw their principle
            require(poolDeposit.unlockBlock <= block.number || pool.unlocked == true, "tokens locked");

            totalUnlocked += poolDeposit.amount;

            // update the aggregated deposit virtual amount
            // update the virtualTotalSupply
            virtualLiquidityDelta += ( (poolDeposit.amount * poolDeposit.multiplier) / SCALE_FACTOR ).toUint128();
        }

        // subtract virtualLiquidity Delta from the virtual total supply of this pool
        pool.virtualTotalSupply -= virtualLiquidityDelta;

        // remove the array of deposits and userInfo struct
        delete depositInfo[pid][msg.sender];
        delete userInfo[pid][msg.sender];

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        stakedToken[pid].safeTransfer(to, totalUnlocked);
        emit EmergencyWithdraw(msg.sender, pid, totalUnlocked, to);
    }
}