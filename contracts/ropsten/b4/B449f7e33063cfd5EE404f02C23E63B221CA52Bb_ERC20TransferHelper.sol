// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZoraProposalManager} from "../ZoraProposalManager.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

/// @title ERC-20 Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides modules the ability to transfer ZORA user ERC-20s with their permission
contract ERC20TransferHelper is BaseTransferHelper {
    using SafeERC20 for IERC20;

    constructor(address _approvalsManager) BaseTransferHelper(_approvalsManager) {}

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) public onlyApprovedModule(_from) {
        IERC20(_token).safeTransferFrom(_from, _to, _value);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract accepts proposals and registers new modules, granting them access to the ZORA Module Approval Manager
contract ZoraProposalManager {
    enum ProposalStatus {
        Nonexistent,
        Pending,
        Passed,
        Failed
    }
    /// @notice A Proposal object that tracks a proposal and its status
    /// @member proposer The address that created the proposal
    /// @member status The status of the proposal (see ProposalStatus)
    struct Proposal {
        address proposer;
        ProposalStatus status;
    }

    /// @notice The registrar address that can register, or cancel
    address public registrar;
    /// @notice A mapping of module addresses to proposals
    mapping(address => Proposal) public proposedModuleToProposal;

    event ModuleProposed(address indexed contractAddress, address indexed proposer);
    event ModuleRegistered(address indexed contractAddress);
    event ModuleCanceled(address indexed contractAddress);
    event RegistrarChanged(address indexed newRegistrar);

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "ZPM::onlyRegistrar must be registrar");
        _;
    }

    /// @param _registrarAddress The initial registrar for the manager
    constructor(address _registrarAddress) {
        require(_registrarAddress != address(0), "ZPM::must set registrar to non-zero address");

        registrar = _registrarAddress;
    }

    /// @notice Returns true if the module has been registered
    /// @param _proposalImpl The address of the proposed module
    /// @return True if the module has been registered, false otherwise
    function isPassedProposal(address _proposalImpl) public view returns (bool) {
        return proposedModuleToProposal[_proposalImpl].status == ProposalStatus.Passed;
    }

    /// @notice Creates a new proposal for a module
    /// @param _impl The address of the deployed module being proposed
    function proposeModule(address _impl) public {
        require(proposedModuleToProposal[_impl].proposer == address(0), "ZPM::proposeModule proposal already exists");
        require(_impl != address(0), "ZPM::proposeModule proposed contract cannot be zero address");

        Proposal memory proposal = Proposal({proposer: msg.sender, status: ProposalStatus.Pending});
        proposedModuleToProposal[_impl] = proposal;

        emit ModuleProposed(_impl, msg.sender);
    }

    /// @notice Registers a proposed module
    /// @param _proposalAddress The address of the proposed module
    function registerModule(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::registerModule can only register pending proposals");

        proposal.status = ProposalStatus.Passed;

        emit ModuleRegistered(_proposalAddress);
    }

    /// @notice Cancels a proposed module
    /// @param _proposalAddress The address of the proposed module
    function cancelProposal(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::cancelProposal can only cancel pending proposals");

        proposal.status = ProposalStatus.Failed;

        emit ModuleCanceled(_proposalAddress);
    }

    /// @notice Sets the registrar for this manager
    /// @param _registrarAddress the address of the new registrar
    function setRegistrar(address _registrarAddress) public onlyRegistrar {
        require(_registrarAddress != address(0), "ZPM::setRegistrar must set registrar to non-zero address");
        registrar = _registrarAddress;

        emit RegistrarChanged(_registrarAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ZoraModuleApprovalsManager} from "../ZoraModuleApprovalsManager.sol";

/// @title Base Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides shared utility for ZORA transfer helpers
contract BaseTransferHelper {
    ZoraModuleApprovalsManager approvalsManager;

    /// @param _approvalsManager The ZORA Module Approvals Manager to use as a reference for transfer permissions
    constructor(address _approvalsManager) {
        require(_approvalsManager != address(0), "must set approvals manager to non-zero address");

        approvalsManager = ZoraModuleApprovalsManager(_approvalsManager);
    }

    // Only allows the method to continue if the caller is an approved zora module
    modifier onlyApprovedModule(address _from) {
        require(approvalsManager.isModuleApproved(_from, msg.sender), "module has not been approved by user");

        _;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ZoraProposalManager} from "./ZoraProposalManager.sol";

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract allows users to explicitly allow modules access to the ZORA transfer helpers on their behalf
contract ZoraModuleApprovalsManager {
    /// @notice The address of the proposal manager, manages allowed modules
    ZoraProposalManager public proposalManager;

    /// @notice Mapping of specific approvals for (module, user) pairs in the ZORA registry
    mapping(address => mapping(address => bool)) public userApprovals;

    event ModuleApprovalSet(address indexed user, address indexed module, bool approved);
    event AllModulesApprovalSet(address indexed user, bool approved);

    /// @param _proposalManager The address of the ZORA proposal manager
    constructor(address _proposalManager) {
        proposalManager = ZoraProposalManager(_proposalManager);
    }

    /// @notice Returns true if the user has approved a given module, false otherwise
    /// @param _user The user to check approvals for
    /// @param _module The module to check approvals for
    /// @return True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module) external view returns (bool) {
        return userApprovals[_user][_module];
    }

    /// @notice Allows a user to set the approval for a given module
    /// @param _moduleAddress The module to approve
    /// @param _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _moduleAddress, bool _approved) public {
        require(proposalManager.isPassedProposal(_moduleAddress), "ZMAM::module must be approved");

        userApprovals[msg.sender][_moduleAddress] = _approved;

        emit ModuleApprovalSet(msg.sender, _moduleAddress, _approved);
    }

    /// @notice Sets approvals for multiple modules at once
    /// @param _moduleAddresses The list of module addresses to set approvals for
    /// @param _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(address[] memory _moduleAddresses, bool _approved) public {
        for (uint256 i = 0; i < _moduleAddresses.length; i++) {
            setApprovalForModule(_moduleAddresses[i], _approved);
        }
    }
}