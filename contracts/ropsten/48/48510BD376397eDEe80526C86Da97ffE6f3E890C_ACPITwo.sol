//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";

contract ACPITwo is ACPI {
    mapping(address => uint256) private _balance;
    uint256 private _acpiPrice;

    mapping(address => uint256) public pendingReturns;

    mapping(address => uint256) public pendingWins;

    constructor() {
        _setupAbstract(msg.sender, 2);
        _roundTime = 60 * 5;
        _totalRound = 10;
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external override onlyModerator {
        _currentRound += 1;

        if (_currentRound == _totalRound) setAcpiPrice();
    }

    /**
     * @dev Set target user wins to 0 {onlyTokenContract}
     * note called after a claimTokens from the parent contract
     */
    function resetAccount(address account) external override onlyTokenContract {
        pendingReturns[account] = 0;
        pendingWins[account] = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRealT.sol";

/**
 * @dev Abstract contract of the ACPI standard by realt.co
 */

abstract contract ACPI {
    IRealT internal _realtERC20;
    uint256[] internal _priceHistory;

    uint256 internal _currentRound;
    uint256 internal _totalRound;
    uint256 internal _roundTime;

    uint256 public acpiPrice;

    uint8 internal _acpiNumber;

   modifier onlyCurrentACPI() {
        require(_realtERC20.getACPI() == _acpiNumber, "Only Current ACPI Method");
        _;
    }

   modifier onlyTokenContract() {
        require(_realtERC20.hasRole(_realtERC20.TOKEN_CONTRACT(), msg.sender), "Only Token Contract Method");
        _;
    }

    modifier onlyModerator() {
        require(_realtERC20.hasRole(_realtERC20.ACPI_MODERATOR(), msg.sender), "Only ACPI Moderator Method");
        _;
    }

    /**
     * @dev Setup Abstract contract must be called only in the child contract
     */
    function _setupAbstract(address realtERC20, uint8 acpiNumber) virtual internal {
        _realtERC20 = IRealT(realtERC20);
        _acpiNumber = acpiNumber;
    }

    /**
     * @dev Returns the current round.
     */
    function currentRound() virtual external view returns (uint256) {
        return _currentRound;
    }

    /**
     * @dev Returns the amount of rounds per ACPI.
     */
    function totalRound() virtual external view returns (uint256) {
        return _totalRound;
    }

    /**
     * @dev Returns the time between two consecutive round in seconds
     */
    function roundTime() external virtual view returns (uint256) {
        return _roundTime;
    }

    /**
     * @dev Set totalRound value
     */
    function setTotalRound(uint256 newValue)
        external
        virtual
        onlyModerator
        returns (uint256)
    {
        return _totalRound = newValue;
    }

    /**
     * @dev Set time between two consecutive round in seconds
     */
    function setRoundTime(uint256 newValue)
        external
        virtual
        onlyModerator
        returns (uint256)
    {
        return _roundTime = newValue;
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
        uint256 sum;
        for (uint256 i; i < _priceHistory.length; i++) {
            sum += _priceHistory[i];
        }
        acpiPrice = sum / _priceHistory.length;
    }

    /**
     * @dev Set target user wins to 0 {onlyTokenContract}
     * note called after a claimTokens from the parent contract
     */
    function resetAccount(address account) external virtual;

    /**
     * @dev Emitted when a user win a round of any ACPI
     * `amount` is the amount of Governance Token RealT awarded
     */
    event RoundWin(address indexed winner, uint8 indexed acpiNumber, uint256 amount);

    /**
     * @dev Withdraw native currency {onlyTokenContract}
     */
    function withdraw(address recipient) external virtual onlyTokenContract {
        payable(recipient).transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev Interface of the Real Token
 */

interface IRealT is IERC20, IAccessControl {
    function TOKEN_ADMIN() external view returns (bytes32);

    function ACPI_MODERATOR() external view returns (bytes32);

    function ACPI_CONTRACT() external view returns (bytes32);

    function TOKEN_CONTRACT() external view returns (bytes32);

    function getACPI() external view returns (uint8);

    function setACPI(uint8 currentACPI) external;

    function batchTransfer(
        address[] calldata sender,
        address[] calldata recipient,
        uint256[] calldata amount
    ) external;

    function mint(address account, uint256 amount) external;

    function batchMint(address[] calldata account, uint256[] calldata amount)
        external;

    function burn(address account, uint256 amount) external;

    function batchBurn(address[] calldata account, uint256[] calldata amount)
        external;

    function getACPIWins() external view returns (uint256);

    function getACPIReturns() external view returns (uint256);

    function claimTokens() external;

    function withdraw(address vault) external;
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