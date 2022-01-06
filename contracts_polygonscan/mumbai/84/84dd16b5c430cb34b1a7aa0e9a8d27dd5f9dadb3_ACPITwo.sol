//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";

contract ACPITwo is ACPI {
    // Address => _currentRound => balance
    mapping(address => mapping(uint16 => uint256)) private _balance;

    uint8 private _rewardMultiplicator;

    address[] private _bidders;

    uint256 private _minBid;
    uint256 private _roundPot;
    uint256 private _reward;

    constructor() ACPI(msg.sender, 2) {
        _minBid = 250 gwei;
        _reward = 1 ether;
        _rewardMultiplicator = 0;
    }

    /**
     * @dev bid to enter the round {onlyCurrentACPI}
     */
    function bid(uint16 targetRound)
        external
        override
        payable
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(
            targetRound == _currentRound,
            "BID: Current round is over"
        );

        require(msg.value >= _minBid, "BID: Amount sent should be higher");

        if (_balance[msg.sender][_currentRound] == 0)
            _bidders.push(msg.sender);
        _balance[msg.sender][_currentRound] += msg.value;
        _roundPot += msg.value;

        emit Bid(msg.sender, _balance[msg.sender][_currentRound]);

        return true;
    }

    function roundPot() external view returns (uint256) {
        return _roundPot;
    }

    function reward() external view returns (uint256) {
        return _reward;
    }

    function minBid() external view returns (uint256) {
        return _minBid;
    }

    /**
     * @dev increase reward between each turn in %
     */
    function setRewardMultiplicator(uint8 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _rewardMultiplicator = newValue;
        return true;
    }


    /**
     * @dev increase reward between each turn in %
     */
    function setReward(uint256 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _reward = newValue;
        return true;
    }

    function setMinBid(uint256 newValue) external onlyModerator returns (bool) {
        _minBid = newValue;
        return true;
    }

    function getBid() external view onlyCurrentACPI returns (uint256) {
        return _balance[msg.sender][_currentRound];
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound()
        external
        override
        onlyModerator
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "START: All rounds have been done");

        if (_bidders.length > 0) {
            _priceHistory.push(_roundPot);

            for (uint256 i = 0; i < _bidders.length; i++) {
                _pendingWins[_bidders[i]] +=
                    (_balance[_bidders[i]][_currentRound] * _reward) /
                    _roundPot;
            }
            delete _bidders;
            emit RoundWin(_roundPot);

            _totalWins += _reward;
            _roundPot = 0;
            _reward += (_reward * _rewardMultiplicator) / 100;
        }

        _currentRound += 1;
        if (_currentRound == _totalRound) setAcpiPrice();

        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IACPIMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Abstract contract of the ACPI standard
 */

abstract contract ACPI {
    IACPIMaster internal _acpiMaster;
    uint256[] internal _priceHistory;

    // User Address => User balance
    mapping(address => uint256) internal _pendingWins;

    uint256 internal _totalWins;

    uint16 internal _currentRound;
    uint16 internal _totalRound;
    uint256 internal _roundTime;

    uint256 internal _acpiPrice;

    uint8 internal _acpiNumber;

    /**
     * @dev Setup Abstract contract must be called only in the child contract
     */
    constructor(address acpiMaster, uint8 acpiNumber) {
        _acpiMaster = IACPIMaster(acpiMaster);
        _acpiNumber = acpiNumber;
        _roundTime = 60 * 45;
        _totalRound = 384;
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
     * @dev Returns the totalWins of ACPI
     */
    function totalWins()
        external
        view
        virtual
        returns (uint256)
    {
        return _totalWins;
    }

   function totalReturns()
        external
        view
        virtual
        returns (uint256)
    {}


    /**
     * @dev Set totalRound value
     */
    function setTotalRound(uint16 newValue)
        external
        virtual
        onlyModerator
        returns (bool)
    {
        _totalRound = newValue;
        return true;
    }

    /**
     * @dev Set time between two consecutive round in seconds
     */
    function setRoundTime(uint256 newValue)
        external
        virtual
        onlyModerator
        returns (bool)
    {
        _roundTime = newValue;
        return true;
    }

    function bid(uint16 targetRound) external payable virtual returns (bool);

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external virtual returns (bool);

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
    function resetAccount(address account)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        _pendingWins[account] = 0;
        return true;
    }

    /**
     * @dev Emitted when a user win a round of any ACPI
     * `amount` is the amount of REG Token awarded
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
        require(recipient != address(0), "Can't burn token");

        recipient.transfer(amount);
        return true;
    }

    function pendingReturns(address account)
        external
        view
        virtual
        returns (uint256)
    {}

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Real Token
 */

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IREG.sol";

interface IACPIMaster is IAccessControl {
    event ACPIChanged(uint8 indexed newAcpi);

    function tokenContract() external view returns (address);

    function acpiOneContract() external view returns (address);

    function acpiTwoContract() external view returns (address);

    function acpiThreeContract() external view returns (address);

    function acpiFourContract() external view returns (address);

    function ACPI_MASTER() external view returns (bytes32);

    function ACPI_MODERATOR() external view returns (bytes32);

    function initialTokenPrice() external view returns (uint256);

    function crossChainPrice() external view returns (uint256);

    function getACPI() external view returns (uint8);

    function generateCrossChainPrice(uint256 averageCrossChainPrice) external returns (bool);

    function setACPI(uint8 newACPI) external returns (bool);

    function getACPIWins() external view returns (uint256);

    function getACPIReturns() external view returns (uint256);

    function tokenToClaim() external view returns (uint256);

    function claimTokens() external returns (bool);

    function withdrawTokens(address payable vault, uint256 amount)
        external
        returns (bool);

    function withdrawAll(address payable vault)
        external
        returns (bool);

    function withdraw(address payable vault, uint256[4] calldata amounts)
        external
        returns (bool);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external returns (bool);

    function setTokenAddress(address tokenAddress) external returns (bool);

    function setACPIOne(address acpiAddress) external returns (bool);

    function setACPITwo(address acpiAddress) external returns (bool);

    function setACPIThree(address acpiAddress) external returns (bool);


    function setACPIFour(address acpiAddress) external returns (bool);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the Real Token
 */

interface IREG is IERC20 {
    function batchTransfer(
        address[] calldata recipient,
        uint256[] calldata amount
    ) external returns (bool);

    function contractTransfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function batchMint(address[] calldata account, uint256[] calldata amount)
        external
        returns (bool);

    function contractBurn(uint256 amount) external returns (bool);

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        returns (bool);

    function withdraw(address payable recipient, uint256 amount)
        external
        returns (bool);
}