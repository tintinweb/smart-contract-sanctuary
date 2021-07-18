// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import {IOilerRegistry} from "./interfaces/IOilerRegistry.sol";
import {IOilerOptionBase} from "./interfaces/IOilerOptionBase.sol";
import {IOilerOptionsRouter} from "./interfaces/IOilerOptionsRouter.sol";
import {IBRouter} from "./interfaces/IBRouter.sol";
import {IBPool} from "./interfaces/IBPool.sol";

contract OilerOptionsRouter is IOilerOptionsRouter {
    IOilerRegistry public immutable override registry;
    IBRouter public immutable override bRouter;

    constructor(IOilerRegistry _registry, IBRouter _bRouter) {
        registry = _registry;
        bRouter = _bRouter;
    }

    modifier onlyRegistry() {
        require(
            address(registry) == msg.sender,
            "OilerOptionsRouter.setUnlimitedApprovals, only the registry can set an unlimited approval"
        );
        _;
    }

    function write(IOilerOptionBase _option, uint256 _amount) external override {
        _writeOnBehalfOf(_option, _amount);
    }

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external override {
        _write(_option, _amount);
        _addLiquidity(_option, _amount, _liquidityProviderCollateralAmount);
    }

    // Permittable versions of the above:

    /**
     * @notice permit signed deadline must be max uint.
     */
    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external override {
        _writeOnBehalfOfPermittable(_option, _amount, _permit);
    }

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writeOnBehalfOfPermit,
        Permit calldata _liquidityAddPermit
    ) external override {
        _writePermittable(_option, _amount, _writeOnBehalfOfPermit);
        _addLiquidityPermittable(_option, _amount, _liquidityProviderCollateralAmount, _liquidityAddPermit);
    }

    // Restricted functions: onlyRegistry
    // This is supposed to be called by the registry when new option is being registered
    function setUnlimitedApprovals(IOilerOptionBase _option) external override onlyRegistry {
        _option.collateralInstance().approve(address(_option), type(uint256).max);

        _option.collateralInstance().approve(address(bRouter), type(uint256).max);

        _option.approve(address(bRouter), type(uint256).max);
    }

    // Internal functions below:

    function _write(IOilerOptionBase _option, uint256 _amount) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _amount),
            "OilerOptionsRouter.write, ERC20 transfer failed"
        );

        _option.write(_amount);
    }

    function _writeOnBehalfOf(IOilerOptionBase _option, uint256 _amount) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _amount),
            "OilerOptionsRouter.write, ERC20 transfer failed"
        );

        _option.write(_amount, msg.sender);
    }

    function _addLiquidity(
        IOilerOptionBase _option,
        uint256 _optionsAmount,
        uint256 _liquidityProviderCollateralAmount
    ) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _liquidityProviderCollateralAmount),
            "OilerOptionsRouter:addLiquidity, ERC20 transfer failed"
        );
        bRouter.addLiquidity(
            address(_option),
            address(_option.collateralInstance()),
            _optionsAmount,
            _liquidityProviderCollateralAmount
        );

        // Transfer back to msg.sender returned tokens and LP tokens.
        require(
            _option.transfer(msg.sender, _option.balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, options return transfer failed"
        );

        require(
            _option.collateralInstance().transfer(msg.sender, _option.collateralInstance().balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, collateral return transfer failed"
        );

        IBPool pool = bRouter.getPoolByTokens(address(_option), address(_option.collateralInstance()));

        require(
            pool.transfer(msg.sender, pool.balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, lbp tokens return failed"
        );
    }

    // Permittable versions of the above:

    function _writeOnBehalfOfPermittable(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit memory _permit
    ) internal {
        IERC20Permit(address(_option.collateralInstance())).permit(
            msg.sender,
            address(this),
            _amount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );
        _writeOnBehalfOf(_option, _amount);
    }

    function _writePermittable(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit memory _permit
    ) internal {
        IERC20Permit(address(_option.collateralInstance())).permit(
            msg.sender,
            address(this),
            _amount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );
        _write(_option, _amount);
    }

    function _addLiquidityPermittable(
        IOilerOptionBase _option,
        uint256 _optionsAmount,
        uint256 _collateralAmount,
        Permit memory _permit
    ) internal {
        _option.collateralInstance().permit(
            msg.sender,
            address(this),
            _collateralAmount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );

        _addLiquidity(_option, _optionsAmount, _collateralAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IOilerOptionsRouter.sol";

interface IOilerRegistry {
    function PUT() external view returns (uint256);

    function CALL() external view returns (uint256);

    function activeOptions(bytes32 _type) external view returns (address[2] memory);

    function archivedOptions(bytes32 _type, uint256 _index) external view returns (address);

    function optionTypes(uint256 _index) external view returns (bytes32);

    function factories(bytes32 _optionType) external view returns (address);

    function optionsRouter() external view returns (IOilerOptionsRouter);

    function getOptionTypesLength() external view returns (uint256);

    function getOptionTypeAt(uint256 _index) external view returns (bytes32);

    function getArchivedOptionsLength(string memory _optionType) external view returns (uint256);

    function getArchivedOptionsLength(bytes32 _optionType) external view returns (uint256);

    function getOptionTypeFactory(string memory _optionType) external view returns (address);

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory);

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory);

    function registerFactory(address factory) external;

    function setOptionsTypeFactory(string memory _optionType, address _factory) external;

    function registerOption(address _optionAddress, string memory _optionType) external;

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IOilerCollateral} from "./IOilerCollateral.sol";

interface IOilerOptionBase is IERC20, IERC20Permit {
    function optionType() external view returns (string memory);

    function collateralInstance() external view returns (IOilerCollateral);

    function isActive() external view returns (bool active);

    function hasExpired() external view returns (bool);

    function hasBeenExercised() external view returns (bool);

    function put() external view returns (bool);

    function write(uint256 _amount) external;

    function write(uint256 _amount, address _onBehalfOf) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IOilerOptionBase.sol";
import "./IOilerRegistry.sol";
import "./IBRouter.sol";

interface IOilerOptionsRouter {
    // TODO add expiration?
    struct Permit {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function registry() external view returns (IOilerRegistry);

    function bRouter() external view returns (IBRouter);

    function setUnlimitedApprovals(IOilerOptionBase _option) external;

    function write(IOilerOptionBase _option, uint256 _amount) external;

    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writePermit,
        Permit calldata _liquidityAddPermit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IBPool} from "./IBPool.sol";

interface IBRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 poolTokens);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 poolAmountIn
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function getPoolByTokens(address tokenA, address tokenB) external view returns (IBPool pool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBPool {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function balanceOf(address whom) external view returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function finalize() external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setPublicSwap(bool publicSwap) external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);

    function getCurrentTokens() external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IOilerCollateral is IERC20, IERC20Permit {
    function decimals() external view returns (uint8);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}