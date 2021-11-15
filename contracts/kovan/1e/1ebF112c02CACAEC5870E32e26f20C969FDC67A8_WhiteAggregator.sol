// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Aggregator is AccessControl {
    struct OracleInfo {
        uint256 withdrawable; // amount of withdrawable LINKs
        address admin; // current oracle admin
    }

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // role allowed to submit the data
    uint256 public minConfirmations; // minimal required confimations
    uint256 public allocatedFunds; // LINK's amount payed to oracles
    uint256 public availableFunds; // LINK's amount available to be payed to oracles
    uint256 public payment; // payment for one submission
    IERC20 public link; // LINK's token address
    mapping(address => OracleInfo) public getOracleInfo; // oracle address => oracle details

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "onlyAdmin: bad role");
        _;
    }
    modifier onlyOracle {
        require(hasRole(ORACLE_ROLE, msg.sender), "onlyOracle: bad role");
        _;
    }

    /* PUBLIC */

    /// @dev Constructor that initializes the most important configurations.
    /// @param _minConfirmations Minimal required confirmations.
    /// @param _payment Oracle reward.
    /// @param _link Link token to pay to oracles.
    constructor(
        uint256 _minConfirmations,
        uint128 _payment,
        IERC20 _link
    ) {
        minConfirmations = _minConfirmations;
        payment = _payment;
        link = _link;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
    }

    /// @dev Withdraws oracle reward.
    /// @param _oracle Oracle address.
    /// @param _recipient Recepient reward.
    /// @param _amount Amount to withdraw.
    function withdrawPayment(
        address _oracle,
        address _recipient,
        uint256 _amount
    ) external {
        require(
            getOracleInfo[_oracle].admin == msg.sender,
            "withdrawPayment: only callable by admin"
        );
        uint256 available = getOracleInfo[_oracle].withdrawable;
        require(
            available >= _amount,
            "withdrawPayment: insufficient withdrawable funds"
        );
        getOracleInfo[_oracle].withdrawable = available - _amount;
        allocatedFunds -= _amount;
        assert(link.transfer(_recipient, _amount));
    }

    /// @dev Updates available rewards to be distributed.
    function updateAvailableFunds() public {
        availableFunds = link.balanceOf(address(this)) - allocatedFunds;
    }

    function onTokenTransfer(
        address,
        uint256,
        bytes calldata _data
    ) external {
        require(msg.sender == address(link), "onTokenTransfer: not the Link");
        require(_data.length == 0, "transfer doesn't accept calldata");
        updateAvailableFunds();
    }

    /* ADMIN */

    /// @dev Withdraws available LINK's.
    /// @param _recipient Recepient reward.
    /// @param _amount Amount to withdraw.
    function withdrawFunds(address _recipient, uint256 _amount)
        external
        onlyAdmin()
    {
        require(
            uint256(availableFunds) >= _amount,
            "insufficient reserve funds"
        );
        require(
            link.transfer(_recipient, _amount),
            "withdrawFunds: transfer failed"
        );
        updateAvailableFunds();
    }

    /// @dev Sets minimal required confirmations.
    /// @param _minConfirmations Minimal required confirmations.
    function setMinConfirmations(uint256 _minConfirmations) external onlyAdmin {
        minConfirmations = _minConfirmations;
    }

    /// @dev Sets new oracle reward.
    /// @param _payment Oracle reward.
    function setPayment(uint128 _payment) external onlyAdmin {
        payment = _payment;
    }

    /// @dev Add new oracle.
    /// @param _oracle Oracle address.
    /// @param _admin Admin address.
    function addOracle(address _oracle, address _admin) external onlyAdmin {
        grantRole(ORACLE_ROLE, _oracle);
        getOracleInfo[_oracle].admin = _admin;
    }

    /// @dev Remove oracle.
    /// @param _oracle Oracle address.
    function removeOracle(address _oracle) external onlyAdmin {
        revokeRole(ORACLE_ROLE, _oracle);
    }

    /* INTERNAL */

    /// @dev Assess teh oracle rewards.
    /// @param _oracle Oracle address.
    function _payOracle(address _oracle) internal {
        availableFunds -= payment;
        allocatedFunds += payment;
        getOracleInfo[_oracle].withdrawable += payment;
    }

    /* VIEW */

    /// @dev Withdraws oracle reward.
    /// @param _oracle Oracle address.
    /// @return Oracle rewards.
    function withdrawablePayment(address _oracle)
        external
        view
        returns (uint256)
    {
        return getOracleInfo[_oracle].withdrawable;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Aggregator.sol";
import "../interfaces/IWhiteAggregator.sol";

contract WhiteAggregator is Aggregator, IWhiteAggregator {
    struct SubmissionInfo {
        bool confirmed; // whether is confirmed
        uint256 confirmations; // received confirmations count
        mapping(address => bool) hasVerified; // verifier => has already voted
    }

    mapping(bytes32 => SubmissionInfo) public getMintInfo; // mint id => submission info
    mapping(bytes32 => SubmissionInfo) public getBurntInfo; // burnt id => submission info

    event Confirmed(bytes32 submissionId, address operator); // emitted once the submission is confirmed
    event SubmissionApproved(bytes32 submissionId); // emitted once the submission is confirmed

    /// @dev Constructor that initializes the most important configurations.
    /// @param _minConfirmations Minimal required confirmations.
    /// @param _payment Oracle reward.
    /// @param _link Link token to pay to oracles.
    constructor(
        uint256 _minConfirmations,
        uint128 _payment,
        IERC20 _link
    ) Aggregator(_minConfirmations, _payment, _link) {}

    /// @dev Confirms the mint request.
    /// @param _mintId Submission identifier.
    function submitMint(bytes32 _mintId) external override onlyOracle {
        SubmissionInfo storage mintInfo = getMintInfo[_mintId];
        require(!mintInfo.hasVerified[msg.sender], "submit: submitted already");
        mintInfo.confirmations += 1;
        mintInfo.hasVerified[msg.sender] = true;
        if (mintInfo.confirmations >= minConfirmations) {
            mintInfo.confirmed = true;
            emit SubmissionApproved(_mintId);
        }
        _payOracle(msg.sender);
        emit Confirmed(_mintId, msg.sender);
    }

    /// @dev Confirms the burnnt request.
    /// @param _burntId Submission identifier.
    function submitBurn(bytes32 _burntId) external override onlyOracle {
        SubmissionInfo storage burnInfo = getBurntInfo[_burntId];
        require(!burnInfo.hasVerified[msg.sender], "submit: submitted already");
        burnInfo.confirmations += 1;
        burnInfo.hasVerified[msg.sender] = true;
        if (burnInfo.confirmations >= minConfirmations) {
            burnInfo.confirmed = true;
            emit SubmissionApproved(_burntId);
        }
        emit Confirmed(_burntId, msg.sender);
        _payOracle(msg.sender);
    }

    /// @dev Returns whether mint request is confirmed.
    /// @param _mintId Submission identifier.
    /// @return Whether mint request is confirmed.
    function isMintConfirmed(bytes32 _mintId)
        external
        view
        override
        returns (bool)
    {
        return getMintInfo[_mintId].confirmed;
    }

    /// @dev Returns whether burnnt request is confirmed.
    /// @param _burntId Submission identifier.
    /// @return Whether burnnt request is confirmed.
    function isBurntConfirmed(bytes32 _burntId)
        external
        view
        override
        returns (bool)
    {
        return getBurntInfo[_burntId].confirmed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWhiteDebridge.sol";

interface IWhiteAggregator {
    function submitMint(bytes32 _mintId) external;

    function submitBurn(bytes32 _burntId) external;

    function isMintConfirmed(bytes32 _mintId) external view returns (bool);

    function isBurntConfirmed(bytes32 _burntId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IWhiteDebridge {
    function send(
        bytes32 _debridgeId,
        address _receiver,
        uint256 _amount,
        uint256 _chainIdTo
    ) external payable;

    function mint(
        bytes32 _debridgeId,
        address _receiver,
        uint256 _amount,
        uint256 _nonce
    ) external;

    function burn(
        bytes32 _debridgeId,
        address _receiver,
        uint256 _amount
    ) external;

    function claim(
        bytes32 _debridgeId,
        address _receiver,
        uint256 _amount,
        uint256 _nonce
    ) external;

    function addNativeAsset(
        address _tokenAddress,
        uint256 _minAmount,
        uint256 _transferFee,
        uint256 _minReserves,
        uint256[] memory _supportedChainIds
    ) external;

    function setChainIdSupport(
        bytes32 _debridgeId,
        uint256 _chainId,
        bool _isSupported
    ) external;

    function addExternalAsset(
        address _tokenAddress,
        uint256 _chainId,
        uint256 _minAmount,
        uint256 _transferFee,
        uint256 _minReserves,
        uint256[] memory _supportedChainIds,
        string memory _name,
        string memory _symbol
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

