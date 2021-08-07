// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IKeeperSubsidyPool.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IEToken.sol";
import "./interfaces/IEPoolPeriphery.sol";
import "./interfaces/IEPool.sol";
import "./utils/ControllerMixin.sol";
import "./utils/TokenUtils.sol";

import "./EPoolLibrary.sol";

contract EPoolPeriphery is ControllerMixin, IEPoolPeriphery {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;
    using TokenUtils for IEToken;

    address public immutable override factory;
    address public immutable override router;
    // Keeper subsidy pool for making rebalancing via flash swaps capital neutral for msg.sender
    IKeeperSubsidyPool public immutable override keeperSubsidyPool;
    // supported EPools by the periphery
    mapping(address => bool) public override ePools;
    // max. allowed slippage between EPool oracle and uniswap when executing a flash swap
    // 1.0e18 is defined as no slippage, 1.03e18 == 3% slippage, if < 1.0e18 then swap always has to make a profit
    uint256 public override maxFlashSwapSlippage;

    event IssuedEToken(
        address indexed ePool, address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user
    );
    event RedeemedEToken(
        address indexed ePool, address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user
    );
    event SetEPoolApproval(address indexed ePool, bool approval);
    event SetMaxFlashSwapSlippage(uint256 maxFlashSwapSlippage);
    event RecoveredToken(address token, uint256 amount);

    /**
     * @param _controller Address of the controller
     * @param _factory Address of the Uniswap V2 factory
     * @param _router Address of the Uniswap V2 router
     * @param _keeperSubsidyPool Address of keeper subsidiy pool
     * @param _maxFlashSwapSlippage Max. allowed slippage EPool oracle vs. Uniswap. See var. decl. for valid inputs.
     */
    constructor(
        IController _controller,
        address _factory,
        address _router,
        IKeeperSubsidyPool _keeperSubsidyPool,
        uint256 _maxFlashSwapSlippage
    ) ControllerMixin(_controller) {
        factory = _factory;
        router = _router;
        keeperSubsidyPool = _keeperSubsidyPool;
        maxFlashSwapSlippage = _maxFlashSwapSlippage; // e.g. 1.05e18 -> 5% slippage
    }

    /**
     * @notice Returns the address of the Controller
     * @return Address of Controller
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(address _controller) external override onlyDao("EPoolPeriphery: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Give or revoke approval a EPool for the EPoolPeriphery
     * @dev Can only called by the DAO or the guardian
     * @param ePool Address of the EPool
     * @param approval Boolean on whether approval for EPool should be given or revoked
     * @return True on success
     */
    function setEPoolApproval(
        IEPool ePool,
        bool approval
    ) external override onlyDaoOrGuardian("EPoolPeriphery: not dao or guardian") returns (bool) {
        if (approval) {
            // assuming EPoolPeriphery only holds funds within calls
            ePool.tokenA().approve(address(ePool), type(uint256).max);
            ePool.tokenB().approve(address(ePool), type(uint256).max);
            ePools[address(ePool)] = true;
        } else {
            ePool.tokenA().approve(address(ePool), 0);
            ePool.tokenB().approve(address(ePool), 0);
            ePools[address(ePool)] = false;
        }
        emit SetEPoolApproval(address(ePool), approval);
        return true;
    }

    /**
     * @notice Set max. slippage between EPool oracle and uniswap when performing flash swap
     * See variable declaration for valid inputs.
     * @dev Can only be callede by the DAO or the guardian
     * @param _maxFlashSwapSlippage Max. flash swap slippage
     * @return True on success
     */
    function setMaxFlashSwapSlippage(
        uint256 _maxFlashSwapSlippage
    ) external override onlyDaoOrGuardian("EPoolPeriphery: not dao or guardian") returns (bool) {
        maxFlashSwapSlippage = _maxFlashSwapSlippage;
        emit SetMaxFlashSwapSlippage(maxFlashSwapSlippage);
        return true;
    }

    /**
     * @notice Issues an amount of EToken for maximum amount of TokenA
     * @dev Reverts if maxInputAmountA is exceeded. Unused amount of TokenA is refunded to msg.sender.
     * Requires setting allowance for TokenA.
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to issue
     * @param maxInputAmountA Max. amount of TokenA to deposit
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function issueForMaxTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountA,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        tokenA.safeTransferFrom(msg.sender, address(this), maxInputAmountA);
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            t, amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        // swap part of input amount for amountB
        require(maxInputAmountA >= amountA, "EPoolPeriphery: insufficient max. input");
        uint256 amountAToSwap = maxInputAmountA - amountA;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        tokenA.approve(router, amountAToSwap);
        uint256[] memory amountsOut = IUniswapV2Router01(router).swapTokensForExactTokens(
            amountB, amountAToSwap, path, address(this), deadline
        );
        // do the deposit (TokenA is already approved)
        ePool.issueExact(eToken, amount);
        // transfer EToken to msg.sender
        IERC20(eToken).safeTransfer(msg.sender, amount);
        // refund unused maxInputAmountA -= amountA + amountASwappedForAmountB
        tokenA.safeTransfer(msg.sender, maxInputAmountA - amountA - amountsOut[0]);
        emit IssuedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Issues an amount of EToken for maximum amount of TokenB
     * @dev Reverts if maxInputAmountB is exceeded. Unused amount of TokenB is refunded to msg.sender.
     * Requires setting allowance for TokenB.
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to issue
     * @param maxInputAmountB Max. amount of TokenB to deposit
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function issueForMaxTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountB,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        tokenB.safeTransferFrom(msg.sender, address(this), maxInputAmountB);
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            t, amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        // swap part of input amount for amountB
        require(maxInputAmountB >= amountB, "EPoolPeriphery: insufficient max. input");
        uint256 amountBToSwap = maxInputAmountB - amountB;
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        tokenB.approve(router, amountBToSwap);
        uint256[] memory amountsOut = IUniswapV2Router01(router).swapTokensForExactTokens(
            amountA, amountBToSwap, path, address(this), deadline
        );
        // do the deposit (TokenB is already approved)
        ePool.issueExact(eToken, amount);
        // transfer EToken to msg.sender
        IERC20(eToken).safeTransfer(msg.sender, amount);
        // refund unused maxInputAmountB -= amountB + amountBSwappedForAmountA
        tokenB.safeTransfer(msg.sender, maxInputAmountB - amountB - amountsOut[0]);
        emit IssuedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Redeems an amount of EToken for a min. amount of TokenA
     * @dev Reverts if minOutputA is not met. Requires setting allowance for EToken
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to redeem
     * @param minOutputA Min. amount of TokenA to withdraw
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function redeemForMinTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputA,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        IERC20(eToken).safeTransferFrom(msg.sender, address(this), amount);
        // do the withdraw
        IERC20(eToken).approve(address(ePool), amount);
        (uint256 amountA, uint256 amountB) = ePool.redeemExact(eToken, amount);
        // convert amountB withdrawn from EPool into TokenA
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        tokenB.approve(router, amountB);
        uint256[] memory amountsOut = IUniswapV2Router01(router).swapExactTokensForTokens(
            amountB, 0, path, address(this), deadline
        );
        uint256 outputA = amountA + amountsOut[1];
        require(outputA >= minOutputA, "EPoolPeriphery: insufficient output amount");
        IERC20(tokenA).safeTransfer(msg.sender, outputA);
        emit RedeemedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Redeems an amount of EToken for a min. amount of TokenB
     * @dev Reverts if minOutputB is not met. Requires setting allowance for EToken
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to redeem
     * @param minOutputB Min. amount of TokenB to withdraw
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function redeemForMinTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputB,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        IERC20(eToken).safeTransferFrom(msg.sender, address(this), amount);
        // do the withdraw
        IERC20(eToken).approve(address(ePool), amount);
        (uint256 amountA, uint256 amountB) = ePool.redeemExact(eToken, amount);
        // convert amountB withdrawn from EPool into TokenA
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        tokenA.approve(router, amountA);
        uint256[] memory amountsOut = IUniswapV2Router01(router).swapExactTokensForTokens(
            amountA, 0, path, address(this), deadline
        );
        uint256 outputB = amountB + amountsOut[1];
        require(outputB >= minOutputB, "EPoolPeriphery: insufficient output amount");
        IERC20(tokenB).safeTransfer(msg.sender, outputB);
        emit RedeemedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Rebalances a EPool. Capital required for rebalancing is obtained via a flash swap.
     * The potential slippage between the EPool oracle and uniswap is covered by the KeeperSubsidyPool.
     * @dev Fails if maxFlashSwapSlippage is exceeded in uniswapV2Call
     * @param ePool Address of the EPool to rebalance
     * @param fracDelta Fraction of the delta to rebalance (1e18 for rebalancing the entire delta)
     * @return True on success
     */
    function rebalanceWithFlashSwap(
        IEPool ePool,
        uint256 fracDelta
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (address tokenA, address tokenB) = (address(ePool.tokenA()), address(ePool.tokenB()));
        (uint256 deltaA, uint256 deltaB, uint256 rChange) = EPoolLibrary.delta(
            ePool.getTranches(), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(address(tokenA), address(tokenB)));
        // map deltaA, deltaB to amountOut0, amountOut1
        uint256 amountOut0; uint256 amountOut1;
        if (rChange == 0) {
            (amountOut0, amountOut1) = (address(tokenA) == pair.token0())
                ? (uint256(0), deltaB) : (deltaB, uint256(0));
        } else {
            (amountOut0, amountOut1) = (address(tokenA) == pair.token0())
                ? (deltaA, uint256(0)) : (uint256(0), deltaA);
        }
        bytes memory data = abi.encode(ePool, fracDelta);
        pair.swap(amountOut0, amountOut1, address(this), data);
        return true;
    }

    /**
     * @notice rebalanceAllWithFlashSwap callback called by the uniswap pair
     * @dev Trusts that deltas are actually forwarded by the EPool.
     * Verifies that funds are forwarded from flash swap of the uniswap pair.
     * param sender Address of the flash swap initiator
     * param amount0
     * param amount1
     * @param data Data forwarded in the flash swap
     */
    function uniswapV2Call(
        address /* sender */, // skip sender check, check for forwarded funds by flash swap is sufficient
        uint256 /* amount0 */,
        uint256 /* amount1 */,
        bytes calldata data
    ) external {
        (IEPool ePool, uint256 fracDelta) = abi.decode(data, (IEPool, uint256));
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        // fails if no funds are forwarded in the flash swap callback from the uniswap pair
        // TokenA, TokenB are already approved
        (uint256 deltaA, uint256 deltaB, uint256 rChange) = ePool.rebalance(fracDelta);
        address[] memory path = new address[](2); // [0] flash swap repay token, [1] flash lent token
        uint256 amountsIn; // flash swap repay amount
        uint256 deltaOut;
        if (rChange == 0) {
            // release TokenA, add TokenB to EPool -> flash swap TokenB, repay with TokenA
            path[0] = address(ePool.tokenA()); path[1] = address(ePool.tokenB());
            (amountsIn, deltaOut) = (IUniswapV2Router01(router).getAmountsIn(deltaB, path)[0], deltaA);
        } else {
            // add TokenA, release TokenB to EPool -> flash swap TokenA, repay with TokenB
            path[0] = address(ePool.tokenB()); path[1] = address(ePool.tokenA());
            (amountsIn, deltaOut) = (IUniswapV2Router01(router).getAmountsIn(deltaA, path)[0], deltaB);
        }
        // if slippage is negative request subsidy, if positive top of KeeperSubsidyPool
        if (amountsIn > deltaOut) {
            require(
                amountsIn * EPoolLibrary.sFactorI / deltaOut <= maxFlashSwapSlippage,
                "EPoolPeriphery: excessive slippage"
            );
            keeperSubsidyPool.requestSubsidy(path[0], amountsIn - deltaOut);
        } else if (amountsIn < deltaOut) {
            IERC20(path[0]).safeTransfer(address(keeperSubsidyPool), deltaOut - amountsIn);
        }
        // repay flash swap by sending amountIn to pair
        IERC20(path[0]).safeTransfer(msg.sender, amountsIn);
    }

    /**
     * @notice Recovers untracked amounts
     * @dev Can only called by an authorized sender
     * @param token Address of the token
     * @param amount Amount to recover
     * @return True on success
     */
    function recover(IERC20 token, uint256 amount) external override onlyDao("EPool: not dao") returns (bool) {
        token.safeTransfer(msg.sender, amount);
        emit RecoveredToken(address(token), amount);
        return true;
    }

    /* ------------------------------------------------------------------------------------------------------- */
    /* view and pure methods                                                                                   */
    /* ------------------------------------------------------------------------------------------------------- */

    function minInputAmountAForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 minTokenA) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenA());
        path[1] = address(ePool.tokenB());
        minTokenA = amountA + IUniswapV2Router01(router).getAmountsIn(amountB, path)[0];
    }

    // does not include price impact, which would result in a smaller EToken amount
    function eTokenForMinInputAmountA_Unsafe(
        IEPool ePool,
        address eToken,
        uint256 minInputAmountA
    ) external view returns (uint256 amount) {
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        uint256 rate = ePool.getRate();
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 ratio = EPoolLibrary.currentRatio(t, rate, sFactorA, sFactorB);
        (uint256 amountAIdeal, uint256 amountBIdeal) = EPoolLibrary.tokenATokenBForTokenA(
            minInputAmountA, ratio, rate, sFactorA, sFactorB
        );
        return EPoolLibrary.eTokenForTokenATokenB(t, amountAIdeal, amountBIdeal, rate, sFactorA, sFactorB);
    }

    function minInputAmountBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 minTokenB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenB());
        path[1] = address(ePool.tokenA());
        minTokenB = amountB + IUniswapV2Router01(router).getAmountsIn(amountA, path)[0];
    }

    // does not include price impact, which would result in a smaller EToken amount
    function eTokenForMinInputAmountB_Unsafe(
        IEPool ePool,
        address eToken,
        uint256 minInputAmountB
    ) external view returns (uint256 amount) {
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        uint256 rate = ePool.getRate();
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 ratio = EPoolLibrary.currentRatio(t, rate, sFactorA, sFactorB);
        (uint256 amountAIdeal, uint256 amountBIdeal) = EPoolLibrary.tokenATokenBForTokenB(
            minInputAmountB, ratio, rate, sFactorA, sFactorB
        );
        return EPoolLibrary.eTokenForTokenATokenB(t, amountAIdeal, amountBIdeal, rate, sFactorA, sFactorB);
    }

    function maxOutputAmountAForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 maxTokenA) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        uint256 feeRate = ePool.feeRate();
        amountA = amountA - amountA * feeRate / EPoolLibrary.sFactorI;
        amountB = amountB - amountB * feeRate / EPoolLibrary.sFactorI;
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenB());
        path[1] = address(ePool.tokenA());
        maxTokenA = amountA + IUniswapV2Router01(router).getAmountsOut(amountB, path)[1];
    }

    function maxOutputAmountBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 maxTokenB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        uint256 feeRate = ePool.feeRate();
        amountA = amountA - amountA * feeRate / EPoolLibrary.sFactorI;
        amountB = amountB - amountB * feeRate / EPoolLibrary.sFactorI;
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenA());
        path[1] = address(ePool.tokenB());
        maxTokenB = amountB + IUniswapV2Router01(router).getAmountsOut(amountA, path)[1];
    }
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;


interface IKeeperSubsidyPool {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function setBeneficiary(address beneficiary, bool canRequest) external returns (bool);

    function isBeneficiary(address beneficiary) external view returns (bool);

    function requestSubsidy(address token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed tokenA, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amountA);
  event Burn(address indexed sender, uint amount0, uint amountA, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amountAIn,
      uint amount0Out,
      uint amountAOut,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserveA);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function tokenA() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserveA, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amountA);
  function swap(uint amount0Out, uint amountAOut, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEToken is IERC20 {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IKeeperSubsidyPool.sol";
import "./IUniswapRouterV2.sol";
import "./IUniswapFactory.sol";
import "./IEPool.sol";

interface IEPoolPeriphery {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function factory() external view returns (address);

    function router() external view returns (address);

    function ePools(address) external view returns (bool);

    function keeperSubsidyPool() external view returns (IKeeperSubsidyPool);

    function maxFlashSwapSlippage() external view returns (uint256);

    function setEPoolApproval(IEPool ePool, bool approval) external returns (bool);

    function setMaxFlashSwapSlippage(uint256 _maxFlashSwapSlippage) external returns (bool);

    function issueForMaxTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountA,
        uint256 deadline
    ) external returns (bool);

    function issueForMaxTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountB,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputA,
        uint256 deadline
    ) external returns (bool);

    function redeemForMinTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputB,
        uint256 deadline
    ) external returns (bool);

    function rebalanceWithFlashSwap(IEPool ePool, uint256 fracDelta) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEToken.sol";

interface IEPool {
    struct Tranche {
        IEToken eToken;
        uint256 sFactorE;
        uint256 reserveA;
        uint256 reserveB;
        uint256 targetRatio;
        uint256 rebalancedAt;
    }

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function tokenA() external view returns (IERC20);

    function tokenB() external view returns (IERC20);

    function sFactorA() external view returns (uint256);

    function sFactorB() external view returns (uint256);

    function getTranche(address eToken) external view returns (Tranche memory);

    function getTranches() external view returns(Tranche[] memory _tranches);

    function addTranche(uint256 targetRatio, string memory eTokenName, string memory eTokenSymbol) external returns (bool);

    function getAggregator() external view returns (address);

    function setAggregator(address oracle, bool inverseRate) external returns (bool);

    function rebalanceMode() external view returns (uint256);

    function rebalanceMinRDiv() external view returns (uint256);

    function rebalanceInterval() external view returns (uint256);

    function setRebalanceMode(uint256 mode) external returns (bool);

    function setRebalanceMinRDiv(uint256 minRDiv) external returns (bool);

    function setRebalanceInterval(uint256 interval) external returns (bool);

    function feeRate() external view returns (uint256);

    function cumulativeFeeA() external view returns (uint256);

    function cumulativeFeeB() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external returns (bool);

    function transferFees() external returns (bool);

    function getRate() external view returns (uint256);

    function rebalance(uint256 fracDelta) external returns (uint256 deltaA, uint256 deltaB, uint256 rChange);

    function issueExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function redeemExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "../interfaces/IController.sol";

contract ControllerMixin {
    event SetController(address controller);

    IController internal controller;

    constructor(IController _controller) {
        controller = _controller;
    }

    modifier onlyDao(string memory revertMsg) {
        require(msg.sender == controller.dao(), revertMsg);
        _;
    }

    modifier onlyDaoOrGuardian(string memory revertMsg) {
        require(controller.isDaoOrGuardian(msg.sender), revertMsg);
        _;
    }

    modifier issuanceNotPaused(string memory revertMsg) {
        require(controller.pausedIssuance() == false, revertMsg);
        _;
    }

    function _setController(address _controller) internal {
        controller = IController(_controller);
        emit SetController(_controller);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC20Optional.sol";

library TokenUtils {
    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "TokenUtils: no decimals");
        uint8 _decimals = abi.decode(data, (uint8));
        return _decimals;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IETokenFactory.sol";
import "./interfaces/IEToken.sol";
import "./interfaces/IEPool.sol";
import "./utils/TokenUtils.sol";
import "./utils/Math.sol";

library EPoolLibrary {
    using TokenUtils for IERC20;

    uint256 internal constant sFactorI = 1e18; // internal scaling factor (18 decimals)

    /**
     * @notice Returns the target ratio if reserveA and reserveB are 0 (for initial deposit)
     * currentRatio := (reserveA denominated in tokenB / reserveB denominated in tokenB) with decI decimals
     */
    function currentRatio(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        if (t.reserveA == 0 || t.reserveB == 0) {
            if (t.reserveA == 0 && t.reserveB == 0) return t.targetRatio;
            if (t.reserveA == 0) return 0;
            if (t.reserveB == 0) return type(uint256).max;
        }
        return ((t.reserveA * rate / sFactorA) * sFactorI) / (t.reserveB * sFactorI / sFactorB);
    }

    /**
     * @notice Returns the deviation of reserveA and reserveB from target ratio
     * currentRatio >= targetRatio: release TokenA liquidity and add TokenB liquidity --> rChange = 0
     * currentRatio < targetRatio: add TokenA liquidity and release TokenB liquidity --> rChange = 1
     * deltaA := abs(t.reserveA, (t.reserveB / rate * t.targetRatio)) / (1 + t.targetRatio)
     * deltaB := deltaA * rate
     * rChange := 0 if currentRatio >= targetRatio, 1 if currentRatio < targetRatio
     * rDiv := 1 - (currentRatio / targetRatio)
     */
    function trancheDelta(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        uint256 ratio = currentRatio(t, rate, sFactorA, sFactorB);
        if (ratio < t.targetRatio) {
            (rChange, rDiv) = (1, sFactorI - (ratio * sFactorI / t.targetRatio));
        } else {
            (rChange, rDiv) = (
                0, (ratio == type(uint256).max) ? type(uint256).max : (ratio * sFactorI / t.targetRatio) - sFactorI
            );
        }
        deltaA = (
            Math.abs(t.reserveA, tokenAForTokenB(t.reserveB, t.targetRatio, rate, sFactorA, sFactorB)) * sFactorA
        ) / (sFactorA + (t.targetRatio * sFactorA / sFactorI));
        // (convert to TokenB precision first to avoid altering deltaA)
        deltaB = ((deltaA * sFactorB / sFactorA) * rate) / sFactorI;
        // round to 0 in case of rounding errors
        if (deltaA == 0 || deltaB == 0) (deltaA, deltaB, rChange, rDiv) = (0, 0, 0, 0);
    }

    /**
     * @notice Returns the sum of the tranches total deltas (summed up tranche deltaA and deltaB)
     */
    function delta(
        IEPool.Tranche[] memory ts,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange) {
        int256 totalDeltaA;
        int256 totalDeltaB;
        for (uint256 i = 0; i < ts.length; i++) {
            (uint256 _deltaA, uint256 _deltaB, uint256 _rChange,) = trancheDelta(ts[i], rate, sFactorA, sFactorB);
            if (_rChange == 0) {
                (totalDeltaA, totalDeltaB) = (totalDeltaA - int256(_deltaA), totalDeltaB + int256(_deltaB));
            } else {
                (totalDeltaA, totalDeltaB) = (totalDeltaA + int256(_deltaA), totalDeltaB - int256(_deltaB));
            }
        }
        if (totalDeltaA > 0 && totalDeltaB < 0)  {
            (deltaA, deltaB, rChange) = (uint256(totalDeltaA), uint256(-totalDeltaB), 1);
        } else if (totalDeltaA < 0 && totalDeltaB > 0) {
            (deltaA, deltaB, rChange) = (uint256(-totalDeltaA), uint256(totalDeltaB), 0);
        }
    }

    /**
     * @notice how much EToken can be issued, redeemed for amountA and amountB
     * initial issuance / last redemption: sqrt(amountA * amountB)
     * subsequent issuances / non nullifying redemptions: claim on reserve * EToken total supply
     */
    function eTokenForTokenATokenB(
        IEPool.Tranche memory t,
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256) {
        uint256 amountsA = totalA(amountA, amountB, rate, sFactorA, sFactorB);
        if (t.reserveA + t.reserveB == 0) {
            return (Math.sqrt((amountsA * t.sFactorE / sFactorA) * t.sFactorE));
        }
        uint256 reservesA = totalA(t.reserveA, t.reserveB, rate, sFactorA, sFactorB);
        uint256 share = ((amountsA * t.sFactorE / sFactorA) * t.sFactorE) / (reservesA * t.sFactorE / sFactorA);
        return share * t.eToken.totalSupply() / t.sFactorE;
    }

    /**
     * @notice Given an amount of EToken, how much TokenA and TokenB have to be deposited, withdrawn for it
     * initial issuance / last redemption: sqrt(amountA * amountB) -> such that the inverse := EToken amount ** 2
     * subsequent issuances / non nullifying redemptions: claim on EToken supply * reserveA/B
     */
    function tokenATokenBForEToken(
        IEPool.Tranche memory t,
        uint256 amount,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (t.reserveA + t.reserveB == 0) {
            uint256 amountsA = amount * sFactorA / t.sFactorE;
            (amountA, amountB) = tokenATokenBForTokenA(
                amountsA * amountsA / sFactorA , t.targetRatio, rate, sFactorA, sFactorB
            );
        } else {
            uint256 eTokenTotalSupply = t.eToken.totalSupply();
            if (eTokenTotalSupply == 0) return(0, 0);
            uint256 share = amount * t.sFactorE / eTokenTotalSupply;
            amountA = share * t.reserveA / t.sFactorE;
            amountB = share * t.reserveB / t.sFactorE;
        }
    }

    /**
     * @notice Given amountB, which amountA is required such that amountB / amountA is equal to the ratio
     * amountA := amountBInTokenA * ratio
     */
    function tokenAForTokenB(
        uint256 amountB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountB * sFactorI / sFactorB) * ratio) / rate) * sFactorA / sFactorI;
    }

    /**
     * @notice Given amountA, which amountB is required such that amountB / amountA is equal to the ratio
     * amountB := amountAInTokenB / ratio
     */
    function tokenBForTokenA(
        uint256 amountA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountA * sFactorI / sFactorA) * rate) / ratio) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenA, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := total - (total / (1 + ratio)) == (total * ratio) / (1 + ratio)
     * amountB := (total / (1 + ratio)) * rate
     */
    function tokenATokenBForTokenA(
        uint256 _totalA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = _totalA - (_totalA * sFactorI / (sFactorI + ratio));
        amountB = (((_totalA * sFactorI / sFactorA) * rate) / (sFactorI + ratio)) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenB, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := (total * ratio) / (rate * (1 + ratio))
     * amountB := total / (1 + ratio)
     */
    function tokenATokenBForTokenB(
        uint256 _totalB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = ((((_totalB * sFactorI / sFactorB) * ratio) / (sFactorI + ratio)) * sFactorA) / rate;
        amountB = (_totalB * sFactorI) / (sFactorI + ratio);
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenA
     * totalA := amountA + (amountB / rate)
     */
    function totalA(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalA) {
        return amountA + ((((amountB * sFactorI / sFactorB) * sFactorI) / rate) * sFactorA) / sFactorI;
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenB
     * totalB := amountB + (amountA * rate)
     */
    function totalB(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalB) {
        return amountB + ((amountA * rate / sFactorA) * sFactorB) / sFactorI;
    }

    /**
     * @notice Return the withdrawal fee for a given amount of TokenA and TokenB
     * feeA := amountA * feeRate
     * feeB := amountB * feeRate
     */
    function feeAFeeBForTokenATokenB(
        uint256 amountA,
        uint256 amountB,
        uint256 feeRate
    ) internal pure returns (uint256 feeA, uint256 feeB) {
        feeA = amountA * feeRate / EPoolLibrary.sFactorI;
        feeB = amountB * feeRate / EPoolLibrary.sFactorI;
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

interface IController {

    function dao() external view returns (address);

    function guardian() external view returns (address);

    function isDaoOrGuardian(address sender) external view returns (bool);

    function setDao(address _dao) external returns (bool);

    function setGuardian(address _guardian) external returns (bool);

    function feesOwner() external view returns (address);

    function pausedIssuance() external view returns (bool);

    function setFeesOwner(address _feesOwner) external returns (bool);

    function setPausedIssuance(bool _pausedIssuance) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

/**
 * @dev Interface of the the optional methods of the ERC20 standard as defined in the EIP.
 */
interface IERC20Optional {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IEToken.sol";

interface IETokenFactory {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function createEToken(string memory name, string memory symbol) external returns (IEToken);
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.1;

library Math {

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
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