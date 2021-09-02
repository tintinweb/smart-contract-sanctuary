pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract YSLOpt is Ownable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant STRAT_ROLE = keccak256("STRAT_ROLE");
    IERC20 public lpToken;

    address public team;
    address public main;
    address public amplifier;
    address public feeAddress;
    address public referral;
    address public adapter;
    uint256 public optimisationTax;
    uint256 public controllerFee;
    uint256 public coef_opt;
    uint256 public coef_s1;
    uint256 public coef_s2;
    uint256 public coef_ref;

    mapping(address => uint256) public userDeposited;
    uint256 public totalDeposited;

    uint256 public lastEarnBlock;
    //BUSD token
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //WBNB token
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    //CAKE token
    address public CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    //Banana token
    address public BANANA = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;

    address public apeSwap = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address public pancakeSwap = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    address public apeMaster = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
    address public pancakeMaster = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    address public stratSwap;

    modifier stratOnly() {
        require(hasRole(STRAT_ROLE, _msgSender()), "Caller is not a strategiest");
        _;
    }

    constructor(
        address _adapter,
        address _team,
        address _lpToken,
        address _feeAddress,
        uint256 _controllerFee,
        address _referral,
        address _stratSwap
    ) {
        _setupRole(STRAT_ROLE, address(this));
        require(_controllerFee >= 3 && _controllerFee <= 10, "Controller fee must lay within [3;10] (0.3-1 percents)");
        coef_opt = 165;
        coef_s1 = 175;
        coef_s2 = 225;
        coef_ref = 10;
        adapter = _adapter;
        team = _team;
        lpToken = IERC20(_lpToken);
        feeAddress = _feeAddress;
        controllerFee = _controllerFee;
        referral = _referral;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        stratSwap = _stratSwap;
    }

    function deposit(
        address _from,
        uint256 _amount,
        address _referrer
    ) external virtual returns (uint256);

    function withdraw(uint256 _amount, address _user) external virtual returns (uint256);

    function setCoefficients(
        uint256 _copt,
        uint256 _cs1,
        uint256 _cs2,
        uint256 _cref
    ) external onlyOwner {
        coef_opt = _copt;
        coef_s1 = _cs1;
        coef_s2 = _cs2;
        coef_ref = _cref;
    }

    function setMain(address _main) external onlyOwner {
        main = _main;
    }
}

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./YSLOpt.sol";

import "../interfaces/IPancakeMaster.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IsYSL.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IStrategySwap.sol";

contract YSLOptSingleApe is YSLOpt {
    using SafeERC20 for IERC20;

    address[] public path;

    uint256 apeId;

    constructor(
        address _adapter,
        uint256 _apeId,
        address[] memory _path,
        address _team,
        address _lpToken,
        address _feeAddress,
        uint256 _controllerFee,
        address _referral,
        address _stratSwap
    ) YSLOpt(_adapter, _team, _lpToken, _feeAddress, _controllerFee, _referral, _stratSwap) {
        path = _path;
        apeId = _apeId;
    }

    function deposit(
        address _from,
        uint256 _amount,
        address _referrer
    ) public override stratOnly returns (uint256) {
        if (_referrer != address(0)) {
            IReferral(referral).proccessReferral(_from, _referrer);
        }
        lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _amount = collectControllerFee(_amount);
        userDeposited[_from] += _amount;
        totalDeposited += _amount;
        return _amount;
    }

    function transferOut(
        address _user,
        uint256 _amount,
        address _ysl
    ) public stratOnly returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = _ysl;
        userDeposited[_user] -= _amount;
        totalDeposited -= _amount;
        uint256 fee = _amount / 1000;
        _amount -= fee;
        uint256 amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, fee);
        IStrategySwap(stratSwap).swapLPToBusd(fee, apeSwap, path, lpToken);
        uint256 amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        uint256 emission = IPancakeRouter02(apeSwap).getAmountsOut(amountUSDAfter - amountUSDBefore, path)[1];
        IERC20(BUSD).approve(apeSwap, amountUSDAfter - amountUSDBefore);
        IERC20(_ysl).approve(apeSwap, emission);
        IPancakeRouter02(apeSwap).addLiquidity(
            BUSD,
            _ysl,
            amountUSDAfter - amountUSDBefore,
            emission,
            1,
            1,
            adapter,
            block.timestamp + 10000
        );
        amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, _amount);
        IStrategySwap(stratSwap).swapLPToBusd(_amount, apeSwap, path, lpToken);
        amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        IERC20(BUSD).safeTransfer(_msgSender(), amountUSDAfter - amountUSDBefore);
        return amountUSDAfter - amountUSDBefore;
    }

    function transferIn(address _user, uint256 _amount) public stratOnly returns (uint256) {
        uint256 amountLPBefore = lpToken.balanceOf(address(this));
        IERC20(BUSD).approve(stratSwap, _amount);
        IStrategySwap(stratSwap).swapBusdToLP(_amount, apeSwap, path, BUSD);
        uint256 amountLPAfter = lpToken.balanceOf(address(this));
        userDeposited[_user] += amountLPAfter - amountLPBefore;
        totalDeposited += amountLPAfter - amountLPBefore;
        return amountLPAfter - amountLPBefore;
    }

    function withdraw(uint256 _amount, address _user) external override stratOnly returns (uint256) {
        lpToken.approve(_msgSender(), _amount);
        userDeposited[_user] -= _amount;
        totalDeposited -= _amount;
        return _amount;
    }

    function collectControllerFee(uint256 _amount) internal returns (uint256 summary) {
        uint256 fee = (_amount * controllerFee) / 1000;
        summary = _amount - fee;
        require(summary != _amount, "Insufficiant fee");
        uint256 amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, fee);
        IStrategySwap(stratSwap).swapLPToBusd(fee, apeSwap, path, lpToken);
        uint256 amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        address[] memory _path = new address[](2);
        _path[0] = BUSD;
        _path[1] = WBNB;
        IERC20(BUSD).approve(apeSwap, amountUSDAfter - amountUSDBefore);
        IPancakeRouter02(apeSwap).swapExactTokensForETH(
            amountUSDAfter - amountUSDBefore,
            1,
            _path,
            feeAddress,
            block.timestamp + 10000
        );
    }

    function collectOptimisationTax(uint256 _amount) internal returns (uint256 summary) {
        uint256 tax = (_amount * 15) / 100;
        require(tax > 0, "Inufficiant tax");
        uint256 amountUSDBefore = IERC20(BUSD).balanceOf(address(this));
        lpToken.approve(stratSwap, tax);
        IStrategySwap(stratSwap).swapLPToBusd(tax, apeSwap, path, lpToken);
        uint256 amountUSDAfter = IERC20(BUSD).balanceOf(address(this));
        uint256 split = (amountUSDAfter - amountUSDBefore) / 2;

        //TODO: 10% to liquidity mining rewards, 5% to buy/burn xYSL
        IERC20(BUSD).safeTransfer(main, split);
        IERC20(BUSD).safeTransfer(main, split);
    }

    function compound() external {
        require(_msgSender() == main, "Governance contract only");
        address[] memory path = new address[](2);
        path[0] = BANANA;
        path[1] = BUSD;
        collectOptimisationTax(lpToken.balanceOf(address(this)));
        lpToken.approve(apeSwap, lpToken.balanceOf(address(this)));
        IPancakeMaster(apeMaster).deposit(apeId, lpToken.balanceOf(address(this)));
        IERC20(BANANA).approve(apeSwap, type(uint256).max);
        IPancakeRouter02(apeSwap).swapExactTokensForTokens(
            IERC20(BANANA).balanceOf(address(this)),
            1,
            path,
            address(this),
            block.timestamp + 10000
        );
        IERC20(BUSD).approve(stratSwap, IERC20(BUSD).balanceOf(address(this)));
        IStrategySwap(stratSwap).swapBusdToLP(IERC20(BUSD).balanceOf(address(this)), apeSwap, path, BUSD);
    }

    function earn(address _user, bool _isAmplified) external stratOnly {
        address[] memory path = new address[](2);
        address _sysl = IStrategySwap(stratSwap).sYSL();
        address _ysl = IStrategySwap(stratSwap).YSL();
        path[0] = BUSD;
        path[1] = _ysl;
        uint256 compounded = (IERC20(lpToken).balanceOf(address(this)) - totalDeposited);
        if (compounded == 0) {
            return;
        }
        uint256 usersComp = (compounded * userDeposited[_user]) / totalDeposited;
        lpToken.approve(stratSwap, usersComp);
        uint256 usersCompUSD = IStrategySwap(stratSwap).swapLPToBusd(usersComp, apeSwap, path, lpToken);
        uint256 emission = IPancakeRouter02(apeSwap).getAmountsOut(usersCompUSD, path)[1];
        IsYSL(_ysl).mintFor(address(this), emission);
        IERC20(_ysl).approve(apeSwap, emission);
        IERC20(BUSD).approve(apeSwap, usersCompUSD);
        IPancakeRouter02(apeSwap).addLiquidity(
            BUSD,
            _ysl,
            usersCompUSD,
            emission,
            1,
            1,
            adapter,
            block.timestamp + 10000
        );
        uint256 koef = IReferral(referral).hasReferral(_user) ? coef_s1 : coef_opt;
        if (koef == coef_s1) {
            uint256 bonus = (usersCompUSD * ((IStrategySwap(stratSwap).getsYSLPrice()) / (10**18)) * coef_ref) /
                10**18 /
                100;
            IsYSL(_sysl).mintPurchased(IReferral(referral).referrals(_user), bonus, 90 days);
        }
        koef = _isAmplified ? coef_s2 : koef;
        uint256 usersIncome = (usersCompUSD * ((IStrategySwap(stratSwap).getsYSLPrice()) / (10**18)) * koef) /
            10**18 /
            100;
        IsYSL(_sysl).mintPurchased(_user, usersIncome, 90 days);
    }

    function getUserDepositedUSD(address _user) public view returns (uint256) {
        if (userDeposited[_user] == 0) {
            return 0;
        }
        return IStrategySwap(stratSwap).getBusdAmount(userDeposited[_user], path, apeSwap);
    }

    function getTotalDepositedUSD() public view returns (uint256) {
        if (totalDeposited == 0) {
            return 0;
        }
        return IStrategySwap(stratSwap).getBusdAmount(totalDeposited, path, apeSwap);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeMaster {
    function deposit(uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeRouter02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IReferral {
    function hasReferral(address _account) external view returns (bool);

    function referrals(address _account) external view returns (address);

    function proccessReferral(
        address _sender,
        address _segCreator,
        bytes memory _sig
    ) external;

    function proccessReferral(address _sender, address _segCreator) external;
}

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategySwap {
    function sYSL() external returns (address);

    function YSL() external returns (address);

    function getsYSLPrice() external returns (uint256 price);

    function reversedPath(address[] memory path) external pure returns (address[] memory);

    function swapLPToBusd(
        uint256 _amount,
        address _router,
        address[] memory _path,
        IERC20 lpToken
    ) external returns (uint256);

    function swapBusdToLP(
        uint256 _amount,
        address _router,
        address[] memory _path,
        address _busd
    ) external;

    function swapLPToBusd(
        uint256 _amount,
        address _router,
        address _busd,
        address[] memory path0,
        address[] memory path1,
        IERC20 lpToken
    ) external returns (uint256);

    function swapBusdToLP(
        uint256 _amount,
        address _router,
        address _busd,
        address[] memory path0,
        address[] memory path1,
        IERC20 lpToken
    ) external;

    function getBusdAmount(
        uint256 _amount,
        IERC20 lpToken,
        address _router,
        address[] memory path0,
        address[] memory path1
    ) external view returns (uint256);

    function getBusdAmount(
        uint256 _amount,
        address[] memory path,
        address _router
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IsYSL {
    function YSLSupply() external returns (uint256);

    function isMinted() external returns (bool);

    function mintPurchased(
        address account,
        uint256 amount,
        uint256 lockTime
    ) external;

    function mintFor(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

pragma solidity 0.8.4;

import "../YSLfarm/YSLOptSingleApe.sol";

contract MockYSLOptSingleApe is YSLOptSingleApe {
    constructor(
        address _adapter,
        uint256 _apeId,
        address[] memory _path,
        address _team,
        address _lpToken,
        address _feeAddress,
        uint256 _controllerFee,
        address _referral,
        address _stratSwap
    ) YSLOptSingleApe(_adapter, _apeId, _path, _team, _lpToken, _feeAddress, _controllerFee, _referral, _stratSwap) {}

    function setBUSD(address _BUSD) public {
        BUSD = _BUSD;
    }

    function setWBNB(address _WBNB) public {
        WBNB = _WBNB;
    }

    function setCAKE(address _CAKE) public {
        CAKE = _CAKE;
    }

    function setBANANA(address _BANANA) public {
        BANANA = _BANANA;
    }

    function setApeSwap(address _apeSwap) public {
        apeSwap = _apeSwap;
    }

    function setPancakeSwap(address _pancakeSwap) public {
        pancakeSwap = _pancakeSwap;
    }

    function setApeMaster(address _apeMaster) public {
        apeMaster = _apeMaster;
    }

    function setPancakeMaster(address _pancakeMaster) public {
        pancakeMaster = _pancakeMaster;
    }
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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
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