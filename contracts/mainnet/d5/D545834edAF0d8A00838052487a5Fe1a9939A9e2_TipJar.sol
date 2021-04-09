// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt ([email protected]).
*/

import "./lib/0.8/AccessControlUpgradeable.sol";
import "./lib/0.8/CheckAndSend.sol";

/**
 * @title TipJar
 * @dev Allows suppliers to create a tip that gets distributed to miners + the network
 */
contract TipJar is AccessControlUpgradeable, CheckAndSend {

    /// @notice TipJar Admin role
    bytes32 public constant TIP_JAR_ADMIN_ROLE = keccak256("TIP_JAR_ADMIN_ROLE");

    /// @notice Fee setter role
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    /// @notice Network fee (measured in bips: 10,000 bips = 1% of contract balance)
    uint32 public networkFee;

    /// @notice Network fee output address
    address public networkFeeCollector;

    /// @notice Miner split
    struct Split {
        address splitTo;
        uint32 splitPct;
    }

    /// @notice Miner split mapping
    mapping (address => Split) public minerSplits;

    /// @notice Fee set event
    event FeeSet(uint32 indexed newFee, uint32 indexed oldFee);

    /// @notice Fee collector set event
    event FeeCollectorSet(address indexed newCollector, address indexed oldCollector);

    /// @notice Miner split updated event
    event MinerSplitUpdated(address indexed miner, address indexed newSplitTo, address indexed oldSplitTo, uint32 newSplit, uint32 oldSplit);

    /// @notice Tip event
    event Tip(address indexed miner, address indexed tipper, uint256 tipAmount, uint256 splitAmount, uint256 feeAmount, address feeCollector);

    /// @notice modifier to restrict functions to admins
    modifier onlyAdmin() {
        require(hasRole(TIP_JAR_ADMIN_ROLE, msg.sender), "Caller must have TIP_JAR_ADMIN_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to miners or admin
    modifier onlyMinerOrAdmin(address miner) {
        require(msg.sender == miner || hasRole(TIP_JAR_ADMIN_ROLE, msg.sender), "Caller must be miner or have TIP_JAR_ADMIN_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to fee setters
    modifier onlyFeeSetter() {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "Caller must have FEE_SETTER_ROLE role");
        _;
    }

    /// @notice Initializes contract, setting admin roles + network fee
    /// @param _tipJarAdmin admin of tip pool
    /// @param _feeSetter fee setter address
    /// @param _networkFeeCollector address that collects network fees
    /// @param _networkFee % of fee collected by the network
    function initialize(
        address _tipJarAdmin,
        address _feeSetter,
        address _networkFeeCollector,
        uint32 _networkFee
    ) public initializer {
        _setRoleAdmin(TIP_JAR_ADMIN_ROLE, TIP_JAR_ADMIN_ROLE);
        _setRoleAdmin(FEE_SETTER_ROLE, TIP_JAR_ADMIN_ROLE);
        _setupRole(TIP_JAR_ADMIN_ROLE, _tipJarAdmin);
        _setupRole(FEE_SETTER_ROLE, _feeSetter);
        networkFeeCollector = _networkFeeCollector;
        emit FeeCollectorSet(_networkFeeCollector, address(0));
        networkFee = _networkFee;
        emit FeeSet(_networkFee, 0);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /// @notice Fallback function to allow contract to accept ETH
    fallback() external payable {}

    /**
     * @notice Check that contract call results in specific 32 bytes value, then transfer ETH
     * @param _target target contract
     * @param _payload contract call bytes
     * @param _resultMatch result to match
     */
    function check32BytesAndSend(
        address _target,
        bytes calldata _payload,
        bytes32 _resultMatch
    ) external payable {
        _check32Bytes(_target, _payload, _resultMatch);
    }

    /**
     * @notice Check that contract call results in specific 32 bytes value, then tip
     * @param _target target contract
     * @param _payload contract call bytes
     * @param _resultMatch result to match
     */
    function check32BytesAndTip(
        address _target,
        bytes calldata _payload,
        bytes32 _resultMatch
    ) external payable {
        _check32Bytes(_target, _payload, _resultMatch);
        tip();
    }

    /**
     * @notice Check that multiple contract calls result in specific 32 bytes value, then transfer ETH
     * @param _targets target contracts
     * @param _payloads contract call bytes
     * @param _resultMatches results to match
     */
    function check32BytesAndSendMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) external payable {
        _check32BytesMulti(_targets, _payloads, _resultMatches);
    }

    /**
     * @notice Check that multiple contract calls result in specific 32 bytes value, then tip
     * @param _targets target contracts
     * @param _payloads contract call bytes
     * @param _resultMatches results to match
     */
    function check32BytesAndTipMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) external payable {
        _check32BytesMulti(_targets, _payloads, _resultMatches);
        tip();
    }

    /**
     * @notice Check that contract call results in specific bytes value, then transfer ETH
     * @param _target target contract
     * @param _payload contract call bytes
     * @param _resultMatch result to match
     */
    function checkBytesAndSend(
        address _target,
        bytes calldata _payload,
        bytes calldata _resultMatch
    ) external payable {
        _checkBytes(_target, _payload, _resultMatch);
    }

    /**
     * @notice Check that contract call results in specific bytes value, then tip
     * @param _target target contract
     * @param _payload contract call bytes
     * @param _resultMatch result to match
     */
    function checkBytesAndTip(
        address _target,
        bytes calldata _payload,
        bytes calldata _resultMatch
    ) external payable {
        _checkBytes(_target, _payload, _resultMatch);
        tip();
    }

    /**
     * @notice Check that multiple contract calls result in specific bytes value, then transfer ETH
     * @param _targets target contracts
     * @param _payloads contract call bytes
     * @param _resultMatches results to match
     */
    function checkBytesAndSendMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) external payable {
        _checkBytesMulti(_targets, _payloads, _resultMatches);
    }

    /**
     * @notice Check that multiple contract calls result in specific bytes value, then tip
     * @param _targets target contracts
     * @param _payloads contract call bytes
     * @param _resultMatches results to match
     */
    function checkBytesAndTipMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) external payable {
        _checkBytesMulti(_targets, _payloads, _resultMatches);
        tip();
    }

    /**
     * @notice Distributes any ETH in contract to relevant parties
     */
    function tip() public payable {
        uint256 tipAmount;
        uint256 feeAmount;
        uint256 splitAmount;
        if (networkFee > 0) {
            feeAmount = (address(this).balance * networkFee) / 1000000;
            (bool feeSuccess, ) = networkFeeCollector.call{value: feeAmount}("");
            require(feeSuccess, "Could not collect fee");
        }

        if(minerSplits[block.coinbase].splitPct > 0) {
            splitAmount = (address(this).balance * minerSplits[block.coinbase].splitPct) / 1000000;
            (bool splitSuccess, ) = minerSplits[block.coinbase].splitTo.call{value: splitAmount}("");
            require(splitSuccess, "Could not split");
        }

        if (address(this).balance > 0) {
            tipAmount = address(this).balance;
            (bool success, ) = block.coinbase.call{value: tipAmount}("");
            require(success, "Could not collect ETH");
        }
        
        emit Tip(block.coinbase, msg.sender, tipAmount, splitAmount, feeAmount, networkFeeCollector);
    }

    /**
     * @notice Admin function to set network fee
     * @param newFee new fee
     */
    function setFee(uint32 newFee) external onlyFeeSetter {
        require(newFee <= 1000000, ">100%");
        emit FeeSet(newFee, networkFee);
        networkFee = newFee;
    }

    /**
     * @notice Admin function to set fee collector address
     * @param newCollector new fee collector address
     */
    function setFeeCollector(address newCollector) external onlyAdmin {
        emit FeeCollectorSet(newCollector, networkFeeCollector);
        networkFeeCollector = newCollector;
    }

    /**
     * @notice Update split % and split to address for given miner
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     */
    function updateMinerSplit(
        address minerAddress, 
        address splitTo, 
        uint32 splitPct
    ) external onlyMinerOrAdmin(minerAddress) {
        Split memory oldSplit = minerSplits[minerAddress];
        address oldSplitTo = oldSplit.splitTo;
        uint32 oldSplitPct = oldSplit.splitPct;
        minerSplits[minerAddress] = Split({
            splitTo: splitTo,
            splitPct: splitPct
        });
        emit MinerSplitUpdated(minerAddress, splitTo, oldSplitTo, splitPct, oldSplitPct);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Flashbots: Scott Bigelow ([email protected]).
*/

contract CheckAndSend {
    function _check32BytesMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) internal view {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _check32Bytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
    }

    function _checkBytesMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) internal view {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _checkBytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
    }

    function _check32Bytes(
        address _target,
        bytes memory _payload,
        bytes32 _resultMatch
    ) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(_response.length >= 32, "response less than 32 bytes");
        bytes32 _responseScalar;
        assembly {
            _responseScalar := mload(add(_response, 0x20))
        }
        require(_responseScalar == _resultMatch, "response mismatch");
    }

    function _checkBytes(
        address _target,
        bytes memory _payload,
        bytes memory _resultMatch
    ) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(
            keccak256(_resultMatch) == keccak256(_response),
            "response bytes mismatch"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 99999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}