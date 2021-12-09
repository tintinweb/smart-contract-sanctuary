// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../access/manager/ManagerRole.sol";
import "../access/governance/GovernanceRole.sol";

import "../util/TransferHelper.sol";

contract Treasury is Context {
    using ManagerRole for RoleStore;
    using GovernanceRole for RoleStore;

    RoleStore private _s;

    modifier onlyManagerOrGovernance() {
        require(
            _s.isManager(_msgSender()) || _s.isGovernor(_msgSender()),
            "Treasury::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    // expose manager and governance getters
    function isManager(address account) external view returns (bool) {
        return _s.isManager(account);
    }

    function isGovernor(address account) external view returns (bool) {
        return _s.isGovernor(account);
    }

    constructor() {
        _s.initializeManagerRole(_msgSender());
    }

    function transfer( address token, address to, uint256 amount ) public onlyManagerOrGovernance {
        TransferHelper.safeTransfer(token, to, amount);
    }

    function transferNative( address to, uint256 value ) public onlyManagerOrGovernance {
        TransferHelper.safeTransferNative(to, value);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../../util/ContextLib.sol";

library ManagerRole {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* EVENTS */

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    /* MODIFIERS */

    modifier onlyUninitialized(RoleStore storage s) {
        require(!s.initialized, "ManagerRole::onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized(RoleStore storage s) {
        require(s.initialized, "ManagerRole::onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager(RoleStore storage s) {
        require(s.managers.has(ContextLib._msgSender()), "ManagerRole::onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHODS */
    
    // NOTE: call only in calling contract context initialize function(), do not expose anywhere else
    function initializeManagerRole(
        RoleStore storage s,
        address account
    )
        external
        onlyUninitialized(s)
     {
        _addManager(s, account);
        s.initialized = true;
    }

    /* EXTERNAL STATE CHANGE METHODS */
    
    function addManager(
        RoleStore storage s,
        address account
    )
        external
        onlyManager(s)
        onlyInitialized(s)
    {
        _addManager(s, account);
    }

    function renounceManager(
        RoleStore storage s
    )
        external
        onlyInitialized(s)
    {
        _removeManager(s, ContextLib._msgSender());
    }

    /* EXTERNAL GETTER METHODS */

    function isManager(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
         return s.managers.has(account);
    }

    /* INTERNAL LOGIC METHODS */

    function _addManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.safeRemove(account);
        emit ManagerRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../manager/ManagerRole.sol";
import "../../util/ContextLib.sol";

library GovernanceRole {

    /* LIBRARY USAGE */
    
    using Roles for Role;
    using ManagerRole for RoleStore;

    /* EVENTS */

    event GovernanceAccountAdded(address indexed account, address indexed governor);
    event GovernanceAccountRemoved(address indexed account, address indexed governor);

    /* MODIFIERS */

    modifier onlyManagerOrGovernance(RoleStore storage s, address account) {
        require(
            s.isManager(account) || _isGovernor(s, account), 
            "GovernanceRole::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    /* EXTERNAL STATE CHANGE METHODS */

    /* a manager or existing governance account can add new governance accounts */
    function addGovernor(
        RoleStore storage s,
        address governor
    )
        external
        onlyManagerOrGovernance(s, ContextLib._msgSender())
    {
        _addGovernor(s, governor);
    }

    /* an Governance account can renounce thier own governor status */
    function renounceGovernance(
        RoleStore storage s
    )
        external
    {
        _removeGovernor(s, ContextLib._msgSender());
    }

    /* manger accounts can remove governance accounts */
    function removeGovernor(
        RoleStore storage s,
        address governor
    )
        external
    {
        require(s.isManager(ContextLib._msgSender()), "GovernanceRole::removeGovernance: NOT_MANAGER_ACCOUNT");
        _removeGovernor(s, governor);
    }

    /* EXTERNAL GETTER METHODS */

    function isGovernor(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
        return _isGovernor(s, account);
    }

    /* INTERNAL LOGIC METHODS */

    function _isGovernor(
        RoleStore storage s,
        address account
    )
        internal
        view
        returns (bool)
    {
        return s.governance.has(account);
    }

    function _addGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0), 
            "GovernanceRole::_addGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );
        
        s.governance.add(governor);

        emit GovernanceAccountAdded(ContextLib._msgSender(), governor);
    }

    function _removeGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0),
            "GovernanceRole::_removeGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );

        s.governance.remove(governor);

        emit GovernanceAccountRemoved(ContextLib._msgSender(), governor);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.2 <0.9.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferNative: TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./base/RoleStruct.sol";

struct RoleStore {
    bool initialized;
    Role managers;
    Role governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "./RoleStruct.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles.has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !has(role, account),
            "Roles.add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            has(role, account),
            "Roles.safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            atLeastOneBearer(numberOfBearers),
            "Roles.safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

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
library ContextLib {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* STRUCTS */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}