// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {WarpBaseV1} from "./base/WarpBase.sol";
import {ISolarFactory} from "../interface/solar/ISolarFactory.sol";
import {ISolarPair} from "../interface/solar/ISolarPair.sol";
import {ISolarRouter02} from "../interface/solar/ISolarRouter02.sol";
import {IWETH} from "../interface/solar/IWETH.sol";
import "../lib/errors.sol";

/// @author Nightwing from Yieldbay
/// @notice Implements the mechanism to add liquidity to any solarbeam.io liquidity pool from any ERC20 token or $MOVR.
/// @notice Lets you add liquidity from your preferred token in one transaction.
contract WarpInV1 is WarpBaseV1 {
    using SafeERC20 for IERC20;

    // SolarBeam contracts
    ISolarRouter02 public immutable solarRouter;
    ISolarFactory public immutable solarFactory;

    IWETH public immutable wMOVR;

    /// @notice Event to signify a "warpIn"
    /// @dev Emitted when liquidity is added successfully to a liquidity pool
    /// @dev If `from` is address(0), it represents $MOVR.
    /// @param sender address that called the `warpIn` function.
    /// @param from address of the token to provided by `sender` to add liquidity.
    /// @param pool address of the liquidity pool in which liquidity is added.
    /// @param amountToWarp amount of `from` token to add liquidity with.
    /// @param lpReceived amount of LP tokens of `pool` received by the `sender`.
    event WarpedIn(
        address indexed sender,
        IERC20 indexed from,
        ISolarPair indexed pool,
        uint256 amountToWarp,
        uint256 lpReceived
    );

    constructor(
        ISolarRouter02 _router,
        ISolarFactory _factory,
        IWETH _wMOVR
    ) {
        solarRouter = _router;
        solarFactory = _factory;
        wMOVR = _wMOVR;
    }

    /// @notice Function to add liquidity to the desired liquidity pool from an arbitrary ERC-20 token, or $MOVR.
    /// @dev if `fromToken` is address(0), represents that liquidity needs to be added from $MOVR.
    /// @dev `minimumLPBought` is a target value calculated off-chain. It acts as a check to protect against high-slippage scenarios.
    /// @dev `path0` and `path1` are swap paths passed directly to SolarbeamRouter for swaps. They're calculated off-chain to find the best swap route and increase capital effeciency.
    /// @param fromToken address of the token to add liquidity with.
    /// @param toPool address of the liquidity pool to add liquidity in.
    /// @param amountToWarp amount of `fromToken` to add liquidity with.
    /// @param minimumLPBought minimum amount of LP tokens that should be received by adding liquidity; Calculated off-chain.
    /// @param path0 an array of addresses that represent the swap path for token0 in `toPool`; Calculated off-chain.
    /// @param path1 an array of addresses that represent the swap path for token1 in `toPool`; Calculated off-chain.
    /// @return lpBought amount of LP tokens of `toPool` liquidity pool obtained by adding liquidity.
    function warpIn(
        IERC20 fromToken,
        ISolarPair toPool,
        uint256 amountToWarp,
        uint256 minimumLPBought,
        address[] memory path0,
        address[] memory path1
    ) external payable notPaused returns (uint256 lpBought) {
        if (amountToWarp == 0 && minimumLPBought == 0) revert ZeroAmount();

        // transfer the user's address to the contract
        _getTokens(fromToken, amountToWarp);

        // Warp-in from `fromToken`, to `toPool`.
        lpBought = _warpIn(fromToken, toPool, amountToWarp, path0, path1);

        // Revert is LPBought is lesser than minimumLPBought due to high slippage.
        if (lpBought < minimumLPBought) revert HighSlippage();

        emit WarpedIn(msg.sender, fromToken, toPool, amountToWarp, lpBought);
    }

    /// @notice Converts the `from` token to the tokens required to add liquidity in the `pool`, and adds liquidity in the `pool`.
    /// @dev An internal wrapper function that groups functionality of converting to the target tokens & adding liquidity.
    /// @dev if `from` is address(0), represents $MOVR.
    /// @param from address of the token to add liquidity with.
    /// @param pool address of the liquidity pool to add liquidity in.
    /// @param amount the amount of `from` tokens to add liquidity with.
    /// @param path0 an array of addresses that represent the swap path for token0 in `toPool`; Calculated off-chain.
    /// @param path1 an array of addresses that represent the swap path for token1 in `toPool`; Calculated off-chain.
    /// @return amount of LP tokens received from adding liquidity in the `pool`.
    function _warpIn(
        IERC20 from,
        ISolarPair pool,
        uint256 amount,
        address[] memory path0,
        address[] memory path1
    ) internal returns (uint256) {
        (IERC20 token0, IERC20 token1) = _fetchTokensFromPair(pool);

        (uint256 amount0, uint256 amount1) = _convertToTargetTokens(
            from,
            token0,
            token1,
            amount,
            path0,
            path1
        );

        return _addLiquidityForPair(token0, token1, amount0, amount1);
    }

    /// @notice Converts the `from` token to `token0` and `token1`.
    /// @notice By the end of it, the contract has the correct amounts of token0 and token1 required to add liquidity to the desired pool.
    /// @dev if `from` is address(0), represents $MOVR.
    /// @dev path0 is an empty array if `from` == `token0`; Because no need to convert `from` to `token0` in that case.
    /// @dev path1 is an empty array if `from` == `token1`; Because no need to convert `from` to `token1` in that case.
    /// @param from address of the token to add liquidity with.
    /// @param token0 address of the first token in the pool.
    /// @param token1 address of the second token in the pool.
    /// @param path0 an array of addresses that represent the swap path for token0 in `toPool`; Calculated off-chain.
    /// @param path1 an array of addresses that represent the swap path for token1 in `toPool`; Calculated off-chain.
    /// @return amount0 amount of `token0` to add liquidity with.
    /// @return amount1 amount of `token1` to add liquidity with.
    function _convertToTargetTokens(
        IERC20 from,
        IERC20 token0,
        IERC20 token1,
        uint256 amount,
        address[] memory path0,
        address[] memory path1
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint256 halfAmount;
        unchecked {
            halfAmount = amount / 2;
        }
        if (address(from) != address(token0)) {
            amount0 = _convertToken(from, token0, halfAmount, path0);
        } else {
            amount0 = halfAmount;
        }

        if (address(from) != address(token1)) {
            amount1 = _convertToken(from, token1, halfAmount, path1);
        } else {
            amount1 = halfAmount;
        }
    }

    /// @notice Converts `amount` of `from` token to `to` token.
    /// @dev Explain to a developer any extra details
    /// @dev path is an empty array when - `from` is $MOVR and `to` is $WMOVR.
    /// @param from address of starting token.
    /// @param to address of the destination token.
    /// @param path array of addresses that represent the swap path to swap `from` with `to`
    /// @return amount of `to` token acquired by the contract.
    function _convertToken(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        address[] memory path
    ) internal returns (uint256) {
        if (address(from) == address(0)) {
            wMOVR.deposit{value: amount}();

            if (address(to) == address(wMOVR)) {
                return amount;
            }

            return _swapTokens(IERC20(address(wMOVR)), amount, path);
        }

        return _swapTokens(from, amount, path);
    }

    /// @notice Adds liquidity to the liquidity pool that exists between `token0` and `token1`
    /// @dev Also, sends back to the msg.sender the residual amount of token0 and token1 left after adding liquidity.
    /// @param token0 address of the first token in the pair.
    /// @param token1 address of the second token in the pair.
    /// @param token0Amount amount of token0 to add liquidity with.
    /// @param token1Amount amount of token1 to add liquidity with.
    /// @return amount of LP tokens received by adding liquidity.
    function _addLiquidityForPair(
        IERC20 token0,
        IERC20 token1,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal returns (uint256) {
        // Approve the tokens
        token0.approve(address(solarRouter), token0Amount);
        token1.approve(address(solarRouter), token1Amount);

        // Add liquidity to the token0 & token1 pair
        (uint256 amount0, uint256 amount1, uint256 lpBought) = solarRouter
            .addLiquidity(
                address(token0),
                address(token1),
                token0Amount,
                token1Amount,
                1,
                1,
                msg.sender,
                block.timestamp
            );

        _returnResidual(token0, token0Amount, amount0);
        _returnResidual(token1, token1Amount, amount1);

        return lpBought;
    }

    /// @notice Swaps `from` token to the address last in path token through the solarbeam DEX
    /// @dev Explain to a developer any extra details
    /// @param from address of the starting token.
    /// @param amount amount of `from` token to swap.
    /// @param path an array of addresses that represent the swap path for `to` token; Calculated off-chain.
    /// @return amountBought the amount of `to` token received from the swap.
    function _swapTokens(
        IERC20 from,
        uint256 amount,
        address[] memory path
    ) internal returns (uint256 amountBought) {
        // Approve the solarRouter to spend the contract's `from` token.
        from.approve(address(solarRouter), amount);
        uint256 lastInPath = path.length - 1;

        // Swap the tokens through solarRouter
        amountBought = solarRouter.swapExactTokensForTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp
        )[lastInPath];
    }

    /// @notice Returns the residual tokens left after adding liquidity to the user.
    /// @param token address of the token to check for residue and send.
    /// @param initialAmount amount of `token` before it was used to add liquidity.
    /// @param amountUsed amount of `token` used to add liquidity.
    function _returnResidual(
        IERC20 token,
        uint256 initialAmount,
        uint256 amountUsed
    ) internal {
        if (initialAmount - amountUsed != 0) {
            token.safeTransfer(msg.sender, initialAmount - amountUsed);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISolarFactory} from "../../interface/solar/ISolarFactory.sol";
import {ISolarPair} from "../../interface/solar/ISolarPair.sol";
import {ISolarRouter02} from "../../interface/solar/ISolarRouter02.sol";
import {IWETH} from "../../interface/solar/IWETH.sol";

/// @title Base contract for WarpIn & WarpOut
/// @author Nightwing from Yieldbay
/// @notice Base layer for Warp contracts. Functionality to pause, un-pause, and common functions shared between WarpIn.sol & WarpOut.sol
contract WarpBaseV1 is Ownable {
    using SafeERC20 for IERC20;

    bool public paused = false;

    /// @notice Toggles the pause state. Only owner() can call.
    /// @dev If paused is true, sets it to false. If paused is false, sets it to true.
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    /// @notice Finds the addresses of the two tokens present in a Solarbeam liquidity pool.
    /// @param pair address of the solarbeam liquidity pool.
    /// @return token0 address of the first token in the liquidity pool pair.
    /// @return token1 address of the second token in the liquidity pool pair.
    function _fetchTokensFromPair(ISolarPair pair)
        internal
        view
        returns (IERC20 token0, IERC20 token1)
    {
        require(address(pair) != address(0), "PAIR_NOT_EXIST");

        token0 = IERC20(pair.token0());
        token1 = IERC20(pair.token1());
    }

    /// @notice Transfers the intended tokens from the address to the contract.
    /// @dev Used by WarpIn to obtain the token that the address wants to warp-in.
    /// @dev Used by WarpOut to obtain the LP tokens that the address wants to warp-out.
    /// @param from address of the token to transfer to the contract.
    /// @param amount the amount of `from` tokens to transfer to the contract.
    function _getTokens(IERC20 from, uint256 amount) internal {
        // If fromToken is zero address, transfer $MOVR
        if (address(from) != address(0)) {
            from.safeTransferFrom(msg.sender, address(this), amount);
            return;
        }
        require(amount == msg.value, "MOVR_NEQ_AMOUNT");
    }

    /// @notice Sends $MOVR to an address.
    /// @param amount amount of $MOVR to send.
    /// @param receiver destination address; where the $MOVR needs to be sent.
    function _sendNATIVE(uint256 amount, address payable receiver) internal {
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "SEND_VALUE_FAIL");
    }

    modifier notPaused() {
        require(!paused, "CONTRACT_PAUSED");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ISolarFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function auro() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;

    function setAuroAddress(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISolarPair is IERC20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./ISolarRouter01.sol";

interface ISolarRouter02 is ISolarRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// The chain's native token,
/// i.e., $MOVR for moonriver/solarbeam
/// and $GLMR for moonbeam/solarflare)
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./types.sol";

// BayRouter/warp
error ZeroAmount();
error HighSlippage();
error InvalidDestination(IERC20 destination);
error InsufficientAmount();
error InvalidToken(IERC20 token);
error SendValueFail();

// BayStrategy
error OnlyStrategist();
error OnlyVault();
error InvalidFee(FeeType feeType, uint256 fee);
error AddressNotUpdated(address addr, string message);
error ValueNotUpdated(uint256 value, string message);

// BayVault
error StrategyNotEnabled();
error InvalidDepositToken();
error AlreadyInitialized();
error NotInitialized();
error DuplicateStrategy();

// SolarStrategy
error InsufficientBalance();
error InsufficientAllowance();
error InvalidRoute(string message);
error SlippageOutOfBounds(uint256 value);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ISolarRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path,
        uint256 fee
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path,
        uint256 fee
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

enum FeeType {
    StrategistFee,
    VaultFee,
    HarvestReward
}