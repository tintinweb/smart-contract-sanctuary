//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";
import "./Median.sol";

contract ACPIFour is ACPI {
    // Address => _currentRound => _currentTurn => didBet
    mapping(address => mapping(uint16 => mapping(uint16 => bool)))
        private _hasAlreadyBet;

    uint8 private _priceIncrease;

    uint16 private _currentTurn;

    uint56 private _rewardPerTurn;
    uint56 private _rewardLeft;

    uint256 private _price;
    uint256 private _lastPrice;
    uint256 private _defaultPrice;

    constructor() ACPI(msg.sender, 4) {
        _priceIncrease = 60; // 60% increase
        _defaultPrice = 0.1 ether;
        _roundTime = 60 * 5; // seconds between each turn
        _totalRound = 10;
        _rewardPerTurn = 100;
        _rewardLeft = _rewardPerTurn;
        _price = _defaultPrice;
        _lastPrice = _defaultPrice;
    }

    /**
     * @dev Price per token in native currency
     */
    function setDefaultPrice(uint256 newValue) external onlyModerator {
        _defaultPrice = newValue;
    }

    /**
     * @dev Reward for each turn in number of tokens
     */
    function setReward(uint56 newValue) external onlyModerator {
        _rewardPerTurn = newValue;
        _rewardLeft = newValue;
    }

    /**
     * @dev Price increase between each turn in %
     */
    function setPriceIncrease(uint8 newValue) external onlyModerator {
        _priceIncrease = newValue;
    }

    function defaultPrice() external view returns (uint256) {
        return _defaultPrice;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function priceIncrease() external view returns (uint8) {
        return _priceIncrease;
    }

    function rewardLeft() external view returns (uint256) {
        return _rewardLeft;
    }

    function rewardPerTurn() external view returns (uint256) {
        return _rewardPerTurn;
    }

    function currentTurn() external view returns (uint256) {
        return _currentTurn;
    }

    function buy() external payable onlyCurrentACPI {
        require(_currentRound < _totalRound, "BUY: All rounds have been done");

        require(
            !_hasAlreadyBet[msg.sender][_currentRound][_currentTurn],
            "You can only bet once per turn"
        );

        require(msg.value == _price, "BUY: value must match price");

        require(
            _rewardLeft > 0,
            "BUY: All tokens have been sold for this turn"
        );

        _hasAlreadyBet[msg.sender][_currentRound][_currentTurn] = true;
        _pendingWins[msg.sender] += 1 ether;
        _rewardLeft -= 1;

        emit Bid(msg.sender, _price);
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external override onlyModerator onlyCurrentACPI {
        require(_currentRound < _totalRound, "All rounds have been done");

        if (_rewardLeft > 0) {
            _priceHistory.push(
                (_lastPrice *
                    _rewardPerTurn +
                    _price *
                    (_rewardPerTurn - _rewardLeft)) /
                    (2 * _rewardPerTurn - _rewardLeft)
            );
            _currentRound += 1;
            _currentTurn = 0;
            _price = _defaultPrice;
            _lastPrice = _defaultPrice;
        } else {
            _lastPrice = _price;
            _currentTurn += 1;
            _price += (_price * _priceIncrease) / 100;
        }

        emit RoundWin(_price);

        _rewardLeft = _rewardPerTurn;

        if (_currentRound == _totalRound) setAcpiPrice();
    }

    function setAcpiPrice() internal override {
        if (_priceHistory.length == 0) return;

        _acpiPrice = Median.from(_priceHistory);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IACPIMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    /**
     * @dev Setup Abstract contract must be called only in the child contract
     */
    constructor(address acpiMaster, uint8 acpiNumber)
    {
        _acpiMaster = IACPIMaster(acpiMaster);
        _acpiNumber = acpiNumber;
    }

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
    function resetAccount(address account) external virtual onlyACPIMaster returns (bool) {
        _pendingWins[account] = 0;
        return true;
    }

    /**
     * @dev Emitted when a user win a round of any ACPI
     * `amount` is the amount of Governance Token RealT awarded
     */
    event RoundWin(uint256 amount);

    /**
     * @dev Emitted when a user bid
     */
    event Bid(address user, uint256 amount);

    /**
     * @dev Withdraw native currency {onlyACPIMaster}
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        if (address(this).balance > amount && recipient != address(0))
            recipient.transfer(amount);
        return true;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual onlyACPIMaster returns (bool) {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

library Median {
    function _swap(
        uint256[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function _sort(
        uint256[] memory array,
        uint256 begin,
        uint256 end
    ) private pure {
        if (begin < end) {
            uint256 j = begin;
            uint256 pivot = array[j];
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    _swap(array, i, ++j);
                }
            }
            _swap(array, begin, j);
            _sort(array, begin, j);
            _sort(array, j + 1, end);
        }
    }

    function from(uint256[] memory array) internal pure returns (uint256) {
        _sort(array, 0, array.length);
        return
            array.length % 2 == 0
                ? Math.average(
                    array[array.length / 2 - 1],
                    array[array.length / 2]
                )
                : array[array.length / 2];
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

   function withdrawTokens(address payable vault, uint256 amount) external;

   function withdraw(address payable vault, uint256[4] calldata amounts) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}