// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import './libraries/TransferHelper.sol';
import './libraries/ReentrancyGuard.sol';
import './libraries/ImpossibleLibrary.sol';
import './libraries/SafeMath.sol';

import './interfaces/IImpossibleSwapFactory.sol';
import './interfaces/IImpossibleRouterExtension.sol';
import './interfaces/IImpossibleRouter.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IImpossibleWrappedToken.sol';
import './interfaces/IImpossibleWrapperFactory.sol';

/**
    @title  Router for Impossible Swap V3
    @author Impossible Finance
    @notice This router builds upon basic Uni V2 Router02 by allowing custom
            calculations based on settings in pairs (uni/xybk/custom fees)
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
    @dev    Very little logical changes made in Router02. Most changes to accomodate xybk are in Library
*/

contract ImpossibleRouter is IImpossibleRouter, ReentrancyGuard {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override wrapFactory;

    address private utilitySettingAdmin;

    address public override routerExtension; // Can be set by utility setting admin once only
    address public override WETH; // Can be set by utility setting admin once only

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'ImpossibleRouter: EXPIRED');
        _;
    }

    /**
     @notice Constructor for IF Router
     @param _pairFactory Address of IF Pair Factory
     @param _wrapFactory Address of IF
     @param _utilitySettingAdmin Admin address allowed to set addresses of utility contracts (once)
    */
    constructor(
        address _pairFactory,
        address _wrapFactory,
        address _utilitySettingAdmin
    ) {
        factory = _pairFactory;
        wrapFactory = _wrapFactory;
        utilitySettingAdmin = _utilitySettingAdmin;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     @notice Used to set addresses of utility contracts
     @dev Only allows setter to set these addresses once for trustlessness
     @dev Must set both WETH and routerExtension at the same time, else swap will be bricked
     @param _WETH address of WETH contract
     @param _routerExtension address of router interface contract
     */
    function setUtilities(address _WETH, address _routerExtension) public {
        require(WETH == address(0x0) && routerExtension == address(0x0));
        require(msg.sender == utilitySettingAdmin, 'IF: ?');
        WETH = _WETH;
        routerExtension = _routerExtension;
    }

    /**
     @notice Helper function for sending tokens that might need to be wrapped
     @param token The address of the token that might have a wrapper
     @param src The source to take underlying tokens from
     @param dst The destination to send wrapped tokens to
     @param amt The amount of tokens to send (wrapped tokens, not underlying)
    */
    function wrapSafeTransfer(
        address token,
        address src,
        address dst,
        uint256 amt
    ) internal {
        address underlying = IImpossibleWrapperFactory(wrapFactory).wrappedTokensToTokens(token);
        if (underlying == address(0x0)) {
            TransferHelper.safeTransferFrom(token, src, dst, amt);
        } else {
            uint256 underlyingAmt = IImpossibleWrappedToken(token).amtToUnderlyingAmt(amt);
            TransferHelper.safeTransferFrom(underlying, src, address(this), underlyingAmt);
            TransferHelper.safeApprove(underlying, token, underlyingAmt);
            IImpossibleWrappedToken(token).deposit(dst, underlyingAmt);
        }
    }

    /**
     @notice Helper function for sending tokens that might need to be unwrapped
     @param token The address of the token that might be wrapped
     @param dst The destination to send underlying tokens to
     @param amt The amount of wrapped tokens to send (wrapped tokens, not underlying)
    */
    function unwrapSafeTransfer(
        address token,
        address dst,
        uint256 amt
    ) internal {
        address underlying = IImpossibleWrapperFactory(wrapFactory).wrappedTokensToTokens(token);
        if (underlying == address(0x0)) {
            TransferHelper.safeTransfer(token, dst, amt);
        } else {
            IImpossibleWrappedToken(token).withdraw(dst, amt);
        }
    }

    /**
     @notice Swap function - receive maximum output given fixed input
     @dev Openzeppelin reentrancy guards
     @param amountIn The exact input amount`
     @param amountOutMin The minimum output amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive desired output amount given a maximum input amount
     @dev Openzeppelin reentrancy guards
     @param amountOut The exact output amount desired
     @param amountInMax The maximum input amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amountOut);
    }

    /**
     @notice Swap function - receive maximum output given fixed input of ETH
     @dev Openzeppelin reentrancy guards
     @param amountOutMin The minimum output amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amounts[amounts.length - 1]);
    }

    /**
    @notice Swap function - receive desired ETH output amount given a maximum input amount
     @dev Openzeppelin reentrancy guards
     @param amountOut The exact output amount desired
     @param amountInMax The maximum input amount allowed for a successful swap
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive maximum ETH output given fixed input of tokens
     @dev Openzeppelin reentrancy guards
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum ETH output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     @notice Swap function - receive maximum tokens output given fixed ETH input
     @dev Openzeppelin reentrancy guards
     @param amountOut The minimum output amount in tokens required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
     @return amounts Array of actual output token amounts received per swap, sequentially.
    */
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        amounts = ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ImpossibleRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        IImpossibleRouterExtension(routerExtension).swap(amounts, path);
        unwrapSafeTransfer(path[path.length - 1], to, amountOut);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /**
     @notice Swap function for fee on transfer tokens, no WETH/WBNB
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum token output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant {
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn);
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 balance = IERC20(path[path.length - 1]).balanceOf(address(this));
        require(balance >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        unwrapSafeTransfer(path[path.length - 1], to, balance);
    }

    /**
     @notice Swap function for fee on transfer tokens with WETH/WBNB
     @param amountOutMin The minimum underlying token output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) nonReentrant {
        require(path[0] == WETH, 'ImpossibleRouter: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn));
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 balance = IERC20(path[path.length - 1]).balanceOf(address(this));
        require(balance >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        unwrapSafeTransfer(path[path.length - 1], to, balance);
    }

    /**
     @notice Swap function for fee on transfer tokens, no WETH/WBNB
     @param amountIn The amount of input tokens
     @param amountOutMin The minimum ETH output amount required for successful swaps
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @param to The address that receives the output tokens
     @param deadline The block number after which this transaction is invalid
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) nonReentrant {
        require(path[path.length - 1] == WETH, 'ImpossibleRouter: INVALID_PATH');
        wrapSafeTransfer(path[0], msg.sender, ImpossibleLibrary.pairFor(factory, path[0], path[1]), amountIn);
        IImpossibleRouterExtension(routerExtension).swapSupportingFeeOnTransferTokens(path);
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    /**
     @notice Function for basic add liquidity functionality
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA to add
     @param tokenB The address of underlying tokenB to add
     @param amountADesired The desired amount of tokenA to add
     @param amountBDesired The desired amount of tokenB to add
     @param amountAMin The min amount of tokenA to add (amountAMin:amountBDesired sets bounds on ratio)
     @param amountBMin The min amount of tokenB to add (amountADesired:amountBMin sets bounds on ratio)
     @param to The address to mint LP tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountA Amount of tokenA added as liquidity to pair
     @return amountB Actual amount of tokenB added as liquidity to pair
     @return liquidity Actual amount of LP tokens minted
    */
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
        virtual
        override
        ensure(deadline)
        nonReentrant
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = IImpossibleRouterExtension(routerExtension).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        wrapSafeTransfer(tokenA, msg.sender, pair, amountA);
        wrapSafeTransfer(tokenB, msg.sender, pair, amountB);
        liquidity = IImpossiblePair(pair).mint(to);
    }

    /**
     @notice Function for add liquidity functionality with 1 token being WETH/WBNB
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to add
     @param amountTokenDesired The desired amount of non-ETH underlying token to add
     @param amountTokenMin The min amount of non-ETH underlying token to add (amountTokenMin:ETH sent sets bounds on ratio)
     @param amountETHMin The min amount of WETH/WBNB to add (amountTokenDesired:amountETHMin sets bounds on ratio)
     @param to The address to mint LP tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountToken Amount of non-ETH underlying token added as liquidity to pair
     @return amountETH Actual amount of WETH/WBNB added as liquidity to pair
     @return liquidity Actual amount of LP tokens minted
    */
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
        virtual
        override
        ensure(deadline)
        nonReentrant
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = IImpossibleRouterExtension(routerExtension).addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        wrapSafeTransfer(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IImpossiblePair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    /**
     @notice Function for basic remove liquidity functionality
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param liquidity The amount of LP tokens to burn
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB) {
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountA, amountB) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            tokenA,
            tokenB,
            pair,
            amountAMin,
            amountBMin
        );
        unwrapSafeTransfer(tokenA, to, amountA);
        unwrapSafeTransfer(tokenB, to, amountB);
    }

    /**
     @notice Function for remove liquidity functionality with 1 token being WETH/WBNB
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountToken Actual amount of non-ETH underlying token received
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountToken, uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountToken, amountETH) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            token,
            WETH,
            pair,
            amountTokenMin,
            amountETHMin
        );
        unwrapSafeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
    @notice Function for remove liquidity functionality using EIP712 permit
     @dev Openzeppelin reentrancy guards
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param liquidity The amount of LP tokens to burn
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
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
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = ImpossibleLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        return removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     @notice Function for remove liquidity functionality using EIP712 permit with 1 token being WETH/WBNB
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountToken Actual amount of non-ETH underlying token received
     @return amountETH Actual amount of WETH/WBNB received
    */
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
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /**
     @notice Function for remove liquidity functionality with 1 token being WETH/WBNB
     @dev This is used when non-WETH/WBNB underlying token is fee-on-transfer: e.g. FEI algo stable v1
     @dev Openzeppelin reentrancy guards
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @return amountETH Actual amount of WETH/WBNB received
    */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) nonReentrant returns (uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        IImpossiblePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (, amountETH) = IImpossibleRouterExtension(routerExtension).removeLiquidity(
            token,
            WETH,
            pair,
            amountTokenMin,
            amountETHMin
        );
        unwrapSafeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     @notice Function for remove liquidity functionality using EIP712 permit with 1 token being WETH/WBNB
     @dev This is used when non-WETH/WBNB underlying token is fee-on-transfer: e.g. FEI algo stable v1
     @param token The address of the non-ETH underlying token to receive
     @param liquidity The amount of LP tokens to burn
     @param amountTokenMin The desired amount of non-ETH underlying token that has to be received
     @param amountETHMin The min amount of ETH that has to be received
     @param to The address to send underlying tokens to
     @param deadline The block number after which this transaction is invalid
     @param approveMax How much tokens are approved for transfer (liquidity, or max)
     @param v,r,s Variables that construct a valid EVM signature
     @return amountETH Actual amount of WETH/WBNB received
    */
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
    ) external virtual override returns (uint256 amountETH) {
        address pair = ImpossibleLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IImpossiblePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/// SPDX-License-Identifier: GPL-3
pragma solidity >=0.5.0;

import '../interfaces/IImpossiblePair.sol';
import '../interfaces/IERC20.sol';

import './SafeMath.sol';
import './Math.sol';

library ImpossibleLibrary {
    using SafeMath for uint256;

    /**
     @notice Sorts tokens in ascending order
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return token0 The address of token 0 (lexicographically smaller than addr of token 1)
     @return token1 The address of token 1 (lexicographically larger than addr of token 0)
    */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ImpossibleLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ImpossibleLibrary: ZERO_ADDRESS');
    }

    /**
     @notice Computes the pair contract create2 address deterministically
     @param factory The address of the token factory (pair contract deployer)
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return pair The address of the pair containing token A and B
    */
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex'fc84b622ba228c468b74c2d99bfe9454ffac280ac017f05a02feb9f739aeb1e4' // init code hash                    
                    )
                )
            )
        );
    }

    /**
     @notice Obtains the token reserves in the pair contract
     @param factory The address of the token factory (pair contract deployer)
     @param tokenA The address of token A
     @param tokenB The address of token B
     @return reserveA The amount of token A in reserves
     @return reserveB The amount of token B in reserves
     @return pair The address of the pair containing token A and B
    */
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            address pair
        )
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pair = pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IImpossiblePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     @notice Quote returns amountB based on some amountA, in the ratio of reserveA:reserveB
     @param amountA The amount of token A
     @param reserveA The amount of reserveA
     @param reserveB The amount of reserveB
     @return amountB The amount of token B that matches amount A in the ratio of reserves
    */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'ImpossibleLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ImpossibleLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     @notice Internal function to compute the K value for an xybk pair based on token balances and boost
     @dev More details on math at: https://docs.impossible.finance/impossible-swap/swap-math
     @dev Implementation is the same as in pair
     @param boost0 Current boost0 in pair
     @param boost1 Current boost1 in pair
     @param balance0 Current state of balance0 in pair
     @param balance1 Current state of balance1 in pair
     @return k Value of K invariant
    */
    function xybkComputeK(
        uint256 boost0,
        uint256 boost1,
        uint256 balance0,
        uint256 balance1
    ) internal pure returns (uint256 k) {
        uint256 boost = (balance0 > balance1) ? boost0.sub(1) : boost1.sub(1);
        uint256 denom = boost.mul(2).add(1); // 1+2*boost
        uint256 term = boost.mul(balance0.add(balance1)).div(denom.mul(2)); // boost*(x+y)/(2+4*boost)
        k = (Math.sqrt(term**2 + balance0.mul(balance1).div(denom)) + term)**2;
    }

    /**
     @notice Internal helper function for calculating artificial liquidity
     @dev More details on math at: https://docs.impossible.finance/impossible-swap/swap-math
     @param _boost The boost variable on the correct side for the pair contract
     @param _sqrtK The sqrt of the invariant variable K in xybk formula
     @return uint256 The artificial liquidity term
    */
    function calcArtiLiquidityTerm(uint256 _boost, uint256 _sqrtK) internal pure returns (uint256) {
        return (_boost - 1).mul(_sqrtK);
    }

    /**
     @notice Quotes maximum output given exact input amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param amountIn The input amount of token A
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return amountOut The maximum output amount of token B for a valid swap
    */
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountInPostFee;
        address pair;
        bool isMatch;
        {
            // Avoid stack too deep
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
        }
        uint256 artiLiqTerm;
        bool isXybk;
        {
            // Avoid stack too deep
            uint256 fee;
            IImpossiblePair.TradeState tradeState;
            (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
            amountInPostFee = amountIn.mul(10000 - fee);
            require(
                (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                'ImpossibleLibrary: TRADE_NOT_ALLOWED'
            );
        }

        /// If xybk invariant, set reserveIn/reserveOut to artificial liquidity instead of actual liquidity
        if (isXybk) {
            (uint256 boost0, uint256 boost1) = IImpossiblePair(pair).calcBoost();
            uint256 sqrtK = Math.sqrt(
                xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
            );
            /// since balance0=balance1 only at sqrtK, if final balanceIn >= sqrtK means balanceIn >= balanceOut
            /// Use post-fee balances to maintain consistency with pair contract K invariant check
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                /// If tokenIn = token0, balanceIn > sqrtK => balance0>sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                /// Don't need to check in other case for reserveIn < reserveIn.add(x) <= sqrtK since that case doesnt cross midpt
                if (reserveIn < sqrtK && boost0 != boost1) {
                    /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub((sqrtK.sub(reserveIn)).mul(10000));
                    reserveIn = sqrtK;
                    reserveOut = sqrtK;
                }
            } else {
                /// If tokenIn = token0, balanceIn < sqrtK => balance0<sqrtK, use boost1
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
    }

    /**
     @notice Quotes minimum input given exact output amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param amountOut The desired output amount of token A
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return amountIn The minimum input amount of token A for a valid swap
    */
    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');

        uint256 reserveIn;
        uint256 reserveOut;
        uint256 artiLiqTerm;
        uint256 fee;
        bool isMatch;
        {
            // Avoid stack too deep
            bool isXybk;
            uint256 boost0;
            uint256 boost1;
            {
                // Avoid stack too deep
                (address token0, ) = sortTokens(tokenIn, tokenOut);
                isMatch = tokenIn == token0;
            }
            {
                // Avoid stack too deep
                address pair;
                (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut);
                IImpossiblePair.TradeState tradeState;
                (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
                require(
                    (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                        (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                        (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                    'ImpossibleLibrary: TRADE_NOT_ALLOWED'
                );
                (boost0, boost1) = IImpossiblePair(pair).calcBoost();
            }
            if (isXybk) {
                uint256 sqrtK = Math.sqrt(
                    xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
                );
                /// since balance0=balance1 only at sqrtK, if final balanceOut >= sqrtK means balanceOut >= balanceIn
                if (reserveOut.sub(amountOut) >= sqrtK) {
                    /// If tokenIn = token0, balanceOut > sqrtK => balance1>sqrtK, use boost1
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
                } else {
                    /// If tokenIn = token0, balanceOut < sqrtK => balance0>sqrtK, use boost0
                    artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                    /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                    /// Don't need to check in other case for reserveOut > reserveOut.sub(x) >= sqrtK since that case doesnt cross midpt
                    if (reserveOut > sqrtK && boost0 != boost1) {
                        /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                        amountIn = sqrtK.sub(reserveIn).mul(10000); /// Still need to divide by (10000 - fee). Do with below calculation to prevent early truncation
                        amountOut = amountOut.sub(reserveOut.sub(sqrtK));
                        reserveOut = sqrtK;
                        reserveIn = sqrtK;
                    }
                }
            }
        }
        uint256 numerator = (reserveIn.add(artiLiqTerm)).mul(amountOut).mul(10000);
        uint256 denominator = (reserveOut.add(artiLiqTerm)).sub(amountOut);
        amountIn = (amountIn.add((numerator / denominator)).div(10000 - fee)).add(1);
    }

    /**
     @notice Quotes maximum output given some uncertain input amount of tokens and addresses of tokens in pair
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param tokenIn The address of input token
     @param tokenOut The address of output token
     @param factory The address of the factory contract
     @return uint256 The maximum possible output amount of token A
     @return uint256 The maximum possible output amount of token B
    */
    function getAmountOutFeeOnTransfer(
        address tokenIn,
        address tokenOut,
        address factory
    ) internal view returns (uint256, uint256) {
        uint256 reserveIn;
        uint256 reserveOut;
        address pair;
        bool isMatch;
        {
            // Avoid stack too deep
            (address token0, ) = sortTokens(tokenIn, tokenOut);
            isMatch = tokenIn == token0;
            (reserveIn, reserveOut, pair) = getReserves(factory, tokenIn, tokenOut); /// Should be reserve0/1 but reuse variables to save stack
        }
        uint256 amountOut;
        uint256 artiLiqTerm;
        uint256 amountInPostFee;
        bool isXybk;
        {
            // Avoid stack too deep
            uint256 fee;
            uint256 balanceIn = IERC20(tokenIn).balanceOf(address(pair));
            require(balanceIn > reserveIn, 'ImpossibleLibrary: INSUFFICIENT_INPUT_AMOUNT');
            IImpossiblePair.TradeState tradeState;
            (fee, tradeState, isXybk) = IImpossiblePair(pair).getPairSettings();
            require(
                (tradeState == IImpossiblePair.TradeState.SELL_ALL) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_0 && !isMatch) ||
                    (tradeState == IImpossiblePair.TradeState.SELL_TOKEN_1 && isMatch),
                'ImpossibleLibrary: TRADE_NOT_ALLOWED'
            );
            amountInPostFee = (balanceIn.sub(reserveIn)).mul(10000 - fee);
        }
        /// If xybk invariant, set reserveIn/reserveOut to artificial liquidity instead of actual liquidity
        if (isXybk) {
            (uint256 boost0, uint256 boost1) = IImpossiblePair(pair).calcBoost();
            uint256 sqrtK = Math.sqrt(
                xybkComputeK(boost0, boost1, isMatch ? reserveIn : reserveOut, isMatch ? reserveOut : reserveIn)
            );
            /// since balance0=balance1 only at sqrtK, if final balanceIn >= sqrtK means balanceIn >= balanceOut
            /// Use post-fee balances to maintain consistency with pair contract K invariant check
            if (amountInPostFee.add(reserveIn.mul(10000)) >= sqrtK.mul(10000)) {
                /// If tokenIn = token0, balanceIn > sqrtK => balance0>sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost0 : boost1, sqrtK);
                /// If balance started from <sqrtK and ended at >sqrtK and boosts are different, there'll be different amountIn/Out
                /// Don't need to check in other case for reserveIn < reserveIn.add(x) <= sqrtK since that case doesnt cross midpt
                if (reserveIn < sqrtK && boost0 != boost1) {
                    /// Break into 2 trades => start point -> midpoint (sqrtK, sqrtK), then midpoint -> final point
                    amountOut = reserveOut.sub(sqrtK);
                    amountInPostFee = amountInPostFee.sub(sqrtK.sub(reserveIn));
                    reserveOut = sqrtK;
                    reserveIn = sqrtK;
                }
            } else {
                /// If tokenIn = token0, balanceIn < sqrtK => balance0<sqrtK, use boost0
                artiLiqTerm = calcArtiLiquidityTerm(isMatch ? boost1 : boost0, sqrtK);
            }
        }
        uint256 numerator = amountInPostFee.mul(reserveOut.add(artiLiqTerm));
        uint256 denominator = (reserveIn.add(artiLiqTerm)).mul(10000).add(amountInPostFee);
        uint256 lastSwapAmountOut = numerator / denominator;
        amountOut = (lastSwapAmountOut > reserveOut) ? reserveOut.add(amountOut) : lastSwapAmountOut.add(amountOut);
        return isMatch ? (uint256(0), amountOut) : (amountOut, uint256(0));
    }

    /**
     @notice Quotes maximum output given exact input amount of tokens and addresses of tokens in trade sequence
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param factory The address of the IF factory
     @param amountIn The input amount of token A
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @return amounts The maximum possible output amount of all tokens through sequential swaps
    */
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'ImpossibleLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(amounts[i], path[i], path[i + 1], factory);
        }
    }

    /**
     @notice Quotes minimum input given exact output amount of tokens and addresses of tokens in trade sequence
     @dev The library function considers custom swap fees/invariants/asymmetric tuning of pairs
     @dev However, library function doesn't consider limits created by hardstops
     @param factory The address of the IF factory
     @param amountOut The output amount of token A
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
     @return amounts The minimum output amount required of all tokens through sequential swaps
    */
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'ImpossibleLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(amounts[i], path[i - 1], path[i], factory);
        }
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event UpdatedGovernance(address governance);

    function feeTo() external view returns (address);

    function governance() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setGovernance(address) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IImpossiblePair.sol';

interface IImpossibleRouterExtension {
    function factory() external returns (address factoryAddr);

    function swap(uint256[] memory amounts, address[] memory path) external;

    function swapSupportingFeeOnTransferTokens(address[] memory path) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.6.2;

interface IImpossibleRouter {
    function factory() external view returns (address factoryAddr);

    function routerExtension() external view returns (address routerExtensionAddr);

    function wrapFactory() external view returns (address wrapFactoryAddr);

    function WETH() external view returns (address WETHAddr);

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
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IERC20.sol';

interface IImpossibleWrappedToken is IERC20 {
    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);

    function amtToUnderlyingAmt(uint256) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleWrapperFactory {
    event WrapCreated(address, address, uint256, uint256);
    event WrapDeleted(address, address);

    function tokensToWrappedTokens(address) external view returns (address);

    function wrappedTokensToTokens(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IImpossibleERC20.sol';

interface IImpossiblePair is IImpossibleERC20 {
    enum TradeState {
        SELL_ALL,
        SELL_TOKEN_0,
        SELL_TOKEN_1,
        SELL_NONE
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event ChangeInvariant(bool _isXybk, uint256 _newBoost0, uint256 _newBoost1);
    event UpdatedTradeFees(uint256 _oldFee, uint256 _newFee);
    event UpdatedDelay(uint256 _oldDelay, uint256 _newDelay);
    event UpdatedTradeState(TradeState _tradeState);
    event UpdatedWithdrawalFeeRatio(uint256 _oldWithdrawalFee, uint256 _newWithdrawalFee);
    event UpdatedBoost(
        uint32 _oldBoost0,
        uint32 _oldBoost1,
        uint32 _newBoost0,
        uint32 _newBoost1,
        uint256 _start,
        uint256 _end
    );

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address); // address of token0

    function token1() external view returns (address); // address of token1

    function getReserves() external view returns (uint256, uint256); // reserves of token0/token1

    function calcBoost() external view returns (uint256, uint256);

    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function swap(
        uint256,
        uint256,
        address,
        bytes calldata
    ) external;

    function skim(address to) external;

    function sync() external;

    function getPairSettings()
        external
        view
        returns (
            uint16,
            TradeState,
            bool
        ); // Uses single storage slot, save gas

    function delay() external view returns (uint256); // Amount of time delay required before any change to boost etc, denoted in seconds

    function initialize(
        address,
        address,
        address,
        address
    ) external;
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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
}