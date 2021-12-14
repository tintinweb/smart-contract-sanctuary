//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";

contract ACPIThree is ACPI {
    uint256 private _bidAmount;

    address[] private _roundBidders;

    // Address => _currentRound => didBet
    mapping(address => mapping(uint16 => bool)) private _hasAlreadyBet;

    constructor() {
        _setupAbstract(msg.sender, 3);
        _roundTime = 60 * 5;
        _totalRound = 10;
        _bidAmount = 250 gwei;
    }

    /**
     * @dev Returns the value each user needs to bet to enter a round.
     */
    function bidAmount() external view returns (uint256) {
        return _bidAmount;
    }

    /**
     * @dev Set the bid amount value {onlyModerator}
     */
    function setBidAmount(uint256 newValue) external onlyModerator {
        _bidAmount = newValue;
    }

    /**
     * @dev bid to enter the round {onlyCurrentACPI}
     */
    function bid() external payable onlyCurrentACPI {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(
            msg.value == _bidAmount,
            "Bid value should match exactly bid amount"
        );
        require(
            !_hasAlreadyBet[msg.sender][_currentRound],
            "You already bet this round"
        );

        _roundBidders.push(msg.sender);
        _hasAlreadyBet[msg.sender][_currentRound] = true;

        emit Bid(msg.sender, _bidAmount);
    }

    /**
     * @dev Start round of ACPI ending the last one. {onlyModerator}
     */
    function startRound() external override onlyModerator onlyCurrentACPI {
        require(_currentRound < _totalRound, "All rounds have been done");

        if (_roundBidders.length > 0) {
            _priceHistory.push(_roundBidders.length * _bidAmount);
            for (uint256 i = 0; i < _roundBidders.length; i++) {
                _pendingWins[_roundBidders[i]] +=
                    1 ether /
                    _roundBidders.length;
            }
            delete _roundBidders;

            emit RoundWin(_roundBidders.length * _bidAmount);
        }
        _currentRound += 1;
        if (_currentRound == _totalRound) setAcpiPrice();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IACPIMaster.sol";

/**
 * @dev Abstract contract of the ACPI standard by realt.co
 */

abstract contract ACPI {
    IACPIMaster internal _acpiMaster;
    uint256[] internal _priceHistory;

    // User Address => User balance
    mapping(address => uint256) internal _pendingWins;

    uint16 internal _currentRound;
    uint16 internal _totalRound;
    uint256 internal _roundTime;

    uint256 internal _acpiPrice;

    uint8 internal _acpiNumber;

    modifier onlyCurrentACPI() {
        require(
            _acpiMaster.getACPI() == _acpiNumber,
            "Only Current ACPI Method"
        );
        _;
    }

    modifier onlyACPIMaster() {
        require(
            _acpiMaster.hasRole(_acpiMaster.ACPI_MASTER(), msg.sender),
            "Only ACPI Master Method"
        );
        _;
    }

    modifier onlyModerator() {
        require(
            _acpiMaster.hasRole(_acpiMaster.ACPI_MODERATOR(), msg.sender),
            "Only ACPI Moderator Method"
        );
        _;
    }

    /**
     * @dev Setup Abstract contract must be called only in the child contract
     */
    function _setupAbstract(address realtERC20, uint8 acpiNumber)
        internal
        virtual
    {
        _acpiMaster = IACPIMaster(realtERC20);
        _acpiNumber = acpiNumber;
    }

    /**
     * @dev Returns the current round.
     */
    function currentRound() external view virtual returns (uint16) {
        return _currentRound;
    }

    /**
     * @dev Returns the amount of rounds per ACPI.
     */
    function totalRound() external view virtual returns (uint16) {
        return _totalRound;
    }

    /**
     * @dev Returns the time between two consecutive round in seconds
     */
    function roundTime() external view virtual returns (uint256) {
        return _roundTime;
    }

    /**
     * @dev Returns the price of the current ACPI
     */
    function acpiPrice() external view virtual returns (uint256) {
        return _acpiPrice;
    }

    /**
     * @dev Returns the pendingWins of {account}
     * pendingWins can be withdrawed at the end of all APCIs
     */
    function pendingWins(address account)
        external
        view
        virtual
        returns (uint256)
    {
        return _pendingWins[account];
    }

    /**
     * @dev Set totalRound value
     */
    function setTotalRound(uint16 newValue) external virtual onlyModerator {
        _totalRound = newValue;
    }

    /**
     * @dev Set time between two consecutive round in seconds
     */
    function setRoundTime(uint256 newValue) external virtual onlyModerator {
        _roundTime = newValue;
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external virtual onlyModerator onlyCurrentACPI {
        _currentRound += 1;

        // Implement ACPI logic

        if (_currentRound == _totalRound) setAcpiPrice();
    }

    /**
     * @dev Set the ACPI price when all the rounds have been done
     */
    function setAcpiPrice() internal virtual {
        if (_priceHistory.length == 0) return;
        uint256 sum = 0;
        for (uint256 i = 0; i < _priceHistory.length; i++) {
            sum += _priceHistory[i] / _priceHistory.length;
        }
        _acpiPrice = sum;
    }

    /**
     * @dev Set target user wins to 0 {onlyACPIMaster}
     * note called after a claimTokens from the parent contract
     */
    function resetAccount(address account) external virtual onlyACPIMaster {
        _pendingWins[account] = 0;
    }

    /**
     * @dev Emitted when a user win a round of any ACPI
     * `amount` is the amount of Governance Token RealT awarded
     */
    event RoundWin(uint256 indexed amount);

    /**
     * @dev Emitted when a user bid
     */
    event Bid(address indexed user, uint256 indexed amount);

    /**
     * @dev Withdraw native currency {onlyACPIMaster}
     */
    function withdraw(address recipient, uint256 amount)
        external
        virtual
        onlyACPIMaster
    {
        if (address(this).balance > amount && recipient != address(0))
            payable(recipient).transfer(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Real Token
 */

import "@openzeppelin/contracts/access/IAccessControl.sol";


interface IACPIMaster is IAccessControl {
    
    event ACPIChanged(uint8 indexed newAcpi);

    function ACPI_MASTER() external view returns (bytes32);

    function ACPI_MODERATOR() external view returns (bytes32);

    function initialTokenPrice() external view returns (uint256);

    function getACPI() external view returns (uint8);

    function setACPI(uint8 newACPI) external;

    function getACPIWins() external view returns (uint256);

    function getACPIReturns() external view returns (uint256);

    function tokenToClaim() external view returns (uint256);

    function claimTokens() external;

    function withdrawAll(address vault) external;

   function withdrawTokens(address vault) external;

   function withdraw(address vault, uint256[4] calldata amounts) external;
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