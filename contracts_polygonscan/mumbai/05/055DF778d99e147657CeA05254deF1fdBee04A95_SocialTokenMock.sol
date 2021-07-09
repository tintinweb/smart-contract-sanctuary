// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./StreamingLibrary.sol";
import "./StreamingManager.sol";
import "./Structs.sol";

/**
 * @title Streaming extension for an ERC20 token
 * @author Eric Nordelo
 **/
abstract contract ERC20Streamable is ERC20, AccessControl {
    using Counters for Counters.Counter;
    using StreamingLibrary for Streaming;

    Counters.Counter private _streamingIds;

    bytes32 public constant ADMIN = keccak256("admin");

    address public streamingManagerAddress;
    StreamingManager private _streamingManager;

    mapping(address => mapping(address => bool)) private _openStreamings;
    mapping(uint256 => Streaming) private _streamings;
    mapping(address => FlowInfo) private _incomingFlows;
    mapping(address => FlowInfo) private _outgoingFlows;

    event StreamingCreated(address indexed from, address indexed to, uint256 indexed id, uint64 endingDate);
    event StreamingStopped(address indexed from, address indexed to);
    event StreamingUpdated(address indexed from, address indexed to, uint256 indexed id, uint64 endingDate);

    constructor() {
        // The super admin is the deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
    }

    /**
     * @notice Allows admins to set the Streaming Manager contract address
     * @param _streamingManagerAddress The address of the contract
     **/
    function setStreamingManagerAddress(address _streamingManagerAddress) external onlyRole(ADMIN) {
        streamingManagerAddress = _streamingManagerAddress;
        _streamingManager = StreamingManager(_streamingManagerAddress);
    }

    modifier isValidStreaming(Streaming memory _streaming) {
        require(
            keccak256(abi.encodePacked((_streaming.stype))) == keccak256(abi.encodePacked(("classic"))),
            "Invalid type"
        );
        require(_streaming.senderAddress == msg.sender, "Invalid sender");
        require(_streaming.receiverAddress != address(0), "Invalid receiver");
        require(_streaming.amountPerSecond > 0, "Invalid amount per second");
        _;
    }

    function checkOnlySenderOrAdmin(address _sender) internal view {
        require(_sender == msg.sender || hasRole(ADMIN, msg.sender), "Permission denied");
    }

    /**
     * @notice Create a streaming between to addresses
     * @param _streaming The data of the streaming
     * @return newStreamingId The id of the new streaming
     **/
    function createStreaming(Streaming memory _streaming)
        public
        isValidStreaming(_streaming)
        returns (uint256 newStreamingId)
    {
        require(block.timestamp < _streaming.endingDate, "Invalid ending date");
        require(
            !_openStreamings[_streaming.senderAddress][_streaming.receiverAddress],
            "Can't open two streams to same address"
        );
        _streaming.startingDate = uint64(block.timestamp);

        uint256 totalAmount = _streaming.amountPerSecond * (_streaming.endingDate - _streaming.startingDate);

        // should have enough balance to open the streaming
        require(totalAmount <= balanceOf(msg.sender), "Not enough balance");

        _streamingIds.increment();
        newStreamingId = _streamingIds.current();

        _streamings[newStreamingId] = _streaming;
        _openStreamings[_streaming.senderAddress][_streaming.receiverAddress] = true;

        // use the library to create streaming
        _streaming.createStreaming(_incomingFlows, _outgoingFlows);

        // transfer the total amount to the manager
        transfer(streamingManagerAddress, totalAmount);

        emit StreamingCreated(
            _streaming.senderAddress,
            _streaming.receiverAddress,
            newStreamingId,
            _streaming.endingDate
        );
    }

    /**
     * @notice Update a streaming between to addresses
     * @param _streamingId The id of the streaming to update
     * @param _streamingUpdateRequest The data of the streaming update
     */
    function updateStreaming(uint256 _streamingId, StreamingUpdateRequest calldata _streamingUpdateRequest)
        external
    {
        Streaming memory streaming = getStreaming(_streamingId);

        if (
            streaming.startingDate >= _streamingUpdateRequest.endingDate ||
            _streamingUpdateRequest.endingDate <= block.timestamp ||
            streaming.senderAddress != msg.sender ||
            _streamingUpdateRequest.amountPerSecond <= 0
        ) {
            revert("Invalid request");
        }

        if (streaming.endingDate <= block.timestamp) {
            _stop(streaming, _streamingId);
        } else {
            (uint256 quantityToPayToReceiver, uint256 currentHolding, uint256 expectedHolding) = streaming
            .updateStreaming(
                _streamingId,
                _incomingFlows,
                _outgoingFlows,
                _streamings,
                _streamingUpdateRequest
            );

            // make the transfers (the payment and the return)
            if (quantityToPayToReceiver > 0) {
                _streamingManager.transfer(streaming.receiverAddress, quantityToPayToReceiver);
            }
            // update streaming manager balance
            if (currentHolding > expectedHolding) {
                _streamingManager.transfer(streaming.senderAddress, currentHolding - expectedHolding);
            } else if (currentHolding < expectedHolding) {
                transfer(streamingManagerAddress, expectedHolding - currentHolding);
            }

            emit StreamingUpdated(
                streaming.senderAddress,
                streaming.receiverAddress,
                _streamingId,
                _streamingUpdateRequest.endingDate
            );
        }
    }

    /**
     * @notice Stop a streaming between to addresses
     * @dev Protected against reentracy by check-effect-interactions pattern
     * @param _streamingId The id of the streaming to stop
     */
    function stopStreaming(uint256 _streamingId) public {
        Streaming memory streaming = getStreaming(_streamingId);

        checkOnlySenderOrAdmin(streaming.senderAddress);

        _stop(streaming, _streamingId);
    }

    /**
     * @notice Getter for a streaming
     * @param _streamingId The id of the streaming
     * @return streaming The data of the streaming
     */
    function getStreaming(uint256 _streamingId) public view returns (Streaming memory streaming) {
        streaming = _streamings[_streamingId];
        require(streaming.amountPerSecond > 0, "Unexisting streaming");
    }

    /**
     * @notice Returns the balance of an account with the streaming info
     * @param account The address of the account to check
     * @return The current balance with streamings
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 notYetPaidIncomingFlow = _incomingFlows[account].totalPreviousValueGenerated -
            _incomingFlows[account].totalPreviousValueTransfered;
        notYetPaidIncomingFlow +=
            (block.timestamp - _incomingFlows[account].flow.startingDate) *
            _incomingFlows[account].flow.amountPerSecond;
        uint256 notYetPaidOutgoingFlow = _outgoingFlows[account].totalPreviousValueGenerated -
            _outgoingFlows[account].totalPreviousValueTransfered;
        notYetPaidOutgoingFlow +=
            (block.timestamp - _outgoingFlows[account].flow.startingDate) *
            _outgoingFlows[account].flow.amountPerSecond;

        return super.balanceOf(account) + notYetPaidIncomingFlow - notYetPaidOutgoingFlow;
    }

    function _stop(Streaming memory streaming, uint256 _streamingId) internal {
        // update the balance of the receiver (pay what you owe)

        // this must be true always
        assert(streaming.startingDate < streaming.endingDate);

        (uint256 quantityToPay, uint256 quantityToReturn) = streaming.stopStreaming(
            _streamingId,
            _incomingFlows,
            _outgoingFlows,
            _streamings,
            _openStreamings
        );

        // make the transfers (the payment and the return)
        if (quantityToPay > 0) {
            _streamingManager.transfer(streaming.receiverAddress, quantityToPay);
        }
        if (quantityToReturn > 0) {
            _streamingManager.transfer(streaming.receiverAddress, quantityToReturn);
        }

        emit StreamingStopped(streaming.senderAddress, streaming.receiverAddress);
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal view virtual override {
        // address 0 is minting
        if (from != address(0) && super.balanceOf(from) < amount) {
            revert("Real balance (wihtout streamings) not enough to transfer");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20Streamable.sol";

contract SocialTokenMock is ERC20, ERC20Streamable, Ownable {
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
        // default decimals: 18
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    // allow to increment the totalSupply by minting
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view override(ERC20, ERC20Streamable) returns (uint256) {
        return ERC20Streamable.balanceOf(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override(ERC20Streamable, ERC20) {
        ERC20Streamable._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Streamable.sol";
import "./StreamingManager.sol";
import "./Structs.sol";

/**
 * @title Library for streamings
 * @author Eric Nordelo
 */
library StreamingLibrary {
    /**
     * @notice Helper for streaming creation
     * @param _streaming The streaming being created
     * @param _incomingFlows The incoming flows mapping
     * @param _outgoingFlows The outgoing flows mapping
     */
    function createStreaming(
        Streaming memory _streaming,
        mapping(address => FlowInfo) storage _incomingFlows,
        mapping(address => FlowInfo) storage _outgoingFlows
    ) external {
        // update flows
        _incomingFlows[_streaming.receiverAddress].flow.amountPerSecond += _streaming.amountPerSecond;
        _outgoingFlows[_streaming.senderAddress].flow.amountPerSecond += _streaming.amountPerSecond;

        // update flow infos
        FlowInfo memory incomingFlowInfo = _incomingFlows[_streaming.receiverAddress];
        FlowInfo memory outgoingFlowInfo = _outgoingFlows[_streaming.senderAddress];

        if (incomingFlowInfo.flow.startingDate == 0) {
            _incomingFlows[_streaming.receiverAddress].flow.startingDate = _streaming.startingDate;
        } else {
            _incomingFlows[_streaming.receiverAddress].totalPreviousValueGenerated +=
                (_streaming.startingDate - incomingFlowInfo.flow.startingDate) *
                incomingFlowInfo.flow.amountPerSecond;

            _incomingFlows[_streaming.receiverAddress].flow.startingDate = _streaming.startingDate;
        }
        if (outgoingFlowInfo.flow.startingDate == 0) {
            _outgoingFlows[_streaming.senderAddress].flow.startingDate = _streaming.startingDate;
        } else {
            _outgoingFlows[_streaming.senderAddress].totalPreviousValueGenerated +=
                (_streaming.startingDate - outgoingFlowInfo.flow.startingDate) *
                outgoingFlowInfo.flow.amountPerSecond;

            _outgoingFlows[_streaming.senderAddress].flow.startingDate = _streaming.startingDate;
        }
    }

    /**
     * @notice Helper for streaming updating
     * @param streaming The streaming being updated
     * @param _streamingId The id of the streaming
     * @param _incomingFlows The incoming flows mapping
     * @param _outgoingFlows The outgoing flows mapping
     * @param _streamings The streamings mapping
     * @param _streamingUpdateRequest The data for the update
     * @return quantityToPayToReceiver
     * @return currentHolding
     * @return expectedHolding
     */
    function updateStreaming(
        Streaming memory streaming,
        uint256 _streamingId,
        mapping(address => FlowInfo) storage _incomingFlows,
        mapping(address => FlowInfo) storage _outgoingFlows,
        mapping(uint256 => Streaming) storage _streamings,
        StreamingUpdateRequest calldata _streamingUpdateRequest
    )
        external
        returns (
            uint256 quantityToPayToReceiver,
            uint256 currentHolding,
            uint256 expectedHolding
        )
    {
        if (block.timestamp > streaming.startingDate) {
            uint256 intervalTranscursed = block.timestamp - streaming.startingDate;
            quantityToPayToReceiver = ((streaming.amountPerSecond * intervalTranscursed));
            streaming.startingDate = uint64(block.timestamp);
        }

        // calculate how much should streaming manager hold now and update
        currentHolding =
            (streaming.amountPerSecond * (streaming.endingDate - streaming.startingDate)) -
            quantityToPayToReceiver;
        expectedHolding =
            _streamingUpdateRequest.amountPerSecond *
            (_streamingUpdateRequest.endingDate - streaming.startingDate);

        // update flow infos
        FlowInfo memory incomingFlowInfo = _incomingFlows[streaming.receiverAddress];
        FlowInfo memory outgoingFlowInfo = _outgoingFlows[streaming.senderAddress];

        _incomingFlows[streaming.receiverAddress].totalPreviousValueGenerated +=
            (block.timestamp - incomingFlowInfo.flow.startingDate) *
            incomingFlowInfo.flow.amountPerSecond;

        _incomingFlows[streaming.receiverAddress].flow.startingDate = uint64(block.timestamp);

        _outgoingFlows[streaming.senderAddress].totalPreviousValueGenerated +=
            (block.timestamp - outgoingFlowInfo.flow.startingDate) *
            outgoingFlowInfo.flow.amountPerSecond;

        _outgoingFlows[streaming.senderAddress].flow.startingDate = uint64(block.timestamp);

        if (quantityToPayToReceiver > 0) {
            _incomingFlows[streaming.receiverAddress].totalPreviousValueTransfered += quantityToPayToReceiver;
            _outgoingFlows[streaming.senderAddress].totalPreviousValueTransfered += quantityToPayToReceiver;
        }

        // update flows
        _incomingFlows[streaming.receiverAddress].flow.amountPerSecond =
            _incomingFlows[streaming.receiverAddress].flow.amountPerSecond -
            streaming.amountPerSecond +
            _streamingUpdateRequest.amountPerSecond;
        _outgoingFlows[streaming.senderAddress].flow.amountPerSecond =
            _outgoingFlows[streaming.senderAddress].flow.amountPerSecond -
            streaming.amountPerSecond +
            _streamingUpdateRequest.amountPerSecond;

        // update the streaming
        _streamings[_streamingId].startingDate = uint64(block.timestamp);
        _streamings[_streamingId].amountPerSecond = _streamingUpdateRequest.amountPerSecond;
        _streamings[_streamingId].endingDate = _streamingUpdateRequest.endingDate;
    }

    /**
     * @notice Helper for streaming stopping
     * @param streaming The streaming being stopped
     * @param _streamingId The id of the streaming
     * @param _incomingFlows The incoming flows mapping
     * @param _outgoingFlows The outgoing flows mapping
     * @param _streamings The streamings mapping
     * @param _openStreamings The open streamings mapping
     * @return quantityToPay
     * @return quantityToReturn
     */

    function stopStreaming(
        Streaming memory streaming,
        uint256 _streamingId,
        mapping(address => FlowInfo) storage _incomingFlows,
        mapping(address => FlowInfo) storage _outgoingFlows,
        mapping(uint256 => Streaming) storage _streamings,
        mapping(address => mapping(address => bool)) storage _openStreamings
    ) external returns (uint256 quantityToPay, uint256 quantityToReturn) {
        if (block.timestamp > streaming.startingDate) {
            uint256 totalAmount = streaming.amountPerSecond * (streaming.endingDate - streaming.startingDate);

            uint256 addTillDate = streaming.endingDate < block.timestamp
                ? streaming.endingDate
                : block.timestamp;
            uint256 intervalTranscursed = addTillDate - streaming.startingDate;

            quantityToPay = ((streaming.amountPerSecond * intervalTranscursed));
            quantityToReturn = totalAmount - quantityToPay;
        }

        // stop the streaming
        delete _streamings[_streamingId];
        _openStreamings[streaming.senderAddress][streaming.receiverAddress] = false;

        // update flow infos
        FlowInfo memory incomingFlowInfo = _incomingFlows[streaming.receiverAddress];
        FlowInfo memory outgoingFlowInfo = _outgoingFlows[streaming.senderAddress];

        _incomingFlows[streaming.receiverAddress].totalPreviousValueGenerated +=
            (block.timestamp - incomingFlowInfo.flow.startingDate) *
            incomingFlowInfo.flow.amountPerSecond;

        _incomingFlows[streaming.receiverAddress].flow.startingDate = uint64(block.timestamp);

        _outgoingFlows[streaming.senderAddress].totalPreviousValueGenerated +=
            (block.timestamp - outgoingFlowInfo.flow.startingDate) *
            outgoingFlowInfo.flow.amountPerSecond;

        _outgoingFlows[streaming.senderAddress].flow.startingDate = uint64(block.timestamp);

        // update flows
        _incomingFlows[streaming.receiverAddress].flow.amountPerSecond -= streaming.amountPerSecond;
        _outgoingFlows[streaming.senderAddress].flow.amountPerSecond -= streaming.amountPerSecond;

        if (quantityToPay > 0) {
            _incomingFlows[streaming.receiverAddress].totalPreviousValueTransfered += quantityToPay;
            _outgoingFlows[streaming.senderAddress].totalPreviousValueTransfered += quantityToPay;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Streaming manager
 * @author Eric Nordelo
 * @notice Arbitrage between the streaming sender and receivers (manage the payments)
 */
contract StreamingManager {
    address public immutable erc20StreamableAddress;

    constructor(address _erc20StreamableAddress) {
        erc20StreamableAddress = _erc20StreamableAddress;
    }

    function transfer(address _to, uint256 _amount) external {
        require(msg.sender == erc20StreamableAddress, "Invalid sender");
        ERC20 token = ERC20(erc20StreamableAddress);
        token.transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Streaming {
    string stype;
    address senderAddress;
    address receiverAddress;
    uint256 amountPerSecond;
    uint64 startingDate;
    uint64 endingDate;
}

struct StreamingUpdateRequest {
    uint256 amountPerSecond;
    uint64 endingDate;
}

struct Flow {
    uint256 amountPerSecond;
    uint64 startingDate;
}

struct FlowInfo {
    Flow flow;
    uint256 totalPreviousValueGenerated;
    uint256 totalPreviousValueTransfered;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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