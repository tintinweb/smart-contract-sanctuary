pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './libraries/SchnitzelSwapV1Library.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IWrappedNative.sol'; // former IWETH.sol
import './interfaces/ISchnitzelSwapV1Referral.sol';
import './interfaces/ISchnitzelSwapV1Router.sol';
import './interfaces/staking/ISchnitzelStakingPool.sol';
import './SchnitzelSwapV1Router.sol';
import './SchnitzelSwapV1Pair.sol';

interface IBurnable {
    function burn(uint256 amount) external virtual;
}

contract SchnitzelSwapV1Router is Ownable {
    struct FeeConfig {
        uint256 percentStaking;
        uint256 percentBurns;
    }

    FeeConfig public feeConfig;

    IERC20 private STZL;
    ISchnitzelSwapV1Referral private referralContract;
    ISchnitzelStakingPool private stakingPool;
    address private factory;
    address private WrappedNative; // WETH, WBNB, ...

    event ReduceFee(address token, string referralCode, uint256 amount);

    uint256 private constant ZERO = uint256(0);

    // Logic unchanged
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'SchnitzelV1Router: EXPIRED');
        _;
    }

    //Logic Changes:
    // - added addresses for referral, stake, STZL-token,
    // - added shares for referral, stake
    constructor(
        address _factory,
        address _WrappedNative,
        ISchnitzelSwapV1Referral _referralContract,
        ISchnitzelStakingPool _stakingPool,
        IERC20 _STZL
    ) public {
        factory = _factory;
        WrappedNative = _WrappedNative;
        referralContract = _referralContract;
        stakingPool = _stakingPool;
        STZL = _STZL;
    }

    // Audit: default
    // Logic Unchanged
    receive() external payable {
        assert(msg.sender == WrappedNative);
        // only accept ETH via fallback from the WETH contract
    }

    // Additional Logic: Setter for added variable
    function setFeeConfig(uint256 percentStaking, uint256 percentBurns) external onlyOwner {
        require(percentStaking + percentBurns <= 100, 'Sum of Stake and burns percent fee must be 0 - 100');
        feeConfig.percentStaking = percentStaking;
        feeConfig.percentBurns = percentBurns;
    }

    // **** ADD LIQUIDITY **** (identical to Uniswap)
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = SchnitzelSwapV1Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SchnitzelSwapV1Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SchnitzelV1Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = SchnitzelSwapV1Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SchnitzelV1Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // Identical to Uniswap
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    ) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = address(SchnitzelSwapV1Library.pairFor(factory, tokenA, tokenB));
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISchnitzelSwapV1Pair(pair).mint(to);
    }

    // Identical to Uniswap except the new LiquidityAdded event
    function addLiquidityNative(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    ) external payable virtual ensure(deadline) returns (
        uint256 amountToken,
        uint256 amountNative,
        uint256 liquidity
    ) {
        (amountToken, amountNative) = _addLiquidity(
            token,
            WrappedNative,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountNativeMin
        );
        address pair = address(SchnitzelSwapV1Library.pairFor(factory, token, WrappedNative));
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWrappedNative(WrappedNative).deposit{value : amountNative}();
        assert(IWrappedNative(WrappedNative).transfer(pair, amountNative));
        liquidity = ISchnitzelSwapV1Pair(pair).mint(to);
        // refund dust eth, if any
        // if (msg.value > amountNative) TransferHelper.safeTransferNative(msg.sender, msg.value - amountNative);
    }

    // Identical to Uniswap except that STZL rewards are withdrawn
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (
        uint256 amountA,
        uint256 amountB,
        uint256 rewardSTZL
    ) {
        ISchnitzelSwapV1Pair pair = SchnitzelSwapV1Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2ERC20(address(pair)).transferFrom(msg.sender, address(pair), liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1, uint256 x) = pair.burn(to);
        rewardSTZL = x;
        (amountA, amountB) = tokenA == getToken0(tokenA, tokenB) ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SchnitzelSwapV1Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SchnitzelSwapV1Router: INSUFFICIENT_B_AMOUNT');
    }

    // helper function to avoid stack to deep errors (lol)
    function getToken0(address tokenA, address tokenB) internal returns (address) {
        (address token0,) = SchnitzelSwapV1Library.sortTokens(tokenA, tokenB);
        return token0;
    }

    // logic changes:
    // - added safeTransfer of STZL
    // - withdrawAndTransfer of wrapped
    function removeLiquidityNative(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountWrappedMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (
        uint256 amountToken,
        uint256 amountWrapped,
        uint256 rewardSTZL
    ) {
        (amountToken, amountWrapped, rewardSTZL) = removeLiquidity(
            token,
            WrappedNative,
            liquidity,
            amountTokenMin,
            amountWrappedMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        // added the STZL transfer
        TransferHelper.safeTransfer(address(STZL), to, rewardSTZL);
        IWrappedNative(WrappedNative).withdraw(amountWrapped);
        TransferHelper.safeTransferNative(to, amountWrapped);
    }

    // Logic unchanged
    // Audit: default, changed uint types
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
    ) external virtual returns (uint256 amountA, uint256 amountB, uint256 rewardSTZL) {
        IUniswapV2ERC20(address(SchnitzelSwapV1Library.pairFor(factory, tokenA, tokenB))).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB, rewardSTZL) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    // Logic mainly unchanged, besided the STZL part
    // Audit: default, changed uint types
    function removeLiquidityNativeWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (
        uint256 amountToken,
        uint256 amountNative,
        uint256 amountSTZL
    ) {
        address pair = address(SchnitzelSwapV1Library.pairFor(factory, token, WrappedNative));
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IUniswapV2ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountNative, amountSTZL) = removeLiquidityNative(
            token,
            liquidity,
            amountTokenMin,
            amountNativeMin,
            to,
            deadline
        );
    }

    // Logic mainly unchanged, besided the STZL part
    // Audit: default, changed uint types
    function removeLiquidityNativeSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint256 amountNative, uint256 rewardSTZL) {
        (, amountNative, rewardSTZL) = removeLiquidity(
            token,
            WrappedNative,
            liquidity,
            amountTokenMin,
            amountNativeMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWrappedNative(WrappedNative).withdraw(amountNative);
        TransferHelper.safeTransferNative(to, amountNative);
    }

    // Logic mainly unchanged, besided the STZL part
    // Audit: default, changed uint types
    function removeLiquidityNativeWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountNative, uint256 rewardSTZL) {
        address pair = address(SchnitzelSwapV1Library.pairFor(factory, token, WrappedNative));
        uint256 value = approveMax ? type(uint256).max : liquidity;
        SchnitzelSwapV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountNative, rewardSTZL) = removeLiquidityNativeSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountNativeMin,
            to,
            deadline
        );
    }

    // just to avoid stack too deep errors (rofl)
    struct STZLAmounts {
        uint256 forBurns;
        uint256 forStaking;
        uint256 forReferral;
    }

    //minor changes:
    // - referralCode as argument
    // @todo - ReduceFee Event
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to,
        string memory referralCode
    ) internal virtual {
        STZLAmounts memory schnitzelTokenAmounts;

        for (uint256 i; i < path.length - 1; i++) {
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = path[i] == getToken0(path[i], path[i + 1]) ? (ZERO, amountOut) : (amountOut, ZERO);
            address to = i < path.length - 2 ? address(SchnitzelSwapV1Library.pairFor(factory, path[i + 1], path[i + 2])) : _to;

            {
                (uint256 amount0Out, uint256 amount1Out) = path[i] == getToken0(path[i + 1], address(STZL)) ? (ZERO, amountOut) : (amountOut, ZERO);
                ISchnitzelSwapV1Pair pair = SchnitzelSwapV1Library.pairFor(factory, path[i + 1], address(STZL));
                try pair.swap(amount0Out, amount1Out, address(this), '', new bytes(0)) {
                    // if all percentage shares together are higher than 90% we assume a bug and don't do anything
                    // we also don't want to `require` here because that would fully break swaps
                    if (feeConfig.percentStaking + feeConfig.percentBurns + referralContract.getReferrerPercentage(referralCode) <= 90) {
                        STZLAmounts memory schnitzelTokenAddAmounts = STZLAmounts({
                            forBurns: STZL.balanceOf(address(this)) * feeConfig.percentBurns / 100,
                            forStaking: STZL.balanceOf(address(this)) * feeConfig.percentStaking / 100,
                            forReferral: STZL.balanceOf(address(this)) * referralContract.getReferrerPercentage(referralCode) / 100
                        });

                        schnitzelTokenAmounts.forStaking = schnitzelTokenAmounts.forStaking + schnitzelTokenAddAmounts.forStaking;
                        schnitzelTokenAmounts.forBurns = schnitzelTokenAmounts.forBurns + schnitzelTokenAddAmounts.forBurns;
                        schnitzelTokenAmounts.forReferral = schnitzelTokenAmounts.forReferral + schnitzelTokenAddAmounts.forReferral;

                        pair.addSTZLRewards(STZL.balanceOf(address(this)) - schnitzelTokenAddAmounts.forStaking - schnitzelTokenAddAmounts.forBurns - schnitzelTokenAddAmounts.forReferral);
                    }
                } catch Error(string memory reason) {
                    // if there is not enough liquidity for STZL we charge fees the old school way
                    // all other errors should still be thrown

                    require(keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked('SchnitzelSwapV1: INSUFFICIENT_LIQUIDITY')), reason);
                }
            }

            (uint256 amount0OutAfterFees, uint256 amount1OutAfterFees) = amount0Out > ZERO ? (amount0Out - amount0Out * 997 / 1000, ZERO) : (ZERO, amount1Out - amount1Out * 997 / 1000);

            ISchnitzelSwapV1Pair(SchnitzelSwapV1Library.pairFor(factory, path[i], path[i + 1])).swap(
                amount0OutAfterFees,
                amount1OutAfterFees,
                to,
                referralCode,
                new bytes(0)
            );
        }

        if (schnitzelTokenAmounts.forBurns > 0) {
            IBurnable(address(STZL)).burn(schnitzelTokenAmounts.forBurns);
        }

        if (schnitzelTokenAmounts.forStaking > 0) {
            stakingPool.addRewards(schnitzelTokenAmounts.forStaking);
        }

        if (schnitzelTokenAmounts.forReferral > 0) {
            // @todo - we might want a safe transfer here
            STZL.transfer(referralContract.getReferrerAddress(referralCode), schnitzelTokenAmounts.forReferral);
        }
    }

    // Identical except referralCode
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SchnitzelSwapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SchnitzelV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]
        );
        _swap(amounts, path, to, referralCode);
    }

    // Identical except referralCode
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = SchnitzelSwapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SchnitzelV1Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]
        );
        _swap(amounts, path, to, referralCode);
    }

    // Identical except referralCode
    function swapExactNativeForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WrappedNative, 'SchnitzelV1Router: INVALID_PATH');
        amounts = SchnitzelSwapV1Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SchnitzelV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWrappedNative(WrappedNative).deposit{value : amounts[0]}();
        assert(IWrappedNative(WrappedNative).transfer(address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]));
        _swap(amounts, path, to, referralCode);
    }

    // Identical except referralCode
    function swapTokensForExactNative(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WrappedNative, 'SchnitzelSwapV1Router: INVALID_PATH');
        amounts = SchnitzelSwapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SchnitzelSwapV1Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]
        );
        _swap(amounts, path, address(this), referralCode);
        IWrappedNative(WrappedNative).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferNative(to, amounts[amounts.length - 1]);
    }

    // Identical except referralCode
    function swapExactTokensForNative(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WrappedNative, 'SchnitzelSwapV1Router: INVALID_PATH');
        amounts = SchnitzelSwapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SchnitzelSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]
        );
        _swap(amounts, path, address(this), referralCode);
        IWrappedNative(WrappedNative).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferNative(to, amounts[amounts.length - 1]);
    }

    // Identical except referralCode
    function swapNativeForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external payable virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WrappedNative, 'SchnitzelSwapV1Router: INVALID_PATH');
        amounts = SchnitzelSwapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'SchnitzelSwapV1Router: EXCESSIVE_INPUT_AMOUNT');
        IWrappedNative(WrappedNative).deposit{value: amounts[0]}();
        assert(IWrappedNative(WrappedNative).transfer(address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amounts[0]));
        _swap(amounts, path, to, referralCode);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferNative(msg.sender, msg.value - amounts[0]);
    }

    // Audit: added referralCode
    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, string calldata referralCode) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            ISchnitzelSwapV1Pair pair = ISchnitzelSwapV1Pair(SchnitzelSwapV1Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == getToken0(input, output) ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = SchnitzelSwapV1Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == getToken0(input, output) ? (ZERO, amountOutput) : (amountOutput, ZERO);
            address to = i < path.length - 2 ? address(SchnitzelSwapV1Library.pairFor(factory, output, path[i + 2])) : _to;
            pair.swap(amount0Out, amount1Out, to, referralCode, new bytes(0));
        }
    }

    // Audit: added referralCode
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, referralCode);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'SchnitzelSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // Audit: added referralCode
    function swapExactNativeForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual payable ensure(deadline) {
        require(path[0] == WrappedNative, 'SchnitzelSwapV1Router: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWrappedNative(WrappedNative).deposit{value: amountIn}();
        assert(IWrappedNative(WrappedNative).transfer(address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, referralCode);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'SchnitzelSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // Audit: added referralCode
    function swapExactTokensForNativeSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        string calldata referralCode
    ) external virtual ensure(deadline) {
        require(path[path.length - 1] == WrappedNative, 'SchnitzelSwapV1Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(SchnitzelSwapV1Library.pairFor(factory, path[0], path[1])), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), referralCode);
        uint256 amountOut = IERC20(WrappedNative).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SchnitzelSwapV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWrappedNative(WrappedNative).withdraw(amountOut);
        TransferHelper.safeTransferNative(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual returns (uint amountB) {
        return SchnitzelSwapV1Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure virtual returns (uint amountOut)
    {
        return SchnitzelSwapV1Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure virtual returns (uint amountIn)
    {
        return SchnitzelSwapV1Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view virtual returns (uint[] memory amounts)
    {
        return SchnitzelSwapV1Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view virtual returns (uint[] memory amounts)
    {
        return SchnitzelSwapV1Library.getAmountsIn(factory, amountOut, path);
    }

    function _getReferralShare(string memory referralCode) internal view returns (uint256 percentage) {
        (address referrer,) = ISchnitzelSwapV1Referral(referralContract).getReferrer(referralCode);
        if (referrer == address(0)) {
            return 0;
        }
        // @todo - fetch amount from staking contract and determine share
        return 1;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

import "../interfaces/ISchnitzelSwapV1Pair.sol";

// Audit: based on UniswapV2Library
library SchnitzelSwapV1Library {
    // Audit: default
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // Audit: default
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (ISchnitzelSwapV1Pair pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = ISchnitzelSwapV1Pair(bytesToAddress(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'2155b031853017166122e55d5972d0c9408d679a9cf64e63e32d3744a18dfa93' // get init code hash from 'scripts/getByteCodeHash'
            ))));
    }

    // Audit: default
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISchnitzelSwapV1Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // Audit: default
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // Audit: Removed fee calculation
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    // Audit: Removed fee calculation
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut;
        uint denominator = reserveOut - amountOut;
        amountIn = numerator / denominator + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // addded due to solidity upgrade
    function bytesToAddress(bytes32 bys) private pure returns (address addr) {
        assembly {
            mstore(0, bys)
            addr := mload(0)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
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

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferNative: Native transfer failed');
    }
}

pragma solidity ^0.8.0;

// former IWETH (and IWETH.sol)
interface IWrappedNative {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;

interface ISchnitzelSwapV1Referral {
    event RegistrationReferral(address indexed from, string referralCode, string displayName, string url);

    function registerReferralCode(
        string calldata referralCode,
        string calldata displayName,
        string calldata url
    ) external returns (bool);

    function registerReferralCode(string calldata referralCode, string calldata displayName) external returns (bool);

    // returns the address of the referrer and the share in percent
    function getReferrer(string calldata referralCode) external view returns (address, uint256);
    function getReferrerPercentage(string calldata referralCode) external view returns (uint256);
    function getReferrerAddress(string calldata referralCode) external view returns (address);

    function getCodeSize() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface ISchnitzelSwapV1Router {

    function factory() external view returns (address);
    function WrappedNative() external view returns (address); // renamed from WETH()
    function referral() external view returns (address);
    function stake() external view returns (address);
    function STZL() external view returns (address);

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

    // former addLiquidityETH
    function addLiquidityWrapped(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountWrappedMin, // former amountETHMin
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountWrapped, uint liquidity); // former amountETH

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint amountSTZL);

    // former removeLiquidityETH
    function removeLiquidityWrapped(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountWrappedMin, // former amountETHMin
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountWrapped, uint amountSTZL); // former amountETH

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

    // former removeLiquidityETHWithPermit
    function removeLiquidityWrappedWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountWrappedMin, // former amountETHMin
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountWrapped, uint amountSTZL); // former amountETH

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external returns (uint[] memory amounts);

    // former swapExactETHForTokens
    function swapExactWrappedForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline,
        string calldata referralCode
    ) external payable returns (uint[] memory amounts);

    // former swapTokensForExactETH
    function swapTokensForExactWrapped(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external returns (uint[] memory amounts);

    // former swapExactTokensForETH
    function swapExactTokensForWrapped(uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external returns (uint[] memory amounts);

    // former swapETHForExactTokens
    function swapWrappedForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external payable returns (uint[] memory amounts);

    // former removeLiquidityETHSupportingFeeOnTransferTokens
    function removeLiquidityWrappedSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountWrappedMin, // former amountETHMin
        address to,
        uint deadline
    ) external returns (uint amountWrapped, uint amountSTZL); // former amountETH

    // former removeLiquidityETHWithPermitSupportingFeeOnTransferTokens
    function removeLiquidityWrappedWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountWrappedMin, // former amountETHMin
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountWrapped, uint amountSTZL); // former amountETH

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external;

    // former swapExactETHForTokensSupportingFeeOnTransferTokens
    function swapExactWrappedForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external payable;

    // former swapExactTokensForETHSupportingFeeOnTransferTokens
    function swapExactTokensForWrappedSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        string calldata referralCode
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISchnitzelStakingPool {
    function addRewards(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISchnitzelSwapV1Callee.sol";
import "./interfaces/ISchnitzelSwapV1Factory.sol";
import "./interfaces/ISchnitzelSwapV1Pair.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";
import "./SchnitzelSwapV1ERC20.sol";

contract SchnitzelSwapV1Pair is ISchnitzelSwapV1Pair, SchnitzelSwapV1ERC20 {
    using UQ112x112 for uint224;

    uint256 public constant override MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override STZL;
    address public override factory;
    address public override token0;
    address public override token1;

    struct LiquidityProviderInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping (address => LiquidityProviderInfo) public liquidityProviderInfo;

    uint256 public totalSTZLRewards;
    uint256 public lastSTZLRewardsAmount;
    uint256 public accRewardPerShare;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private constant DIV_PRECISION = 1e18;

    // No logic changed from UniswapV2
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'SchnitzelSwapV1: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // No logic changed from UniswapV2
    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // No logic changed from UniswapV2
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SchnitzelSwapV1: TRANSFER_FAILED');
    }

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    // No logic changed from UniswapV2
    function initialize(address _token0, address _token1, address _STZL) override external {
        require(msg.sender == factory, 'SchnitzelSwapV1: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        STZL = _STZL;
    }

    function addSTZLRewards(uint256 amount) override external {
        require(amount > 0, 'SchnitzelSwapV1: Amount must be greater than zero');

        _safeTransfer(address(STZL), address(this), amount);
        totalSTZLRewards = totalSTZLRewards + amount;
        emit LogAddRewards(amount);
    }

    function updateRewards() private {
        if (totalSTZLRewards > lastSTZLRewardsAmount) {
            if (totalSupply > 0) {
                uint256 reward = totalSTZLRewards - lastSTZLRewardsAmount;
                accRewardPerShare = accRewardPerShare + (reward * DIV_PRECISION) / totalSupply;
            }
            lastSTZLRewardsAmount = totalSTZLRewards;
            emit LogUpdateRewards(lastSTZLRewardsAmount, accRewardPerShare);
        }
    }

    // No logic changed from UniswapV2
    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'SchnitzelSwapV1: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // No logic changed from UniswapV2 except SafeMath removal
    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = ISchnitzelSwapV1Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast;
        // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * 5 + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // Added STZL reward calculation
    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock override returns (uint liquidity) {
        // updateRewards();

        // (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // // gas savings
        // uint balance0 = IERC20(token0).balanceOf(address(this));
        // uint balance1 = IERC20(token1).balanceOf(address(this));
        // uint amount0 = balance0 - _reserve0;
        // uint amount1 = balance1 - _reserve1;

        // bool feeOn = _mintFee(_reserve0, _reserve1);
        // uint _totalSupply = totalSupply;
        // // gas savings, must be defined here since totalSupply can update in _mintFee
        // if (_totalSupply == 0) {
        //     liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        //     _mint(address(0), MINIMUM_LIQUIDITY);
        //     // permanently lock the first MINIMUM_LIQUIDITY tokens
        // } else {
        //     liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        // }
        // require(liquidity > 0, 'SchnitzelSwapV1: INSUFFICIENT_LIQUIDITY_MINTED');
        // _mint(to, liquidity);

        // _update(balance0, balance1, _reserve0, _reserve1);
        // if (feeOn) kLast = reserve0 * reserve1;
        // // reserve0 and reserve1 are up-to-date

        // LiquidityProviderInfo storage lp = liquidityProviderInfo[msg.sender];
        // lp.amount = lp.amount + liquidity;
        // lp.rewardDebt = lp.rewardDebt + liquidity * accRewardPerShare / DIV_PRECISION;

        // emit Mint(msg.sender, amount0, amount1);
    }

    // Added STZL reward calculation
    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock override returns (uint256 amount0, uint256 amount1, uint256 rewardSTZL) {
        updateRewards();

        LiquidityProviderInfo storage lp = liquidityProviderInfo[msg.sender];

        uint256 accumulated = lp.amount * accRewardPerShare / DIV_PRECISION;
        rewardSTZL = accumulated - lp.rewardDebt;

        lp.amount = 0;
        lp.rewardDebt = 0;

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'SchnitzelSwapV1: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _safeTransfer(STZL, to, rewardSTZL);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1;
        // reserve0 and reserve1 are up-to-date

        totalSTZLRewards = totalSTZLRewards - rewardSTZL;

        emit Burn(msg.sender, amount0, amount1, to, rewardSTZL);
    }

    // Added referralCode argument plus removed SafeMath
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, string memory referralCode, bytes calldata data) override external lock {
        require(amount0Out > 0 || amount1Out > 0, 'SchnitzelSwapV1: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'SchnitzelSwapV1: INSUFFICIENT_LIQUIDITY');



        
            uint balance0;
            uint balance1;
            {// scope for _token{0,1}, avoids stack too deep errors
                address _token0 = token0;
                address _token1 = token1;
                require(to != _token0 && to != _token1, 'SchnitzelSwapV1: INVALID_TO');
                if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
                if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
                if (data.length > 0) ISchnitzelSwapV1Callee(to).schnitzelSwapV1Call(msg.sender, amount0Out, amount1Out, referralCode, data);
                balance0 = IERC20(_token0).balanceOf(address(this));
                balance1 = IERC20(_token1).balanceOf(address(this));
            }
            uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
            uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
            require(amount0In > 0 || amount1In > 0, 'SchnitzelSwapV1: INSUFFICIENT_INPUT_AMOUNT');

            {
                // @todo - fix this extra check
                uint balance0Adjusted = balance0 * 1000;
                uint balance1Adjusted = balance1 * 1000;
                require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * 1000 ** 2, 'SchnitzelSwapV1: K');
            }

            _update(balance0, balance1, _reserve0, _reserve1);
        

        // we are using amount1Out instead amount0Out for the if condition to avoid stack to deep errors (don't as why)
        _emitSwap(amount0In, amount1In, amount0Out, amount1Out, to, referralCode);
  }

    function _emitSwap(uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address to, string memory referralCode) internal {
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to, referralCode);
    }

    // Audit: default
    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // Audit: default
    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        LiquidityProviderInfo storage senderLp = liquidityProviderInfo[from];
        LiquidityProviderInfo storage receiverLp = liquidityProviderInfo[to];

        uint256 additionalReceiverRewardDebt = amount / senderLp.amount * senderLp.rewardDebt;
        receiverLp.rewardDebt = receiverLp.rewardDebt + additionalReceiverRewardDebt;
        senderLp.rewardDebt = senderLp.rewardDebt - additionalReceiverRewardDebt;
        senderLp.amount = senderLp.amount - amount;
        receiverLp.amount = receiverLp.amount + amount;
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
pragma solidity >= 0.8.0;

interface ISchnitzelSwapV1Pair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to, uint256 rewardSTZL);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to,
        string referralCode
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event LogAddRewards(uint256 amount);
    event LogUpdateRewards(uint256 totalSTZLRewards, uint256 accRewardPerShare);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function STZL() external view returns (address);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1, uint256 rewardSTZL);
    function swap(uint amount0Out, uint amount1Out, address to, string memory referralCode, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address) external;
    function addSTZLRewards(uint256 amount) external;
}

pragma solidity ^0.8.0;

interface ISchnitzelSwapV1Callee {
    function schnitzelSwapV1Call(address sender, uint amount0, uint amount1, string memory referralCode, bytes calldata data) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISchnitzelSwapV1Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    // only this has been added
    function STZL() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >= 0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// Nothing changed from UniswapV2

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity ^0.8.0;
// a library for performing various math operations, nothing changed from UniswapV2

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// @todo - Call beforeTokenTransfer (also check mint and burn)
// Audit: based on UniswapV1ERC20
abstract contract SchnitzelSwapV1ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant override name = 'SchnitzelSwap V1';
    string public constant override symbol = 'STZL-V1';
    uint8 public constant  override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    // Audit: default
    constructor() {
        uint chainId;
        assembly {
            chainId := chainid() // Audit: changed
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    // Audit: default
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    // Audit: default
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    // Audit: default
    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // Audit: default
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    // Audit: default
    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // Audit: default
    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // Changed uint(-1) -> type(uint256).max
    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    // Audit: changed require messages
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'SchnitzelSwapV1: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SchnitzelSwapV1: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
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