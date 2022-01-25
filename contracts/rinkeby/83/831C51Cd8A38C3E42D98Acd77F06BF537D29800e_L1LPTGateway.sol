// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ControlledGateway
 * @notice Base Contract for both L1 and L2 LPT gateways. Provides AccessControl.
 * Gateways can be paused by the governor to stop outgoing token migrations
 */
contract ControlledGateway is AccessControl, Pausable {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    address public immutable l1Lpt;
    address public immutable l2Lpt;

    constructor(address _l1Lpt, address _l2Lpt) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);

        l1Lpt = _l1Lpt;
        l2Lpt = _l2Lpt;
    }

    function pause() external onlyRole(GOVERNOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(GOVERNOR_ROLE) {
        _unpause();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1LPTGateway {
    event DepositInitiated(
        address _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _sequenceNumber,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _exitNum,
        uint256 _amount
    );

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external;

    // if token is not supported this should return 0x0 address
    function calculateL2TokenAddress(address l1Token)
        external
        view
        returns (address);

    // used by router
    function counterpartGateway() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBridge} from "../../arbitrum/IBridge.sol";
import {IInbox} from "../../arbitrum/IInbox.sol";
import {IOutbox} from "../../arbitrum/IOutbox.sol";

abstract contract L1ArbitrumMessenger {
    IInbox public immutable inbox;

    event TxToL2(
        address indexed from,
        address indexed to,
        uint256 indexed seqNum,
        bytes data
    );

    constructor(address _inbox) {
        inbox = IInbox(_inbox);
    }

    modifier onlyL2Counterpart(address l2Counterpart) {
        // a message coming from the counterpart gateway was executed by the bridge
        address bridge = inbox.bridge();
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = IOutbox(IBridge(bridge).activeOutbox())
            .l2ToL1Sender();
        require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        return
            sendTxToL2(
                target,
                from,
                msg.value,
                0, // we always assume that l2CallValue = 0
                maxSubmissionCost,
                maxGas,
                gasPriceBid,
                data
            );
    }

    function sendTxToL2(
        address target,
        address from,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes memory data
    ) internal returns (uint256) {
        uint256 seqNum = inbox.createRetryableTicket{value: _l1CallValue}(
            target,
            _l2CallValue,
            maxSubmissionCost,
            from,
            from,
            maxGas,
            gasPriceBid,
            data
        );
        emit TxToL2(from, target, seqNum, data);
        return seqNum;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ControlledGateway} from "../../ControlledGateway.sol";
import {L1ArbitrumMessenger} from "./L1ArbitrumMessenger.sol";
import {IL1LPTGateway} from "./IL1LPTGateway.sol";
import {IL2LPTGateway} from "../../L2/gateway/IL2LPTGateway.sol";

interface TokenLike {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);
}

interface IMinter {
    function bridgeMint(address _to, uint256 _amount) external;
}

/**
 * @title L1LPTGateway
 * @notice Manages inbound and outbound transfers of LPT between L1 and Arbitrum Rollup
 * @dev the contract can be paused by the governor which will prevent any outbound transfers
 * but pausing the contract does not affect inbound transfers (tokens coming from L2)
 */
contract L1LPTGateway is IL1LPTGateway, ControlledGateway, L1ArbitrumMessenger {
    address public immutable l1Router;
    address public immutable l1LPTEscrow;
    address public l2Counterpart;
    address public minter;

    constructor(
        address _l1Router,
        address _l1LPTEscrow,
        address _l1Lpt,
        address _l2Lpt,
        address _inbox
    ) ControlledGateway(_l1Lpt, _l2Lpt) L1ArbitrumMessenger(_inbox) {
        l1Router = _l1Router;
        l1LPTEscrow = _l1LPTEscrow;
    }

    /**
     * @notice Sets address of companion L2LPTGateway
     * @dev Only address with the governor role is allowed to change the value of l2Counterpart
     * @param _l2Counterpart L2 Address of the counterpart
     */
    function setCounterpart(address _l2Counterpart)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        l2Counterpart = _l2Counterpart;
    }

    /**
     * @notice Sets address of Minter
     * @dev Only address with the governor role is allowed to change the value of minter
     * @param _minter L1 Address of minter
     */
    function setMinter(address _minter) external onlyRole(GOVERNOR_ROLE) {
        minter = _minter;
    }

    /**
     * @notice Creates and sends a retryable ticket to migrate LPT to L2 using arbitrum Inbox.
     * The tokens are sent to the Escrow contract for safekeeping until they are withdrawn
     * The ticket must be redeemed on L2 to receive tokens at the specified address.
     * @dev maxGas and gasPriceBid must be set using arbitrum's Inbox.estimateRetryableTicket method.
     * @param _l1Token L1 Address of LPT
     * @param _to Recepient address on L2
     * @param _amount Amount of tokens to tranfer
     * @param _maxGas Gas limit for L2 execution of the ticket
     * @param _gasPriceBid Price per gas on L2
     * @param _data Encoded maxSubmission cost and sender address along with additional calldata
     * @return seqNum Sequence number of the retryable ticket created by Inbox
     */
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable override whenNotPaused returns (bytes memory) {
        require(_l1Token == l1Lpt, "TOKEN_NOT_LPT");

        // nested scope to avoid stack too deep errors
        address from;
        uint256 seqNum;
        bytes memory extraData;
        {
            uint256 maxSubmissionCost;
            (from, maxSubmissionCost, extraData) = parseOutboundData(_data);
            require(extraData.length == 0, "CALL_HOOK_DATA_NOT_ALLOWED");

            // transfer tokens to escrow
            TokenLike(_l1Token).transferFrom(from, l1LPTEscrow, _amount);

            bytes memory outboundCalldata = getOutboundCalldata(
                _l1Token,
                from,
                _to,
                _amount,
                extraData
            );

            seqNum = sendTxToL2(
                l2Counterpart,
                from,
                maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                outboundCalldata
            );
        }

        emit DepositInitiated(_l1Token, from, _to, seqNum, _amount);

        return abi.encode(seqNum);
    }

    /**
     * @notice Receives withdrawn token amount from L2
     * The equivalent tokens are released from the Escrow contract and sent to the destination
     * In case the escrow doesn't have enough balance, new tokens are minted
     * @dev can only accept txs coming directly from L2 LPT Gateway
     * @param l1Token L1 Address of LPT
     * @param from Address of the sender
     * @param to Recepient address on L1
     * @param amount Amount of tokens transferred
     * @param data Contains exitNum which is always set to 0
     */
    function finalizeInboundTransfer(
        address l1Token,
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external override onlyL2Counterpart(l2Counterpart) {
        require(l1Token == l1Lpt, "TOKEN_NOT_LPT");
        (uint256 exitNum, ) = abi.decode(data, (uint256, bytes));

        uint256 escrowBalance = TokenLike(l1Token).balanceOf(l1LPTEscrow);

        // mint additional tokens if requested amount exceeds escrowed amount
        if (amount <= escrowBalance) {
            TokenLike(l1Token).transferFrom(l1LPTEscrow, to, amount);
        } else {
            if (escrowBalance > 0) {
                TokenLike(l1Token).transferFrom(l1LPTEscrow, to, escrowBalance);
            }
            IMinter(minter).bridgeMint(to, amount - escrowBalance);
        }

        emit WithdrawalFinalized(l1Token, from, to, exitNum, amount);
    }

    /**
     * @notice decodes calldata required for migration of tokens
     * @dev data must include maxSubmissionCost, extraData can be left empty
     * @param data encoded callhook data
     * @return from sender of the tx
     * @return maxSubmissionCost base ether value required to keep retyrable ticket alive
     * @return extraData any other data sent to L2
     */
    function parseOutboundData(bytes memory data)
        internal
        view
        returns (
            address from,
            uint256 maxSubmissionCost,
            bytes memory extraData
        )
    {
        if (msg.sender == l1Router) {
            // router encoded
            (from, extraData) = abi.decode(data, (address, bytes));
        } else {
            from = msg.sender;
            extraData = data;
        }
        // user encoded
        (maxSubmissionCost, extraData) = abi.decode(
            extraData,
            (uint256, bytes)
        );
    }

    /**
     * @notice returns address of L2 LPT Gateway
     */
    function counterpartGateway() external view override returns (address) {
        return l2Counterpart;
    }

    /**
     * @notice returns address of L2 version of LPT
     */
    function calculateL2TokenAddress(address l1Token)
        external
        view
        override
        returns (address)
    {
        if (l1Token != l1Lpt) {
            return address(0);
        }

        return l2Lpt;
    }

    /**
     * @notice Creates calldata required to create a retryable ticket
     * @dev encodes the target function with its params which
     * will be called on L2 when the retryable ticket is redeemed
     */
    function getOutboundCalldata(
        address l1Token,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public pure returns (bytes memory outboundCalldata) {
        bytes memory emptyBytes = "";

        outboundCalldata = abi.encodeWithSelector(
            IL2LPTGateway.finalizeInboundTransfer.selector,
            l1Token,
            from,
            to,
            amount,
            abi.encode(emptyBytes, data)
        );

        return outboundCalldata;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL2LPTGateway {
    event DepositFinalized(
        address indexed _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawalInitiated(
        address _l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _l2ToL1Id,
        uint256 _exitNum,
        uint256 _amount
    );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external;

    // if token is not supported this should return 0x0 address
    function calculateL2TokenAddress(address _l1Token)
        external
        view
        returns (address);

    // used by router
    function counterpartGateway() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData)
        external
        returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        returns (uint256);

    function bridge() external view returns (address);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(
        bytes calldata sendsData,
        uint256[] calldata sendLengths
    ) external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}