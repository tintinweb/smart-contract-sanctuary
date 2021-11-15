// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./amm/interfaces/ITempusAMM.sol";
import "./amm/interfaces/IVault.sol";
import "./ITempusPool.sol";
import "./math/Fixed256x18.sol";
import "./utils/PermanentlyOwnable.sol";
import "./utils/AMMBalancesHelper.sol";
import "./utils/UntrustedERC20.sol";

contract TempusController is PermanentlyOwnable, ReentrancyGuard {
    using Fixed256x18 for uint256;
    using SafeERC20 for IERC20;
    using UntrustedERC20 for IERC20;
    using AMMBalancesHelper for uint256[];

    /// @dev Event emitted on a successful BT/YBT deposit.
    /// @param pool The Tempus Pool to which assets were deposited
    /// @param depositor Address of the user who deposited Yield Bearing Tokens to mint
    ///                  Tempus Principal Share (TPS) and Tempus Yield Shares
    /// @param recipient Address of the recipient who will receive TPS and TYS tokens
    /// @param yieldTokenAmount Amount of yield tokens received from underlying pool
    /// @param backingTokenValue Value of @param yieldTokenAmount expressed in backing tokens
    /// @param shareAmounts Number of Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS) granted to `recipient`
    /// @param interestRate Interest Rate of the underlying pool from Yield Bearing Tokens to the underlying asset
    /// @param fee The fee which was deducted (in terms of yield bearing tokens)
    event Deposited(
        address indexed pool,
        address indexed depositor,
        address indexed recipient,
        uint256 yieldTokenAmount,
        uint256 backingTokenValue,
        uint256 shareAmounts,
        uint256 interestRate,
        uint256 fee
    );

    /// @dev Event emitted on a successful BT/YBT redemption.
    /// @param pool The Tempus Pool from which Tempus Shares were redeemed
    /// @param redeemer Address of the user whose Shares (Principals and Yields) are redeemed
    /// @param recipient Address of user that recieved Yield Bearing Tokens
    /// @param principalShareAmount Number of Tempus Principal Shares (TPS) to redeem into the Yield Bearing Token (YBT)
    /// @param yieldShareAmount Number of Tempus Yield Shares (TYS) to redeem into the Yield Bearing Token (YBT)
    /// @param yieldTokenAmount Number of Yield bearing tokens redeemed from the pool
    /// @param backingTokenValue Value of @param yieldTokenAmount expressed in backing tokens
    /// @param interestRate Interest Rate of the underlying pool from Yield Bearing Tokens to the underlying asset
    /// @param fee The fee which was deducted (in terms of yield bearing tokens)
    /// @param isEarlyRedeem True in case of early redemption, otherwise false
    event Redeemed(
        address indexed pool,
        address indexed redeemer,
        address indexed recipient,
        uint256 principalShareAmount,
        uint256 yieldShareAmount,
        uint256 yieldTokenAmount,
        uint256 backingTokenValue,
        uint256 interestRate,
        uint256 fee,
        bool isEarlyRedeem
    );

    /// @dev Atomically deposits YBT/BT to TempusPool and provides liquidity
    ///      to the corresponding Tempus AMM with the issued TYS & TPS
    /// @param tempusAMM Tempus AMM to use to swap TYS for TPS
    /// @param tokenAmount Amount of YBT/BT to be deposited
    /// @param isBackingToken specifies whether the deposited asset is the Backing Token or Yield Bearing Token
    function depositAndProvideLiquidity(
        ITempusAMM tempusAMM,
        uint256 tokenAmount,
        bool isBackingToken
    ) external payable nonReentrant {
        _depositAndProvideLiquidity(tempusAMM, tokenAmount, isBackingToken);
    }

    /// @dev Atomically deposits YBT/BT to TempusPool and swaps TYS for TPS to get fixed yield
    ///      See https://docs.balancer.fi/developers/guides/single-swaps#swap-overview
    /// @param tempusAMM Tempus AMM to use to swap TYS for TPS
    /// @param tokenAmount Amount of YBT/BT to be deposited in underlying YBT/BT decimal precision
    /// @param isBackingToken specifies whether the deposited asset is the Backing Token or Yield Bearing Token
    /// @param minTYSRate Minimum exchange rate of TYS (denominated in TPS) to receive in exchange for TPS
    function depositAndFix(
        ITempusAMM tempusAMM,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 minTYSRate
    ) external payable nonReentrant {
        _depositAndFix(tempusAMM, tokenAmount, isBackingToken, minTYSRate);
    }

    /// @dev Deposits Yield Bearing Tokens to a Tempus Pool.
    /// @param targetPool The Tempus Pool to which tokens will be deposited
    /// @param yieldTokenAmount amount of Yield Bearing Tokens to be deposited
    ///                         in YBT Contract precision which can be 18 or 8 decimals
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    function depositYieldBearing(
        ITempusPool targetPool,
        uint256 yieldTokenAmount,
        address recipient
    ) public nonReentrant {
        _depositYieldBearing(targetPool, yieldTokenAmount, recipient);
    }

    /// @dev Deposits Backing Tokens into the underlying protocol and
    ///      then deposited the minted Yield Bearing Tokens to the Tempus Pool.
    /// @param targetPool The Tempus Pool to which tokens will be deposited
    /// @param backingTokenAmount amount of Backing Tokens to be deposited into the underlying protocol
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    function depositBacking(
        ITempusPool targetPool,
        uint256 backingTokenAmount,
        address recipient
    ) public payable nonReentrant {
        _depositBacking(targetPool, backingTokenAmount, recipient);
    }

    /// @dev Redeem TPS+TYS held by msg.sender into Yield Bearing Tokens
    /// @notice `msg.sender` must approve Principals and Yields amounts to `targetPool`
    /// @notice `msg.sender` will receive yield bearing tokens
    /// @notice Before maturity, `principalAmount` must equal to `yieldAmount`
    /// @param targetPool The Tempus Pool from which to redeem Tempus Shares
    /// @param sender Address of user whose Shares are going to be redeemed
    /// @param principalAmount Amount of Tempus Principals to redeem in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yields to redeem in YieldShare decimal precision
    /// @param recipient Address of user that will recieve yield bearing tokens
    function redeemToYieldBearing(
        ITempusPool targetPool,
        address sender,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    ) public nonReentrant {
        _redeemToYieldBearing(targetPool, sender, principalAmount, yieldAmount, recipient);
    }

    /// @dev Redeem TPS+TYS held by msg.sender into Backing Tokens
    /// @notice `sender` must approve Principals and Yields amounts to this TempusPool
    /// @notice `recipient` will receive the backing tokens
    /// @notice Before maturity, `principalAmount` must equal to `yieldAmount`
    /// @param targetPool The Tempus Pool from which to redeem Tempus Shares
    /// @param sender Address of user whose Shares are going to be redeemed
    /// @param principalAmount Amount of Tempus Principals to redeem in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yields to redeem in YieldShare decimal precision
    /// @param recipient Address of user that will recieve yield bearing tokens
    function redeemToBacking(
        ITempusPool targetPool,
        address sender,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    ) public nonReentrant {
        _redeemToBacking(targetPool, sender, principalAmount, yieldAmount, recipient);
    }

    /// @dev Withdraws liquidity from TempusAMM
    /// @notice `msg.sender` needs to approve controller for @param lpTokensAmount of LP tokens
    /// @notice Transfers LP tokens to controller and exiting tempusAmm with `msg.sender` as recipient
    /// @param tempusAMM Tempus AMM instance
    /// @param lpTokensAmount Amount of LP tokens to be withdrawn
    /// @param principalAmountOutMin Minimal amount of TPS to be withdrawn
    /// @param yieldAmountOutMin Minimal amount of TYS to be withdrawn
    /// @param toInternalBalances Withdrawing liquidity to internal balances
    function exitTempusAMM(
        ITempusAMM tempusAMM,
        uint256 lpTokensAmount,
        uint256 principalAmountOutMin,
        uint256 yieldAmountOutMin,
        bool toInternalBalances
    ) external nonReentrant {
        _exitTempusAMM(tempusAMM, lpTokensAmount, principalAmountOutMin, yieldAmountOutMin, toInternalBalances);
    }

    /// @dev Withdraws liquidity from TempusAMM and redeems Shares to Yield Bearing or Backing Tokens
    ///      Checks user's balance of principal shares and yield shares
    ///      and exits AMM with exact amounts needed for redemption.
    /// @notice `msg.sender` needs to approve `tempusAMM.tempusPool` for both Yields and Principals
    ///         for `sharesAmount`
    /// @notice `msg.sender` needs to approve controller for whole balance of LP token
    /// @notice Transfers users' LP tokens to controller, then exits tempusAMM with `msg.sender` as recipient.
    ///         After exit transfers remainder of LP tokens back to user
    /// @notice Can fail if there is not enough user balance
    /// @notice Only available before maturity since exiting AMM with exact amounts is disallowed after maturity
    /// @param tempusAMM TempusAMM instance to withdraw liquidity from
    /// @param sharesAmount Amount of Principals and Yields
    /// @param toBackingToken If true redeems to backing token, otherwise redeems to yield bearing
    function exitTempusAMMAndRedeem(
        ITempusAMM tempusAMM,
        uint256 sharesAmount,
        bool toBackingToken
    ) external nonReentrant {
        _exitTempusAMMAndRedeem(tempusAMM, sharesAmount, toBackingToken);
    }

    /// @dev Withdraws ALL liquidity from TempusAMM and redeems Shares to Yield Bearing or Backing Tokens
    /// @notice `msg.sender` needs to approve controller for whole balance for both Yields and Principals
    /// @notice `msg.sender` needs to approve controller for whole balance of LP token
    /// @notice Can fail if there is not enough user balance
    /// @param tempusAMM TempusAMM instance to withdraw liquidity from
    /// @param maxLeftoverShares Maximum amount of Principals or Yields to be left in case of early exit
    /// @param toBackingToken If true redeems to backing token, otherwise redeems to yield bearing
    function completeExitAndRedeem(
        ITempusAMM tempusAMM,
        uint256 maxLeftoverShares,
        bool toBackingToken
    ) external nonReentrant {
        _completeExitAndRedeem(tempusAMM, maxLeftoverShares, toBackingToken);
    }

    /// Finalize the pool after maturity.
    function finalize(ITempusPool targetPool) external nonReentrant {
        targetPool.finalize();
    }

    /// Transfers accumulated Yield Bearing Token (YBT) fees
    /// from @param targetPool contract to `recipient`.
    /// @param targetPool The Tempus Pool from which to transfer fees
    /// @param recipient Address which will receive the specified amount of YBT
    function transferFees(ITempusPool targetPool, address recipient) external nonReentrant {
        targetPool.transferFees(msg.sender, recipient);
    }

    /// @dev Returns amount that user needs to swap to end up with almost the same amounts of Principals and Yields
    /// @param tempusAMM TempusAMM instance to be used to query swap
    /// @param principals User's Principals balance
    /// @param yields User's Yields balance
    /// @param threshold Maximum difference between final balances of Principals and Yields
    /// @return amountIn Amount of Principals or Yields that user needs to swap to end with almost equal amounts
    function getSwapAmountToEndWithEqualShares(
        ITempusAMM tempusAMM,
        uint256 principals,
        uint256 yields,
        uint256 threshold
    ) public view returns (uint256 amountIn) {
        (uint256 difference, bool yieldsIn) = (principals > yields)
            ? (principals - yields, false)
            : (yields - principals, true);
        if (difference > threshold) {
            uint256 principalsRate = tempusAMM.tempusPool().principalShare().getPricePerFullShareStored();
            uint256 yieldsRate = tempusAMM.tempusPool().yieldShare().getPricePerFullShareStored();

            uint256 rate = yieldsIn ? principalsRate.divf18(yieldsRate) : yieldsRate.divf18(principalsRate);
            for (uint8 i = 0; i < 32; i++) {
                // if we have accurate rate this should hold
                amountIn = difference.divf18(rate + Fixed256x18.ONE);
                uint256 amountOut = tempusAMM.getExpectedReturnGivenIn(amountIn, yieldsIn);
                uint256 newPrincipals = yieldsIn ? (principals + amountOut) : (principals - amountIn);
                uint256 newYields = yieldsIn ? (yields - amountIn) : (yields + amountOut);
                uint256 newDifference = (newPrincipals > newYields)
                    ? (newPrincipals - newYields)
                    : (newYields - newPrincipals);
                if (newDifference < threshold) {
                    return amountIn;
                } else {
                    rate = amountOut.divf18(amountIn);
                }
            }
            revert("getSwapAmountToEndWithEqualShares did not converge.");
        }
    }

    /// @dev Performs Swap from tokenIn to tokenOut
    /// @notice sender needs to approve tempusAMM.getVault() for swapAmount of tokenIn
    /// @param tempusAMM TempusAMM instance to be used for Swap
    /// @param sender Address of user whose tokenIn tokens will be used for swap
    /// @param recipient Address of user that will recieve tokensOut
    /// @param swapAmount Amount of tokenIn to be swapped
    /// @param tokenIn Token that will be sent from user to the tempusAMM
    /// @param tokenOut Token that will be returned from the tempusAMM to the user
    /// @param minReturn Minimum amount of tokenOut that user will recieve
    function swap(
        ITempusAMM tempusAMM,
        address sender,
        address recipient,
        uint256 swapAmount,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 minReturn
    ) public {
        require(swapAmount > 0, "Invalid swap amount.");

        (IVault vault, bytes32 poolId, , ) = _getAMMDetailsAndEnsureInitialized(tempusAMM);

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: poolId,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: tokenIn,
            assetOut: tokenOut,
            amount: swapAmount,
            userData: ""
        });

        IVault.FundManagement memory fundManagement = IVault.FundManagement({
            sender: sender,
            fromInternalBalance: false,
            recipient: payable(recipient),
            toInternalBalance: false
        });
        vault.swap(singleSwap, fundManagement, minReturn, block.timestamp);
    }

    function _depositAndProvideLiquidity(
        ITempusAMM tempusAMM,
        uint256 tokenAmount,
        bool isBackingToken
    ) private {
        (
            IVault vault,
            bytes32 poolId,
            IERC20[] memory ammTokens,
            uint256[] memory ammBalances
        ) = _getAMMDetailsAndEnsureInitialized(tempusAMM);

        ITempusPool targetPool = tempusAMM.tempusPool();
        _deposit(targetPool, tokenAmount, isBackingToken);

        uint256[2] memory ammDepositPercentages = ammBalances.getAMMBalancesRatio();
        uint256[] memory ammLiquidityProvisionAmounts = new uint256[](2);

        (ammLiquidityProvisionAmounts[0], ammLiquidityProvisionAmounts[1]) = (
            ammTokens[0].balanceOf(address(this)).mulf18(ammDepositPercentages[0]),
            ammTokens[1].balanceOf(address(this)).mulf18(ammDepositPercentages[1])
        );

        ammTokens[0].safeIncreaseAllowance(address(vault), ammLiquidityProvisionAmounts[0]);
        ammTokens[1].safeIncreaseAllowance(address(vault), ammLiquidityProvisionAmounts[1]);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: ammTokens,
            maxAmountsIn: ammLiquidityProvisionAmounts,
            userData: abi.encode(uint8(ITempusAMM.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT), ammLiquidityProvisionAmounts),
            fromInternalBalance: false
        });

        // Provide TPS/TYS liquidity to TempusAMM
        vault.joinPool(poolId, address(this), msg.sender, request);

        // Send remaining Shares to user
        if (ammDepositPercentages[0] < Fixed256x18.ONE) {
            ammTokens[0].safeTransfer(msg.sender, ammTokens[0].balanceOf(address(this)));
        }
        if (ammDepositPercentages[1] < Fixed256x18.ONE) {
            ammTokens[1].safeTransfer(msg.sender, ammTokens[1].balanceOf(address(this)));
        }
    }

    function _depositAndFix(
        ITempusAMM tempusAMM,
        uint256 tokenAmount,
        bool isBackingToken,
        uint256 minTYSRate
    ) private {
        ITempusPool targetPool = tempusAMM.tempusPool();
        IERC20 principalShares = IERC20(address(targetPool.principalShare()));
        IERC20 yieldShares = IERC20(address(targetPool.yieldShare()));

        _deposit(targetPool, tokenAmount, isBackingToken);

        uint256 swapAmount = yieldShares.balanceOf(address(this));
        yieldShares.safeIncreaseAllowance(address(tempusAMM.getVault()), swapAmount);
        uint256 minReturn = swapAmount.mulf18(minTYSRate);
        swap(tempusAMM, address(this), address(this), swapAmount, yieldShares, principalShares, minReturn);

        // At this point all TYS must be swapped for TPS
        uint256 principalsBalance = principalShares.balanceOf(address(this));
        assert(principalsBalance > 0);
        assert(yieldShares.balanceOf(address(this)) == 0);

        principalShares.safeTransfer(msg.sender, principalsBalance);
    }

    function _deposit(
        ITempusPool targetPool,
        uint256 tokenAmount,
        bool isBackingToken
    ) private {
        if (isBackingToken) {
            _depositBacking(targetPool, tokenAmount, address(this));
        } else {
            _depositYieldBearing(targetPool, tokenAmount, address(this));
        }
    }

    function _depositYieldBearing(
        ITempusPool targetPool,
        uint256 yieldTokenAmount,
        address recipient
    ) private {
        require(yieldTokenAmount > 0, "yieldTokenAmount is 0");

        IERC20 yieldBearingToken = IERC20(targetPool.yieldBearingToken());

        // Deposit to controller and approve transfer from controller to targetPool
        uint transferredYBT = yieldBearingToken.untrustedTransferFrom(msg.sender, address(this), yieldTokenAmount);
        yieldBearingToken.safeIncreaseAllowance(address(targetPool), transferredYBT);

        (uint mintedShares, uint depositedBT, uint fee, uint rate) = targetPool.deposit(transferredYBT, recipient);

        emit Deposited(
            address(targetPool),
            msg.sender,
            recipient,
            transferredYBT,
            depositedBT,
            mintedShares,
            rate,
            fee
        );
    }

    function _depositBacking(
        ITempusPool targetPool,
        uint256 backingTokenAmount,
        address recipient
    ) private {
        require(backingTokenAmount > 0, "backingTokenAmount is 0");

        IERC20 backingToken = IERC20(targetPool.backingToken());

        if (msg.value == 0) {
            backingTokenAmount = backingToken.untrustedTransferFrom(msg.sender, address(this), backingTokenAmount);
            backingToken.safeIncreaseAllowance(address(targetPool), backingTokenAmount);
        } else {
            require(address(backingToken) == address(0), "given TempusPool's Backing Token is not ETH");
        }

        (uint256 mintedShares, uint256 depositedYBT, uint256 fee, uint256 interestRate) = targetPool.depositBacking{
            value: msg.value
        }(backingTokenAmount, recipient);

        emit Deposited(
            address(targetPool),
            msg.sender,
            recipient,
            depositedYBT,
            backingTokenAmount,
            mintedShares,
            interestRate,
            fee
        );
    }

    function _redeemToYieldBearing(
        ITempusPool targetPool,
        address sender,
        uint256 principals,
        uint256 yields,
        address recipient
    ) private {
        require((principals > 0) || (yields > 0), "principalAmount and yieldAmount cannot both be 0");

        (uint redeemedYBT, uint fee, uint interestRate) = targetPool.redeem(sender, principals, yields, recipient);

        uint redeemedBT = targetPool.numAssetsPerYieldToken(redeemedYBT, targetPool.currentInterestRate());
        bool earlyRedeem = !targetPool.matured();
        emit Redeemed(
            address(targetPool),
            sender,
            recipient,
            principals,
            yields,
            redeemedYBT,
            redeemedBT,
            fee,
            interestRate,
            earlyRedeem
        );
    }

    function _redeemToBacking(
        ITempusPool targetPool,
        address sender,
        uint256 principals,
        uint256 yields,
        address recipient
    ) private {
        require((principals > 0) || (yields > 0), "principalAmount and yieldAmount cannot both be 0");

        (uint redeemedYBT, uint redeemedBT, uint fee, uint rate) = targetPool.redeemToBacking(
            sender,
            principals,
            yields,
            recipient
        );

        bool earlyRedeem = !targetPool.matured();
        emit Redeemed(
            address(targetPool),
            sender,
            recipient,
            principals,
            yields,
            redeemedYBT,
            redeemedBT,
            fee,
            rate,
            earlyRedeem
        );
    }

    function _exitTempusAMM(
        ITempusAMM tempusAMM,
        uint256 lpTokensAmount,
        uint256 principalAmountOutMin,
        uint256 yieldAmountOutMin,
        bool toInternalBalances
    ) private {
        require(tempusAMM.transferFrom(msg.sender, address(this), lpTokensAmount), "LP token transfer failed");

        ITempusPool tempusPool = tempusAMM.tempusPool();
        uint256[] memory amounts = getAMMOrderedAmounts(tempusPool, principalAmountOutMin, yieldAmountOutMin);
        _exitTempusAMMGivenLP(tempusAMM, address(this), msg.sender, lpTokensAmount, amounts, toInternalBalances);

        assert(tempusAMM.balanceOf(address(this)) == 0);
    }

    function _exitTempusAMMGivenLP(
        ITempusAMM tempusAMM,
        address sender,
        address recipient,
        uint256 lpTokensAmount,
        uint256[] memory minAmountsOut,
        bool toInternalBalances
    ) private {
        require(lpTokensAmount > 0, "LP token amount is 0");

        (IVault vault, bytes32 poolId, IERC20[] memory ammTokens, ) = _getAMMDetailsAndEnsureInitialized(tempusAMM);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: ammTokens,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(uint8(ITempusAMM.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT), lpTokensAmount),
            toInternalBalance: toInternalBalances
        });
        vault.exitPool(poolId, sender, payable(recipient), request);
    }

    function _exitTempusAMMGivenAmountsOut(
        ITempusAMM tempusAMM,
        address sender,
        address recipient,
        uint256[] memory amountsOut,
        uint256 lpTokensAmountInMax,
        bool toInternalBalances
    ) private {
        (IVault vault, bytes32 poolId, IERC20[] memory ammTokens, ) = _getAMMDetailsAndEnsureInitialized(tempusAMM);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: ammTokens,
            minAmountsOut: amountsOut,
            userData: abi.encode(
                uint8(ITempusAMM.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT),
                amountsOut,
                lpTokensAmountInMax
            ),
            toInternalBalance: toInternalBalances
        });
        vault.exitPool(poolId, sender, payable(recipient), request);
    }

    function _exitTempusAMMAndRedeem(
        ITempusAMM tempusAMM,
        uint256 sharesAmount,
        bool toBackingToken
    ) private {
        ITempusPool tempusPool = tempusAMM.tempusPool();
        require(!tempusPool.matured(), "Pool already finalized");
        uint256 userPrincipalBalance = IERC20(address(tempusPool.principalShare())).balanceOf(msg.sender);
        uint256 userYieldBalance = IERC20(address(tempusPool.yieldShare())).balanceOf(msg.sender);

        uint256 ammExitAmountPrincipal = sharesAmount - userPrincipalBalance;
        uint256 ammExitAmountYield = sharesAmount - userYieldBalance;

        // transfer LP tokens to controller
        uint256 userBalanceLP = tempusAMM.balanceOf(msg.sender);
        require(tempusAMM.transferFrom(msg.sender, address(this), userBalanceLP), "LP token transfer failed");

        uint256[] memory amounts = getAMMOrderedAmounts(tempusPool, ammExitAmountPrincipal, ammExitAmountYield);
        _exitTempusAMMGivenAmountsOut(tempusAMM, address(this), msg.sender, amounts, userBalanceLP, false);

        // transfer remainder of LP tokens back to user
        uint256 lpTokenBalance = tempusAMM.balanceOf(address(this));
        require(tempusAMM.transferFrom(address(this), msg.sender, lpTokenBalance), "LP token transfer failed");

        if (toBackingToken) {
            _redeemToBacking(tempusPool, msg.sender, sharesAmount, sharesAmount, msg.sender);
        } else {
            _redeemToYieldBearing(tempusPool, msg.sender, sharesAmount, sharesAmount, msg.sender);
        }
    }

    function _completeExitAndRedeem(
        ITempusAMM tempusAMM,
        uint256 maxLeftoverShares,
        bool toBackingToken
    ) private {
        ITempusPool tempusPool = tempusAMM.tempusPool();

        IERC20 principalShare = IERC20(address(tempusPool.principalShare()));
        IERC20 yieldShare = IERC20(address(tempusPool.yieldShare()));
        // send all shares to controller
        principalShare.safeTransferFrom(msg.sender, address(this), principalShare.balanceOf(msg.sender));
        yieldShare.safeTransferFrom(msg.sender, address(this), yieldShare.balanceOf(msg.sender));

        uint256 userBalanceLP = tempusAMM.balanceOf(msg.sender);

        if (userBalanceLP > 0) {
            // if there is LP balance, transfer to controller
            require(tempusAMM.transferFrom(msg.sender, address(this), userBalanceLP), "LP token transfer failed");

            uint256[] memory minAmountsOut = new uint256[](2);

            // exit amm and sent shares to controller
            _exitTempusAMMGivenLP(tempusAMM, address(this), address(this), userBalanceLP, minAmountsOut, false);
        }

        uint256 principals = principalShare.balanceOf(address(this));
        uint256 yields = yieldShare.balanceOf(address(this));

        if (!tempusPool.matured()) {
            bool yieldsIn = yields > principals;
            uint256 difference = yieldsIn ? (yields - principals) : (principals - yields);

            if (difference >= maxLeftoverShares) {
                uint amountIn = getSwapAmountToEndWithEqualShares(tempusAMM, principals, yields, maxLeftoverShares);
                (IERC20 tokenIn, IERC20 tokenOut) = yieldsIn
                    ? (yieldShare, principalShare)
                    : (principalShare, yieldShare);
                tokenIn.safeIncreaseAllowance(address(tempusAMM.getVault()), amountIn);

                swap(tempusAMM, address(this), address(this), amountIn, tokenIn, tokenOut, 0);

                principals = principalShare.balanceOf(address(this));
                yields = yieldShare.balanceOf(address(this));
            }
            (yields, principals) = (principals <= yields) ? (principals, principals) : (yields, yields);
        }

        if (toBackingToken) {
            _redeemToBacking(tempusPool, address(this), principals, yields, msg.sender);
        } else {
            _redeemToYieldBearing(tempusPool, address(this), principals, yields, msg.sender);
        }
    }

    function _getAMMDetailsAndEnsureInitialized(ITempusAMM tempusAMM)
        private
        view
        returns (
            IVault vault,
            bytes32 poolId,
            IERC20[] memory ammTokens,
            uint256[] memory ammBalances
        )
    {
        vault = tempusAMM.getVault();
        poolId = tempusAMM.getPoolId();
        (ammTokens, ammBalances, ) = vault.getPoolTokens(poolId);
        require(
            ammTokens.length == 2 && ammBalances.length == 2 && ammBalances[0] > 0 && ammBalances[1] > 0,
            "AMM not initialized"
        );
    }

    function getAMMOrderedAmounts(
        ITempusPool tempusPool,
        uint256 principalAmount,
        uint256 yieldAmount
    ) private view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        (amounts[0], amounts[1]) = (tempusPool.principalShare() < tempusPool.yieldShare())
            ? (principalAmount, yieldAmount)
            : (yieldAmount, principalAmount);
        return amounts;
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

    constructor() {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "./IVault.sol";
import "./../../ITempusPool.sol";

interface ITempusAMM {
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    function getVault() external view returns (IVault);

    function getPoolId() external view returns (bytes32);

    function tempusPool() external view returns (ITempusPool);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// Calculates the expected returned swap amount
    /// @param amount The given input amount of tokens
    /// @param yieldShareIn Specifies whether to calculate the swap from TYS to TPS (if true) or from TPS to TYS
    /// @return The expected returned amount of outToken
    function getExpectedReturnGivenIn(uint256 amount, bool yieldShareIn) external view returns (uint256);

    /// @dev queries exiting TempusAMM with exact BPT tokens in
    /// @param bptAmountIn amount of LP tokens in
    /// @return principals Amount of principals that user would recieve back
    /// @return yields Amount of yields that user would recieve back
    function getExpectedTokensOutGivenBPTIn(uint256 bptAmountIn)
        external
        view
        returns (uint256 principals, uint256 yields);

    /// @dev queries joining TempusAMM with exact tokens in
    /// @param amountsIn amount of tokens to be added to the pool
    /// @return amount of LP tokens that could be recieved
    function getExpectedLPTokensForTokensIn(uint256[] memory amountsIn) external view returns (uint256);

    /// @dev This function returns the appreciation of one BPT relative to the
    /// underlying tokens. This starts at 1 when the pool is created and grows over time
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IERC20 assetIn;
        IERC20 assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "./token/IPoolShare.sol";

interface ITempusFees {
    // The fees are in terms of yield bearing token (YBT).
    struct FeesConfig {
        uint256 depositPercent;
        uint256 earlyRedeemPercent;
        uint256 matureRedeemPercent;
    }

    /// Returns the current fee configuration.
    function getFeesConfig() external view returns (FeesConfig memory);

    /// Replace the current fee configuration with a new one.
    /// By default all the fees are expected to be set to zero.
    function setFeesConfig(FeesConfig calldata newFeesConfig) external;

    /// @return Maximum possible fee percentage that can be set for deposit
    function maxDepositFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for early redeem
    function maxEarlyRedeemFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for mature redeem
    function maxMatureRedeemFee() external view returns (uint256);

    /// Accumulated fees available for withdrawal.
    function totalFees() external view returns (uint256);

    /// Transfers accumulated Yield Bearing Token (YBT) fees
    /// from this pool contract to `recipient`.
    /// @param authorizer Authorizer of the transfer
    /// @param recipient Address which will receive the specified amount of YBT
    function transferFees(address authorizer, address recipient) external;
}

interface ITempusPool is ITempusFees {
    /// @return The version of the pool.
    function version() external view returns (uint);

    /// @return The name of underlying protocol, for example "Aave" for Aave protocol
    function protocolName() external view returns (bytes32);

    /// This token will be used as a token that user can deposit to mint same amounts
    /// of principal and interest shares.
    /// @return The underlying yield bearing token.
    function yieldBearingToken() external view returns (address);

    /// This is the address of the actual backing asset token
    /// in the case of ETH, this address will be 0
    /// @return Address of the Backing Token
    function backingToken() external view returns (address);

    /// @return This TempusPool's Tempus Principal Share (TPS)
    function principalShare() external view returns (IPoolShare);

    /// @return This TempusPool's Tempus Yield Share (TYS)
    function yieldShare() external view returns (IPoolShare);

    /// @return The TempusController address that is authorized to perform restricted actions
    function controller() external view returns (address);

    /// @return Start time of the pool.
    function startTime() external view returns (uint256);

    /// @return Maturity time of the pool.
    function maturityTime() external view returns (uint256);

    /// @return True if maturity has been reached and the pool was finalized.
    function matured() external view returns (bool);

    /// Finalize the pool. This can only happen on or after `maturityTime`.
    /// Once finalized depositing is not possible anymore, and the behaviour
    /// redemption will change.
    ///
    /// Can be called by anyone and can be called multiple times.
    function finalize() external;

    /// Deposits yield bearing tokens (such as cDAI) into TempusPool
    ///      msg.sender must approve @param yieldTokenAmount to this TempusPool
    ///      NOTE #1 Deposit will fail if maturity has been reached.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param yieldTokenAmount Amount of yield bearing tokens to deposit in YieldToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedBT The YBT value deposited, denominated as Backing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function deposit(uint256 yieldTokenAmount, address recipient)
        external
        returns (
            uint256 mintedShares,
            uint256 depositedBT,
            uint256 fee,
            uint256 rate
        );

    /// Deposits backing token to the underlying protocol, and then to Tempus Pool.
    ///      NOTE #1 Deposit will fail if maturity has been reached.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param backingTokenAmount amount of Backing Tokens to be deposited to underlying protocol in BackingToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedYBT The BT value deposited, denominated as Yield Bearing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function depositBacking(uint256 backingTokenAmount, address recipient)
        external
        payable
        returns (
            uint256 mintedShares,
            uint256 depositedYBT,
            uint256 fee,
            uint256 rate
        );

    /// Redeem yield bearing tokens from this TempusPool
    ///      msg.sender will receive the YBT
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem for YBT in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem for YBT in YieldShare decimal precision
    /// @param recipient Address to which redeemed YBT will be sent
    /// @return redeemableYieldTokens Amount of Yield Bearing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeem(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        returns (
            uint256 redeemableYieldTokens,
            uint256 fee,
            uint256 rate
        );

    /// Redeem TPS+TYS held by msg.sender into backing tokens
    ///      `msg.sender` must approve TPS and TYS amounts to this TempusPool.
    ///      `msg.sender` will receive the backing tokens
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem in YieldShare decimal precision
    /// @param recipient Address to which redeemed BT will be sent
    /// @return redeemableYieldTokens Amount of Backing Tokens redeemed to `recipient`, denominated in YBT
    /// @return redeemableBackingTokens Amount of Backing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeemToBacking(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        payable
        returns (
            uint256 redeemableYieldTokens,
            uint256 redeemableBackingTokens,
            uint256 fee,
            uint256 rate
        );

    /// Gets the estimated amount of Principals and Yields after a successful deposit
    /// @param amount Amount of BackingTokens or YieldBearingTokens that would be deposited
    /// @param isBackingToken If true, @param amount is in BackingTokens, otherwise YieldBearingTokens
    /// @return Amount of Principals (TPS) and Yields (TYS) in Principal/YieldShare decimal precision
    ///         TPS and TYS are minted in 1:1 ratio, hence a single return value.
    function estimatedMintedShares(uint256 amount, bool isBackingToken) external view returns (uint256);

    /// Gets the estimated amount of YieldBearingTokens or BackingTokens received when calling `redeemXXX()` functions
    /// @param principals Amount of Principals (TPS) in PrincipalShare decimal precision
    /// @param yields Amount of Yields (TYS) in YieldShare decimal precision
    /// @param toBackingToken If true, redeem amount is estimated in BackingTokens instead of YieldBearingTokens
    /// @return Amount of YieldBearingTokens or BackingTokens in YBT/BT decimal precision
    function estimatedRedeem(
        uint256 principals,
        uint256 yields,
        bool toBackingToken
    ) external view returns (uint256);

    /// @dev This returns the stored Interest Rate of the YBT (Yield Bearing Token) pool
    ///      it is safe to call this after updateInterestRate() was called
    /// @return Stored Interest Rate, decimal precision depends on specific TempusPool implementation
    function currentInterestRate() external view returns (uint256);

    /// @return Initial interest rate of the underlying pool,
    ///         decimal precision depends on specific TempusPool implementation
    function initialInterestRate() external view returns (uint256);

    /// @return Interest rate at maturity of the underlying pool (or 0 if maturity not reached yet)
    ///         decimal precision depends on specific TempusPool implementation
    function maturityInterestRate() external view returns (uint256);

    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens
    function pricePerYieldShare() external returns (uint256);

    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShare() external returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens,
    function pricePerYieldShareStored() external view returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShareStored() external view returns (uint256);

    /// @dev This returns actual Backing Token amount for amount of YBT (Yield Bearing Tokens)
    ///      For example, in case of Aave and Lido the result is 1:1,
    ///      and for compound is `yieldTokens * currentInterestRate`
    /// @param yieldTokens Amount of YBT in YBT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of Backing Tokens for specified @param yieldTokens
    function numAssetsPerYieldToken(uint yieldTokens, uint interestRate) external pure returns (uint);

    /// @dev This returns amount of YBT (Yield Bearing Tokens) that can be converted
    ///      from @param backingTokens Backing Tokens
    /// @param backingTokens Amount of Backing Tokens in BT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of YBT for specified @param backingTokens
    function numYieldTokensPerAsset(uint backingTokens, uint interestRate) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

/// @dev Fixed Point decimal math utils for 18-decimal point precision
///      on 256-bit wide numbers
library Fixed256x18 {
    /// @dev 1.0 expressed as an 1e18 decimal
    uint256 internal constant ONE = 1e18;

    /// @dev 1e18 decimal precision constant
    uint256 internal constant PRECISION = 1e18;

    /// @dev Multiplies two 1e18 fixed point decimal numbers
    /// @return result = a * b
    function mulf18(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: should we add rounding rules?
        return (a * b) / PRECISION;
    }

    /// @dev Divides two 1e18 fixed point decimal numbers
    /// @return result = a / b
    function divf18(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: should we add rounding rules?
        return (a * PRECISION) / b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// A subset of OpenZeppelin's Ownable pattern, where renouncing (transfer to zero-address) is disallowed.
/// In upstream the `transferOwnership` function disallows transfer to the zero-address too.
abstract contract PermanentlyOwnable is Ownable {
    function renounceOwnership() public override onlyOwner {
        revert("Ownable: Feature disabled");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../math/Fixed256x18.sol";

library AMMBalancesHelper {
    using Fixed256x18 for uint256;

    function getLiquidityProvisionSharesAmounts(uint256[] memory ammBalances, uint256 shares)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[2] memory ammDepositPercentages = getAMMBalancesRatio(ammBalances);
        uint256[] memory ammLiquidityProvisionAmounts = new uint256[](2);

        (ammLiquidityProvisionAmounts[0], ammLiquidityProvisionAmounts[1]) = (
            shares.mulf18(ammDepositPercentages[0]),
            shares.mulf18(ammDepositPercentages[1])
        );

        return ammLiquidityProvisionAmounts;
    }

    function getAMMBalancesRatio(uint256[] memory ammBalances) internal pure returns (uint256[2] memory balancesRatio) {
        uint256 rate = ammBalances[0].divf18(ammBalances[1]);

        (balancesRatio[0], balancesRatio[1]) = rate > Fixed256x18.ONE
            ? (Fixed256x18.ONE, Fixed256x18.ONE.divf18(rate))
            : (rate, Fixed256x18.ONE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title UntrustedERC20
/// @dev Wrappers around ERC20 transfer operators that return the actual amount
/// transferred. This means they are usable with tokens, which charge a fee or royalty on transfer.
library UntrustedERC20 {
    using SafeERC20 for IERC20;

    /// Transfer tokens to a recipient.
    /// @param token The ERC20 token.
    /// @param to The recipient.
    /// @param value The requested amount.
    /// @return The actual amount of tokens transferred.
    function untrustedTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 startBalance = token.balanceOf(to);
        token.safeTransfer(to, value);
        return token.balanceOf(to) - startBalance;
    }

    /// Transfer tokens to a recipient.
    /// @param token The ERC20 token.
    /// @param from The sender.
    /// @param to The recipient.
    /// @param value The requested amount.
    /// @return The actual amount of tokens transferred.
    function untrustedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 startBalance = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        return token.balanceOf(to) - startBalance;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6 <0.9.0;

import "../ITempusPool.sol";

/// Interface of Tokens representing the principal or yield shares of a pool.
interface IPoolShare {
    enum ShareKind {
        Principal,
        Yield
    }

    /// @return The kind of the share.
    function kind() external view returns (ShareKind);

    /// @return The pool this share is part of.
    function pool() external view returns (ITempusPool);

    /// @dev Price per single share expressed in Backing Tokens of the underlying pool.
    ///      This is for the purpose of TempusAMM api support.
    ///      Example: exchanging Tempus Yield Share to DAI
    /// @return 1e18 decimal conversion rate per share
    function getPricePerFullShare() external returns (uint256);

    /// @return 1e18 decimal stored conversion rate per share
    function getPricePerFullShareStored() external view returns (uint256);
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

