// Be Name KHODA
// Bime Abolfazl

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IBPool {
	function totalSupply() external view returns (uint);
	function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
	function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
	function transferFrom(address src, address dst, uint amt) external returns (bool);
}

interface IERC20 {
	function approve(address dst, uint amt) external returns (bool);
	function totalSupply() external view returns (uint);
	function burn(address from, uint amount) external;
	function transfer(address recipient, uint amount) external returns (bool);
	function transferFrom(address src, address dst, uint amt) external returns (bool);
	function balanceOf(address owner) external view returns (uint);
}

interface Vault {
	function lockFor(uint amount, address _user) external returns (uint);
}

interface IUniswapV2Pair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface AutomaticMarketMaker {
	function calculateSaleReturn(uint tokenAmount) external view returns (uint);
	function calculatePurchaseReturn(uint etherAmount) external view returns (uint);
	function buy(uint _tokenAmount) external payable;
	function sell(uint tokenAmount, uint _etherAmount) external;
	function withdrawPayments(address payable payee) external;
}

contract SealedSwapper is AccessControl, ReentrancyGuard {

	bytes32 public constant ADMIN_SWAPPER_ROLE = keccak256("ADMIN_SWAPPER_ROLE");
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	
	IBPool public bpt;
	IUniswapV2Router02 public uniswapRouter;
	AutomaticMarketMaker public AMM;
	Vault public sdeaVault;
	address public sdeus;
	address public sdea;
	address public sUniDD;
	address public sUniDE;
	address public sUniDU;
	address public dea;
	address public deus;
	address public usdc;
	address public uniDD;
	address public uniDU;
	address public uniDE;

	address[] public usdc2wethPath =  [0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];
	address[] public deus2deaPath =  [0x3b62F3820e0B035cc4aD602dECe6d796BC325325, 0x80aB141F324C3d6F2b18b030f1C4E95d4d658778];
	

	uint public MAX_INT = type(uint).max;
	uint public scale = 1e18;
	uint public DDRatio;
	uint public DERatio;
	uint public DURatio;
	uint public deusRatio;
	uint public DUVaultRatio;

	event Swap(address user, address tokenIn, address tokenOut, uint amountIn, uint amountOut);

	constructor (
		address _uniswapRouter,
		address _bpt,
		address _amm,
		address _sdeaVault,
		uint _DERatio,
		uint _DURatio,
		uint _DDRatio,
		uint _deusRatio,
		uint _DUVaultRatio
	) ReentrancyGuard() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(TRUSTY_ROLE, msg.sender);
		uniswapRouter = IUniswapV2Router02(_uniswapRouter);
		bpt = IBPool(_bpt);
		AMM = AutomaticMarketMaker(_amm);
		sdeaVault = Vault(_sdeaVault);
		DDRatio = _DDRatio;
		DURatio = _DURatio;
		DERatio = _DERatio;
		deusRatio = _deusRatio;
		DUVaultRatio = _DUVaultRatio;
	}
	
	function init(
		address _sdea,
		address _sdeus,
		address _sUniDD,
		address _sUniDE,
		address _sUniDU,
		address _dea,
		address _deus,
		address _usdc,
		address _uniDD,
		address _uniDU,
		address _uniDE
	) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		sdea = _sdea;
		sdeus = _sdeus;
		sUniDD = _sUniDD;
		sUniDE = _sUniDE;
		sUniDU = _sUniDU;
		dea = _dea;
		deus = _deus;
		usdc = _usdc;
		uniDD = _uniDD;
		uniDU = _uniDU;
		uniDE = _uniDE;
		IERC20(dea).approve(address(uniswapRouter), MAX_INT);
		IERC20(deus).approve(address(uniswapRouter), MAX_INT);
		IERC20(usdc).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDD).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDE).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDU).approve(address(uniswapRouter), MAX_INT);
		IERC20(dea).approve(address(sdeaVault), MAX_INT);
	}

	function setRatios(uint _DERatio, uint _DURatio, uint _DDRatio, uint _deusRatio, uint _DUVaultRatio) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		DDRatio = _DDRatio;
		DURatio = _DURatio;
		DERatio = _DERatio;
		deusRatio = _deusRatio;
		DUVaultRatio = _DUVaultRatio;
	}

	function approve(address token, address recipient, uint amount) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		IERC20(token).approve(recipient, amount);
	}

	function bpt2eth(uint poolAmountIn, uint[] memory minAmountsOut) public nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint deaAmount = bpt.exitswapPoolAmountIn(dea, poolAmountIn, minAmountsOut[0]);
		uint deusAmount = uniswapRouter.swapExactTokensForTokens(deaAmount, minAmountsOut[1], deus2deaPath, address(this), block.timestamp + 1 days)[1];
		uint ethAmount = AMM.calculateSaleReturn(deusAmount);
		AMM.sell(deusAmount, minAmountsOut[2]);
		AMM.withdrawPayments(payable(address(this)));
		payable(msg.sender).transfer(ethAmount);

		emit Swap(msg.sender, address(bpt), address(0), poolAmountIn, ethAmount);
	}

	function deus2dea(uint amountIn) internal returns(uint) {
		return uniswapRouter.swapExactTokensForTokens(amountIn, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];
	}

	function bpt2sdea(uint poolAmountIn, uint minAmountOut) public nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);

		uint deaAmount = bpt.exitswapPoolAmountIn(dea, poolAmountIn, minAmountOut);
		uint sdeaAmount = sdeaVault.lockFor(deaAmount, address(this));

		IERC20(sdea).transfer(msg.sender, sdeaAmount);
		emit Swap(msg.sender, address(bpt), sdea, poolAmountIn, sdeaAmount);
	}

	function sdea2dea(uint amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sdea).burn(msg.sender, amount);
		IERC20(dea).transfer(recipient, amount);
		
		emit Swap(recipient, sdea, dea, amount, amount);
	}

	function sdeus2deus(uint amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sdeus).burn(msg.sender, amount);
		IERC20(deus).transfer(recipient, amount);

		emit Swap(recipient, sdeus, deus, amount, amount);
	}

	function sUniDE2UniDE(uint amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDE).burn(msg.sender, amount);
		IERC20(uniDE).transfer(recipient, amount);

		emit Swap(recipient, sUniDE, uniDE, amount, amount);
	}

	function sUniDD2UniDD(uint amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDD).burn(msg.sender, amount);
		IERC20(uniDD).transfer(recipient, amount);

		emit Swap(recipient, sUniDD, uniDD, amount, amount);
	}

	function sUniDU2UniDU(uint amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDU).burn(msg.sender, amount);
		IERC20(uniDU).transfer(recipient, amount * DUVaultRatio / scale);

		emit Swap(recipient, sUniDU, uniDU, amount, amount * DUVaultRatio / scale);
	}

	function calcExitAmount(address token, uint Predeemed) public view returns(uint) {
		uint Psupply = bpt.totalSupply();
		uint Bk = IERC20(token).balanceOf(address(bpt));
		uint ratio = Predeemed * scale / Psupply;
        return Bk * ratio / scale;
	}

	function bpt2sdea(
		uint poolAmountIn,
		uint[] memory balancerMinAmountsOut,
		uint minAmountOut
	) external nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint deaAmount = calcExitAmount(dea, poolAmountIn);
		uint sdeaAmount = calcExitAmount(sdea, poolAmountIn);
		uint sdeusAmount = calcExitAmount(sdeus, poolAmountIn);
		uint sUniDDAmount = calcExitAmount(sUniDD, poolAmountIn);
		uint sUniDEAmount = calcExitAmount(sUniDE, poolAmountIn);
		uint sUniDUAmount = calcExitAmount(sUniDU, poolAmountIn);

		bpt.exitPool(poolAmountIn, balancerMinAmountsOut);

		IERC20(sdeus).burn(address(this), sdeusAmount);
		deaAmount += deus2dea(sdeusAmount * deusRatio / scale);

		IERC20(sUniDE).burn(address(this), sUniDEAmount);
		deaAmount += uniDE2dea(sUniDEAmount * DERatio / scale);

		IERC20(sUniDU).burn(address(this), sUniDUAmount);
		deaAmount += uniDU2dea(sUniDUAmount * DURatio / scale);

		IERC20(sUniDD).burn(address(this), sUniDDAmount);
		deaAmount += uniDD2dea(sUniDDAmount * DDRatio / scale);

		require(deaAmount + sdeaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");

		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount + sdeaAmount);

		emit Swap(msg.sender, address(bpt), sdea, poolAmountIn, deaAmount + sdeaAmount);
	}



	function uniDD2dea(uint sUniDDAmount) internal returns(uint) {
		(uint deusAmount, uint deaAmount) = uniswapRouter.removeLiquidity(deus, dea, sUniDDAmount, 1, 1, address(this), block.timestamp + 1 days);

		uint deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];

		return deaAmount + deaAmount2;
	}

	function sUniDD2sdea(uint sUniDDAmount, uint minAmountOut) public nonReentrant() {
		IERC20(sUniDD).burn(msg.sender, sUniDDAmount);

		uint deaAmount = uniDD2dea(sUniDDAmount * DDRatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);

		emit Swap(msg.sender, uniDD, sdea, sUniDDAmount, deaAmount);
	}


	function uniDU2dea(uint sUniDUAmount) internal returns(uint) {
		(uint deaAmount, uint usdcAmount) = uniswapRouter.removeLiquidity(dea, usdc, (sUniDUAmount * DUVaultRatio / scale), 1, 1, address(this), block.timestamp + 1 days);

		uint ethAmount = uniswapRouter.swapExactTokensForETH(usdcAmount, 1, usdc2wethPath, address(this), block.timestamp + 1 days)[1];

		uint deusAmount = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount);
		
		uint deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];

		return deaAmount + deaAmount2;
	}
	

	function sUniDU2sdea(uint sUniDUAmount, uint minAmountOut) public nonReentrant() {
		IERC20(sUniDU).burn(msg.sender, sUniDUAmount);

		uint deaAmount = uniDU2dea(sUniDUAmount * DURatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);
		
		emit Swap(msg.sender, uniDU, sdea, sUniDUAmount, deaAmount);
	}


	function uniDE2dea(uint sUniDEAmount) internal returns(uint) {
		(uint deusAmount, uint ethAmount) = uniswapRouter.removeLiquidityETH(deus, sUniDEAmount, 1, 1, address(this), block.timestamp + 1 days);
		uint deusAmount2 = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount2);
		uint deaAmount = uniswapRouter.swapExactTokensForTokens(deusAmount + deusAmount2, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];
		return deaAmount;
	}

	function sUniDE2sdea(uint sUniDEAmount, uint minAmountOut) public nonReentrant() {
		IERC20(sUniDE).burn(msg.sender, sUniDEAmount);

		uint deaAmount = uniDE2dea(sUniDEAmount * DERatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);

		emit Swap(msg.sender, uniDE, sdea, sUniDEAmount, deaAmount);
	}

	function withdraw(address token, uint amount, address to) public {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		IERC20(token).transfer(to, amount);
	}

	function withdrawEther(uint amount, address payable to) public {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		to.transfer(amount);
	}
	
	receive() external payable {}
	
	//--------- View functions --------- //

	function minAmountCaculator(address pair, uint amount) public view returns(uint, uint) {
		(uint reserve1, uint reserve2, ) = IUniswapV2Pair(pair).getReserves();
		uint totalSupply = IERC20(pair).totalSupply();
		return (amount * reserve1 / totalSupply, amount * reserve2 / totalSupply);
	}

	function estimateBpt2SDeaAmount(uint poolAmountIn) public view returns(uint[6] memory, uint) {
		uint deaAmount = calcExitAmount(dea, poolAmountIn);
		uint sUniDDAmount = calcExitAmount(sUniDD, poolAmountIn);
		uint sUniDUAmount = calcExitAmount(sUniDU, poolAmountIn);
		uint sUniDEAmount = calcExitAmount(sUniDE, poolAmountIn);
		uint balancerSdeaAmount = calcExitAmount(sdea, poolAmountIn);
		uint sdeusAmount = calcExitAmount(sdeus, poolAmountIn);

		uint sdeaAmount = balancerSdeaAmount;
		sdeaAmount += deaAmount;
		sdeaAmount += getSUniDD2SDeaAmount(sUniDDAmount);
		sdeaAmount += getSUniDU2SDeaAmount(sUniDUAmount);
		sdeaAmount += getSUniDE2SDeaAmount(sUniDEAmount);
		sdeaAmount += uniswapRouter.getAmountsOut(sdeusAmount * deusRatio / scale, deus2deaPath)[1];

		return ([deaAmount, sUniDDAmount, sUniDUAmount, sUniDEAmount, balancerSdeaAmount, sdeusAmount], sdeaAmount);
	}
	function getSUniDU2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deaAmount, uint usdcAmount) = minAmountCaculator(uniDU, (amountIn * DUVaultRatio / scale));
		uint ethAmount = uniswapRouter.getAmountsOut(usdcAmount, usdc2wethPath)[1];
		uint deusAmount = AMM.calculatePurchaseReturn(ethAmount);
		uint deaAmount2 = uniswapRouter.getAmountsOut(deusAmount, deus2deaPath)[1];
		return (deaAmount + deaAmount2) * DURatio / scale;
	}

	function uniPairGetAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

	function getSUniDD2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deusReserve, uint deaReserve, ) = IUniswapV2Pair(uniDD).getReserves();
		(uint deusAmount, uint deaAmount) = minAmountCaculator(uniDD, amountIn);
		uint deaAmount2 = uniPairGetAmountOut(deusAmount, deusReserve - deusAmount, deaReserve - deaAmount);
		return (deaAmount + deaAmount2) * DDRatio / scale;
	}
	
	function getSUniDE2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deusAmount, uint ethAmount) = minAmountCaculator(uniDE, amountIn);
		uint deusAmount2 = AMM.calculatePurchaseReturn(ethAmount);
		uint deaAmount = uniswapRouter.getAmountsOut(deusAmount + deusAmount2, deus2deaPath)[1];
		return deaAmount * DERatio / scale;
	}
}

// Dar panahe Khoda

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

