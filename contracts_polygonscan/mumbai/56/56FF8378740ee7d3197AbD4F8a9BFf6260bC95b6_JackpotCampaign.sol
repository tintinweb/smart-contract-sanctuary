/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
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
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

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
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

contract AccessControlLocal is AccessControl {
    bytes32 private constant USER_ROLE = keccak256("USER_ROLE");

    function _accessControlInit(address root) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, root);
    }

    function addUser(address userToAuthorize) public onlyAdmin {
        grantRole(USER_ROLE, userToAuthorize);
    }

    function removeUser(address userToRemove) external onlyAdmin {
        revokeRole(USER_ROLE, userToRemove);
    }

    // Required modifiers
    modifier onlyWhitelisted() {
        require(
            hasRole(USER_ROLE, msg.sender),
            "Must be in whitelisted list by admin"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Must be in admin list"
        );
        _;
    }
}

library Library {
    struct data {
        uint256 amount;
        bool isValue;
    }
}

contract JackpotCampaign is AccessControlLocal {
    using Library for Library.data;

    struct Transaction {
        address _contractAddress;
        address payable _address;
        uint256 _amount;
    }

    struct BalanceView {
        address _address;
        uint256 _balance;
    }

    address[] balanceIndices;
    mapping(address => Library.data) private balances;

    event AmountBalanceChanged(address user, uint256 newAmount);
    event MoneyInContract(uint256 balanceContract);

    constructor(address root, address firstUser) {
        _accessControlInit(root);
        if (firstUser != address(0x0)) {
            addUser(firstUser);
        }
    }

    receive() external payable {
        _addMoneyBalanceRoutine(msg.sender, msg.value, true);
    }

    function getAllBalances()
        external
        view
        onlyAdmin
        returns (BalanceView[] memory)
    {
        BalanceView[] memory balancesView = new BalanceView[](
            balanceIndices.length
        );
        for (uint256 i = 0; i < balanceIndices.length; i++) {
            address _address = balanceIndices[i];
            balancesView[i] = BalanceView(_address, balances[_address].amount);
        }
        return balancesView;
    }

    //-----------------------------
    //USER OPS
    function getAmount(address _address) public view returns (uint256) {
        uint256 _amount = balances[_address].amount;
        return _amount;
    }

    function deposit() external payable onlyWhitelisted returns (uint256) {
        require(msg.value > 0, "Only positive numbers");
        _addMoneyBalanceRoutine(msg.sender, msg.value, true);
        return balances[msg.sender].amount;
    }

    //Private functions
    function _addMoneyBalanceRoutine(
        address _address,
        uint256 _amount,
        bool isEvent
    ) private {
        if (balances[_address].isValue) {
            balances[_address].amount = balances[_address].amount + _amount;
        } else {
            balances[_address].amount = _amount;
            balances[_address].isValue = true;
            balanceIndices.push(_address);
        }
        if (isEvent) {
            emit AmountBalanceChanged(_address, balances[_address].amount);
            emit MoneyInContract(address(this).balance);
        }
    }

    function _sendMoney(
        address from,
        address payable recipient,
        uint256 amount
    ) private {
        require(
            balances[from].amount >= amount,
            "You cannot send money user doesn't have"
        );
        recipient.transfer(amount);
        balances[from].amount -= amount;
        emit AmountBalanceChanged(from, balances[from].amount);
    }
}