//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt ([email protected]).
*/

import "./interfaces/IUniRouter.sol";
import "./interfaces/ITipJar.sol";
import "./interfaces/IERC20Extended.sol";
import "./lib/SafeERC20.sol";

/**
 * @title ArcherSwapRouter
 * @dev Allows Uniswap V2 Router-compliant trades to be paid via % tips instead of gas
 */
contract ArcherSwapRouter {
    using SafeERC20 for IERC20Extended;

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice TipJar proxy
    ITipJar public immutable tipJar;

    /// @notice Trade details
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    /// @notice Add Liquidity details
    struct AddLiquidity {
        address tokenA;
        address tokenB;
        uint amountADesired;
        uint amountBDesired;
        uint amountAMin;
        uint amountBMin;
        address to;
        uint deadline;
    }

    /// @notice Remove Liquidity details
    struct RemoveLiquidity {
        IERC20Extended lpToken;
        address tokenA;
        address tokenB;
        uint liquidity;
        uint amountAMin;
        uint amountBMin;
        address to;
        uint deadline;
    }

    /// @notice Permit details
    struct Permit {
        IERC20Extended token;
        uint256 amount;
        uint deadline;
        uint8 v;
        bytes32 r; 
        bytes32 s;
    }

    /**
     * @notice Contructs a new ArcherSwap Router
     * @param _tipJar Address of TipJar contract
     */
    constructor(address _tipJar) {
        tipJar = ITipJar(_tipJar);
    }

    /**
     * @notice Add liquidity to token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function addLiquidityAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _addLiquidity(
            router,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to pair, using permit for approvals
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permitA Permit details for token A
     * @param permitB Permit details for token B
     */
    function addLiquidityWithPermitAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        Permit calldata permitA,
        Permit calldata permitB
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        if(permitA.amount > 0) {
            _permit(permitA.token, permitA.amount, permitA.deadline, permitA.v, permitA.r, permitA.s);
        }
        if(permitB.amount > 0) {
            _permit(permitB.token, permitB.amount, permitB.deadline, permitB.v, permitB.r, permitB.s);
        }
        _tipAmountETH(msg.value);
        _addLiquidity(
            router,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin, 
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to ETH>Token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param tipAmount tip amount
     */
    function addLiquidityETHAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= liquidity.amountBDesired + tipAmount, "must send ETH to cover tip + liquidity");
        _tipAmountETH(tipAmount);
        _addLiquidityETH(
            router,
            liquidity.tokenA,
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to ETH>Token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param tipAmount tip amount
     */
    function addLiquidityETHWithPermitAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        Permit calldata permit,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= liquidity.amountBDesired + tipAmount, "must send ETH to cover tip + liquidity");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _tipAmountETH(tipAmount);
        _addLiquidityETH(
            router,
            liquidity.tokenA,
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from token>token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function removeLiquidityAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _removeLiquidity(
            router,
            liquidity.lpToken,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.liquidity,
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from ETH>token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function removeLiquidityETHAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _removeLiquidityETH(
            router,
            liquidity.lpToken,
            liquidity.tokenA,
            liquidity.liquidity, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from token>token pair, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permit Permit details
     */
    function removeLiquidityWithPermitAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _removeLiquidity(
            router,
            liquidity.lpToken,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.liquidity,
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from ETH>token pair, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permit Permit details
     */
    function removeLiquidityETHWithPermitAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _removeLiquidityETH(
            router,
            liquidity.lpToken,
            liquidity.tokenA,
            liquidity.liquidity, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForETHAndTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapExactTokensForETHWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _tipAmountETH(msg.value);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapExactTokensForETHAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapExactTokensForETHWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapTokensForExactETHAndTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapTokensForExactETHWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapTokensForExactETHAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapTokensForExactETHWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapExactETHForTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");
        _tipAmountETH(tipAmount);
        _swapExactETHForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of ETH to pay as tip
     */
    function swapExactETHForTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        require(msg.value > 0, "must send ETH to cover tip");
        uint256 tipAmount = (msg.value * tipPct) / 1000000;
        _tipAmountETH(tipAmount);
        _swapExactETHForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapETHForExactTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");
        _tipAmountETH(tipAmount);
        _swapETHForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of ETH to pay as tip
     */
    function swapETHForExactTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        require(msg.value > 0, "must send ETH to cover tip");
        uint256 tipAmount = (msg.value * tipPct) / 1000000;
        _tipAmountETH(tipAmount);
        _swapETHForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapExactTokensForTokensWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapTokensForExactTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapTokensForExactTokensWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    function _addLiquidity(
        IUniRouter router,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(tokenA);
        IERC20Extended toToken = IERC20Extended(tokenB);
        fromToken.safeTransferFrom(msg.sender, address(this), amountADesired);
        fromToken.safeIncreaseAllowance(address(router), amountADesired);
        toToken.safeTransferFrom(msg.sender, address(this), amountBDesired);
        toToken.safeIncreaseAllowance(address(router), amountBDesired);
        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        if(amountADesired > amountA) {
            fromToken.safeTransfer(msg.sender, fromToken.balanceOf(address(this)));
        }
        if(amountBDesired > amountB) {
            toToken.safeTransfer(msg.sender, toToken.balanceOf(address(this)));
        }
    }

    function _addLiquidityETH(
        IUniRouter router,
        address token,
        uint amountTokenDesired,
        uint amountETHDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(token);
        fromToken.safeTransferFrom(msg.sender, address(this), amountTokenDesired);
        fromToken.safeIncreaseAllowance(address(router), amountTokenDesired);
        (uint256 amountToken, uint256 amountETH, ) = router.addLiquidityETH{value: amountETHDesired}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        if(amountTokenDesired > amountToken) {
            fromToken.safeTransfer(msg.sender, amountTokenDesired - amountToken);
        }
        if(amountETHDesired > amountETH) {
            (bool success, ) = msg.sender.call{value: amountETHDesired - amountETH}("");
            require(success);
        }
    }

    function _removeLiquidity(
        IUniRouter router,
        IERC20Extended lpToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal {
        lpToken.safeTransferFrom(msg.sender, address(this), liquidity);
        lpToken.safeIncreaseAllowance(address(router), liquidity);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        IERC20Extended fromToken = IERC20Extended(tokenA);
        IERC20Extended toToken = IERC20Extended(tokenB);
        fromToken.safeTransfer(msg.sender, amountA);
        toToken.safeTransfer(msg.sender, amountB);
    }

    function _removeLiquidityETH(
        IUniRouter router,
        IERC20Extended lpToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal {
        lpToken.safeTransferFrom(msg.sender, address(this), liquidity);
        lpToken.safeIncreaseAllowance(address(router), liquidity);
        (uint256 amountToken, uint256 amountETH) = router.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        IERC20Extended fromToken = IERC20Extended(token);
        fromToken.safeTransfer(msg.sender, amountToken);
        (bool success, ) = msg.sender.call{value: amountETH}("");
        require(success);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactETHForTokens(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapETHForExactTokens(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        router.swapETHForExactTokens{value: amountInMax}(amountOut, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactETH(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForETH(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForTokens(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountOut Amount of tokens out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive tokens
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactTokens(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    /**
     * @notice Tip % of ETH contract balance
     * @param tipPct % to tip
     */
    function _tipPctETH(uint32 tipPct) internal {
        uint256 contractBalance = address(this).balance;
        uint256 tipAmount = (contractBalance * tipPct) / 1000000;
        tipJar.tip{value: tipAmount}();
    }

    /**
     * @notice Tip specific amount of ETH
     * @param tipAmount Amount to tip
     */
    function _tipAmountETH(uint256 tipAmount) internal {
        tipJar.tip{value: tipAmount}();
    }

    /**
     * @notice Transfer contract ETH balance to specified user
     * @param to User to receive transfer
     */
    function _transferContractETHBalance(address payable to) internal {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice Transfer contract token balance to specified user
     * @param token Token to transfer
     * @param to User to receive transfer
     */
    function _transferContractTokenBalance(IERC20Extended token, address payable to) internal {
        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    /**
     * @notice Convert a token balance into ETH and then tip
     * @param amountIn Amount to swap
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _tipWithTokens(
        IUniRouter router,
        uint amountIn,
        address[] memory path,
        uint256 deadline,
        uint256 minEth
    ) internal {
        IERC20Extended(path[0]).safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, minEth, path, address(this), deadline);
        tipJar.tip{value: address(this).balance}();
    }

    /**
     * @notice Permit contract to spend user's balance
     * @param token Token to permit
     * @param amount Amount to permit
     * @param deadline Block timestamp deadline for permit
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _permit(
        IERC20Extended token, 
        uint amount,
        uint deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) internal {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20Extended {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function version() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function receiveWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address) external view returns (uint);
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITipJar {
    function tip() external payable;
    function updateMinerSplit(address minerAddress, address splitTo, uint32 splitPct) external;
    function setFeeCollector(address newCollector) external;
    function setFee(uint32 newFee) external;
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable; 
}

//SPDX-License-Identifier: MIT
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

interface IUniRouter is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20Extended.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20Extended;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20Extended token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Extended token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20Extended-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Extended token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Extended token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Extended token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Extended token, bytes memory data) private {
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

