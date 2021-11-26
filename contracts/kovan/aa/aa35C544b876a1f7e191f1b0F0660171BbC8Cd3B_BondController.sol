pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/IIouFactory.sol";
import "./interfaces/IIou.sol";
import "./interfaces/ITranche.sol";

/**
 * @dev Controller for a HourGlass bond
 *
 * This bond has A iou and Z iou
 * A iou has two collateral: A tranche and Z tranche
 * Z iou has one collateral: Z tranche
 *
 * (maturityDate - creationDate) = 30 * 1 day
 * totalInterestRate = 100000000000000
 * INTEREST_RATE_GRANULARITY = 100000000000000
 *
 * Day 0:
 * - tranche ratio is 20/30/50
 * - Alice deposits 100 AMPL
 *   - Alice gets 20 A tranche worth 20 AMPL
 *   - Alice gets 50 Z tranche worth 50 AMPL
 * - A iou / A tranche ratio is 20/20
 * - A iou / Z tranche ratio is 20/0
 * - Z iou / Z tranche ratio is 50/50
 * - Alice deposits 20 A tranche and 50 Z tranche
 *   - Alice gets 20 A iou worth 20 A tranche
 *   - Alice gets 50 Z iou worth 50 Z tranche
 *   - A iou totalSupply is 20
 *   - Z iou totalSupply is 50
 *   - Sacrifice is 0 Z tranche
 * - All ratios are unchanged
 *
 * Day 3:
 * - AMPL supply decreased by 25% since Day 0
 * - A iou / A tranche ratio is 20/20
 * - A iou / Z tranche ratio is 20/5
 * - Z iou / Z tranche ratio is 50/45
 * - Alice redeemEmergencys 16 A iou
 *   - Alice sacrifices 36 Z tranche of interests to those who redeemMature their A iou
 *   - Alice gets 16 A tranche worth 16 AMPL
 *   - Alice gets 4 Z tranche worth 2 AMPL
 *   - A iou totalSupply is 4
 *   - Z iou totalSupply is 50
 *   - Sacrifice is 36 Z tranche
 * - All ratios are unchanged
 *
 * Day 15:
 * - AMPL supply stayed the same since Day 3
 * - tranche ratio is 20/30/50
 * - Bob deposits 50 AMPL
 *   - Bob gets 20 A tranche worth 20 AMPL
 *   - Bob gets 50 Z tranche worth 25 AMPL
 * - A iou / A tranche ratio is 20/20
 * - A iou / Z tranche ratio is 20/25
 * - Z iou / Z tranche ratio is 50/25
 * - Bob deposits 20 A tranche and 50 Z tranche
 *   - Bob gets 20 A iou worth 20 A tranche and 25 Z tranche
 *   - Bob gets 50 Z iou worth 25 Z tranche
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 100
 *   - Sacrifice is 36 Z tranche
 * - All ratios are unchanged
 *
 * Day 30:
 * - AMPL supply recovers to its original amount on Day 0
 * - A iou / A tranche ratio is 20/20
 * - A iou / Z tranche ratio is 20/50
 * - Z iou / Z tranche ratio is 50/0
 * - Alice redeemMatures 50 Z iou
 *   - Alice gets 0 Z tranche worth 0 AMPL
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 50
 *   - Sacrifice is 36 Z tranche
 * - Bob redeemMatures 50 Z iou
 *   - Bob gets 0 Z tranche worth 0 AMPL
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 0
 *   - Sacrifice is 36 Z tranche
 * - Alice redeemMatures 4 A iou
 *   - Alice gets 4 A tranche worth 4 AMPL
 *   - Alice gets 16 Z tranche worth 16 AMPL (because Alice also gets 4/24 of the remaining sacrifice of 36 Z tranche of interests)
 *   - A iou totalSupply is 20
 *   - Z iou totalSupply is 0
 *   - Sacrifice is 30 Z tranche
 * - Bob redeemMatures 20 A iou
 *   - Bob gets 20 A tranche worth 20 AMPL
 *   - Bob gets 80 Z tranche worth 80 AMPL (because Bob also gets 20/20 of the remaining sacrifice of 36 Z tranche of interests)
 *   - A iou totalSupply is 0
 *   - Z iou totalSupply is 0
 *   - Sacrifice is 0 Z tranche
 * - Alice redeems 20 A tranche worth 20 AMPL
 * - Alice redeems 20 Z tranche worth 20 AMPL
 * - Bob redeems 20 A tranche worth 20 AMPL
 * - Bob redeems 80 Z tranche worth 80 AMPL
 */
contract BondController is IBondController, Initializable, AccessControl {
    uint256 private TRANCHE_RATIO_GRANULARITY;
    uint256 private constant INTEREST_RATE_GRANULARITY = 100000000000000;

    TrancheData[] public override tranches;
    address[] public override ious;
    uint256 public override trancheCount;
    mapping(address => bool) public iouTokenAddresses;
    uint256 public maturityDate;
    bool public isMature;
    uint256 public creationDate;
    uint256 public totalInterestRate;
    uint256 public everySecondInterestRate;
    uint256 public totalInterestSacrificed;

    /**
     * @dev Constructor for Tranche ERC20 token
     * @param _iouFactory The address of the iou factory
     * @param _tranches The tranches that may be deposited into this bond
     * @param _admin The address of the initial admin for this contract
     * @param _maturityDate The date timestamp in seconds at which this bond matures
     * @param _totalInterestRate The total interest rate of this bond
     */
    function init(
        address _iouFactory,
        TrancheData[] memory _tranches,
        address _admin,
        uint256 _maturityDate,
        uint256 _totalInterestRate
    ) external initializer {
        require(_iouFactory != address(0), "BondController: invalid iouFactory address");
        require(_tranches.length == 2, "BondController: invalid tranche count");
        require(_admin != address(0), "BondController: invalid admin address");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        trancheCount = _tranches.length;
        for (uint256 i = 0; i < _tranches.length; i++) {
            tranches.push(_tranches[i]);
        }

        // This bond only accepts `deposit`s and `redeem`s with the ratio defined by `_tranches`
        TRANCHE_RATIO_GRANULARITY = _tranches[0].ratio + _tranches[1].ratio;

        // Create A iou
        address iouTokenAddress = IIouFactory(_iouFactory).createIou("HourGlass token", "A-PRIME", address(_tranches[0].token));
        ious.push(iouTokenAddress);
        iouTokenAddresses[iouTokenAddress] = true;

        // Create Z iou
        iouTokenAddress = IIouFactory(_iouFactory).createIou("HourGlass token", "Z-PRIME", address(_tranches[1].token));
        ious.push(iouTokenAddress);
        iouTokenAddresses[iouTokenAddress] = true;

        require(ious.length == _tranches.length, "BondController: Invalid iou count");

        require(_maturityDate > block.timestamp, "BondController: Invalid maturity date");
        maturityDate = _maturityDate;
        creationDate = block.timestamp;
        totalInterestRate = _totalInterestRate;
        require(totalInterestRate <= INTEREST_RATE_GRANULARITY, "BondController: Invalid interest rate");
        everySecondInterestRate = totalInterestRate / (maturityDate - creationDate); // WARNING this becomes zero if (maturityDate - creationDate) > totalInterestRate
    }

    /**
     * @inheritdoc IBondController
     */
    function deposit(uint256[] memory amounts) external override {
        require(!isMature, "BondController: Already mature");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;
        require(amounts.length == _tranches.length, "BondController: Invalid deposit amounts");

        uint256 total = amounts[0] + amounts[1];

        // If always deposit with correct ratio, then can always transfer in 20 A tranche and mint 20 A iou
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            require(
                (amount * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid deposit ratio"
            );
            TransferHelper.safeTransferFrom(address(_tranches[i].token), _msgSender(), address(this), amount);
            IIou(_ious[i]).mint(_msgSender(), amount);
        }

        emit Deposit(_msgSender(), amounts);
    }

    /**
     * @inheritdoc IBondController
     */
    function mature() external override {
        require(!isMature, "BondController: Already mature");
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || maturityDate < block.timestamp,
            "BondController: Invalid call to mature"
        );
        isMature = true;

        emit Mature(_msgSender());
    }

    /**
     * @inheritdoc IBondController
     */
    function getInterestOnRedeemMature(uint256 amount) public override view returns (uint256) {
        return (amount * totalInterestRate * tranches[1].ratio) / (INTEREST_RATE_GRANULARITY * tranches[0].ratio);
    }

    /**
     * @inheritdoc IBondController
     */
    function getInterestSacrificedOnRedeemMature(uint256 amount) public override view returns (uint256) {
        return (amount * totalInterestSacrificed) / IIou(ious[0]).totalSupply();
    }

    /**
     * @inheritdoc IBondController
     */
    function redeemMature(address iou, uint256 amount) external override {
        require(isMature, "BondController: Bond is not mature");
        require(iouTokenAddresses[iou], "BondController: Invalid iou address");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;

        uint256 interest;
        uint256 interestSacrificed;

        if (iou == _ious[0]) {
            interest = getInterestOnRedeemMature(amount);
            interestSacrificed = getInterestSacrificedOnRedeemMature(amount);

            // Transfer some A tranche
            TransferHelper.safeTransfer(
              address(_tranches[0].token),
              _msgSender(),
              amount
            );

            // Transfer some Z tranche and some sacrificed interest
            TransferHelper.safeTransfer(
              address(_tranches[1].token),
              _msgSender(),
              interest + interestSacrificed
            );

            totalInterestSacrificed -= interestSacrificed;

        } else if (iou == _ious[1]) {
            // interest = getInterestOnRedeemMature(amountZ * _tranches[0].ratio / _tranches[1].ratio);
            interest = (amount * totalInterestRate) / INTEREST_RATE_GRANULARITY;

            // Transfer some Z tranche
            TransferHelper.safeTransfer(
              address(_tranches[1].token),
              _msgSender(),
              amount - interest
            );
        }

        // Burn after transferring so that the next time someone `redeemMature`s, Z tranche transferred is correct
        IIou(iou).burn(_msgSender(), amount);

        emit RedeemMature(_msgSender(), iou, amount);
    }

    /**
     * @inheritdoc IBondController
     */
    function redeem(uint256[] memory amounts) external override {
        require(!isMature, "BondController: Bond is already mature");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;
        require(amounts.length == _ious.length, "BondController: Invalid redeem amounts");
        uint256 total;

        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        // If always redeem with correct ratio, then can always burn 20 A iou and transfer out 20 A tranche
        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                (amounts[i] * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid redemption ratio"
            );
            IIou(_ious[i]).burn(_msgSender(), amounts[i]);
            TransferHelper.safeTransfer(address(_tranches[i].token), _msgSender(), amounts[i]);
        }

        emit Redeem(_msgSender(), amounts);
    }

    /**
     * @inheritdoc IBondController
     */
    function getInterestOnRedeemEmergency(uint256 amount) public override view returns (uint256) {
        return (amount * (block.timestamp - creationDate) * everySecondInterestRate * tranches[1].ratio) / (INTEREST_RATE_GRANULARITY * tranches[0].ratio);
    }

    /**
     * @inheritdoc IBondController
     */
    function redeemEmergency(uint256 amount) external override {
        require(!isMature, "BondController: Already mature");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;

        uint256 totalInterestTillNow = getInterestOnRedeemEmergency(amount);

        IIou(_ious[0]).burn(_msgSender(), amount);
        TransferHelper.safeTransfer(address(_tranches[0].token), _msgSender(), amount);
        TransferHelper.safeTransfer(address(_tranches[1].token), _msgSender(), totalInterestTillNow);

        totalInterestSacrificed += getInterestOnRedeemMature(amount) - totalInterestTillNow;

        emit RedeemEmergency(_msgSender(), amount);
    }
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

/**
 * @dev Controller for a HourGlass bond system
 */
interface IBondController {
    event Deposit(address from, uint256[] amounts);
    event Mature(address caller);
    event RedeemMature(address user, address iou, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event RedeemEmergency(address user, uint256 amount);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function ious(uint256 i) external view returns (address iou);

    function trancheCount() external view returns (uint256 count);

    /**
     * @dev Deposit `amounts` tokens from `msg.sender`, get iou tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amounts` tokens to this contract
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function deposit(uint256[] memory amounts) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is `owner`
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Gets the Z tranche interest that would be redeemed as if `amount` A iou tokens are redeemed at maturity
     */
    function getInterestOnRedeemMature(uint256 amount) external view returns (uint256);

    /**
     * @dev Gets the Z tranche interest sacrificed that would be redeemed as if `amount` A iou tokens are redeemed at maturity
     */
    function getInterestSacrificedOnRedeemMature(uint256 amount) external view returns (uint256);

    /**
     * @dev Redeems some iou tokens
     *  If `iou` is A iou token, then also transfer some `interestSacrified` tranches if any 
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` iou tokens from address `iou`
     *  - `iou` must be a valid iou token on this bond
     */
    function redeemMature(address iou, uint256 amount) external;

    /**
     * @dev Redeems a slice of iou tokens from all tranches.
     * Requirements
     *  - The bond is not mature
     *  - The number of `amounts` is the same as the number of tranches
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function redeem(uint256[] memory amounts) external;

    /**
     * @dev Gets the Z tranche interest that would be redeemed as if `amount` A iou tokens are redeemed before maturity at the current `block`'s timestamp
     */
    function getInterestOnRedeemEmergency(uint256 amount) external view returns (uint256);

    /**
     * @dev Redeems `amount` A iou tokens for `amount` A tranche tokens and the Z tranche interest earned till now
     * Requirements:
     *  - The bond is not mature
     *  - `msg.sender` owns at least `amount` A iou tokens
     */
    function redeemEmergency(uint256 amount) external;
}

pragma solidity 0.8.7;

/**
 * @dev Factory for Iou minimal proxy contracts
 */
interface IIouFactory {
    event IouCreated(address newIouAddress);

    /**
     * @dev Deploys a minimal proxy instance for a new iou ERC20 token with the given parameters.
     */
    function createIou(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external returns (address);
}

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ERC20 token to represent a single IOU for a HourGlass bond
 *
 */
interface IIou is IERC20 {
    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
}

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

/**
 * @dev ERC20 token to represent a single tranche for a ButtonTranche bond
 *
 */
interface ITranche is IERC20 {
    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from` and return the proportional
     * value of the collateral token to `to`
     * @param from The address to burn tokens from
     * @param to The address to send collateral back to
     * @param amount The amount of tokens to burn
     */
    function redeem(
        address from,
        address to,
        uint256 amount
    ) external;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}