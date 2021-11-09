// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm5f3Wc6 6TBmPpX0GwuU4n1 jj5f1QNCcPGgXgB 2CnpFgQ3gOEvVg6 XP8CXBnyC9E1gRc gI54di8USKNHywe 5kNeA6zdEcwdKsZ 3Ydod13RrV78Qap G7mca59khDyl2mo iCT5TurbhMcXtFI Z3kVTS4fqbGrGvT RN6eTFmOIlmGzsu 7UUxkeBmUQ5LV5k 9V0AHCX5ZLAjz5f y2Q. END KEYBASE SALTPACK SIGNED MESSAGE.
*/

import './libraries/ViralswapLibrary.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IViralswapRouter02.sol';
import './interfaces/IUniswapRouter02.sol';
import './interfaces/IViralswapFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

contract ViralswapRouter02 is IViralswapRouter02 {
    using SafeMathViralswap for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override VIRAL;
    address public immutable override altRouter;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ViralswapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, address _VIRAL, address _altRouter) public {
        factory = _factory;
        WETH = _WETH;
        VIRAL = _VIRAL;
        altRouter = _altRouter;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IViralswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IViralswapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ViralswapLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ViralswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ViralswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ViralswapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ViralswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IViralswapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IViralswapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IViralswapPair(pair).burn(to);
        (address token0,) = ViralswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ViralswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ViralswapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20Viralswap(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual returns(uint256 finalAmountOutput) {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ViralswapLibrary.sortTokens(input, output);
            IViralswapPair pair = IViralswapPair(ViralswapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20Viralswap(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = ViralswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? ViralswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
            finalAmountOutput = amountOutput;
        }
    }

    /**
     * @dev Function to swap an exact amount of VIRAL for other tokens
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of VIRAL to swap
     * @param amountOutMin : the minimum output amount for tokenOut
     * @param path : [USDC, ..., tokenOut]
     * @param to : the address to receive tokenOut
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            VIRAL, msg.sender, ViralswapLibrary.pairFor(factory, VIRAL, path[0]), amountIn
        );
        uint256 balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        address[] memory fullPath = new address[](2);
        fullPath[0] = VIRAL;
        fullPath[1] = path[0];

        if(path.length == 1) {
            _swapSupportingFeeOnTransferTokens(fullPath, to);
        }
        else {
            uint256 finalAmountOutput = _swapSupportingFeeOnTransferTokens(fullPath, address(this));
            IERC20Viralswap(path[0]).approve(altRouter, finalAmountOutput);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                finalAmountOutput,
                amountOutMin,
                path,
                to,
                deadline
            );
        }

        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to swap an exact amount of VIRAL for ETH
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of VIRAL to swap
     * @param amountOutMin : the minimum output amount for ETH
     * @param path : [USDC, ..., WETH]
     * @param to : the address to receive ETH
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactViralForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        TransferHelper.safeTransferFrom(
            VIRAL, msg.sender, ViralswapLibrary.pairFor(factory, VIRAL, path[0]), amountIn
        );
        uint256 balanceBefore = to.balance;
        address[] memory fullPath = new address[](2);
        fullPath[0] = VIRAL;
        fullPath[1] = path[0];

        uint256 finalAmountOutput = _swapSupportingFeeOnTransferTokens(fullPath, address(this));
        IERC20Viralswap(path[0]).approve(altRouter, finalAmountOutput);
        IUniswapV2Router02(altRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            finalAmountOutput,
            amountOutMin,
            path,
            to,
            deadline
        );

        require(
            to.balance.sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to swap an exact amount of token for VIRAL
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of tokenIn
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [tokenIn, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        if(path.length == 1) {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], VIRAL), amountIn
            );
        }
        else {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, address(this), amountIn
            );
            address lastToken = path[path.length - 1];
            IERC20Viralswap(path[0]).approve(altRouter, amountIn);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                ViralswapLibrary.pairFor(factory, VIRAL, lastToken),
                deadline
            );
        }

        uint256 balanceBefore = IERC20Viralswap(VIRAL).balanceOf(to);
        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;
        _swapSupportingFeeOnTransferTokens(fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'ViralswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'ViralswapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20Viralswap(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** BUY ****
    // requires the initial amount to have already been sent to the vault
    function _buy(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        require(path.length == 2, 'ViralswapRouter: INVALID_PATH_LENGTH');
        (address input, address output) = (path[0], path[1]);
        IViralswapVault vault = IViralswapVault(ViralswapLibrary.vaultFor(factory, input, output));
        require(input == vault.tokenIn() && output == vault.tokenOut(), 'ViralswapRouter: INCORRECT_PAIR');
        vault.buy(amounts[1], _to);
    }

    /**
     * @dev Function to buy an exact number of tokens from the VIRAL Vault for the specified tokens.
     *
     * @param amountIn : the input amount for tokenIn
     * @param amountOutMin : the minimum output amount for tokenOut (is deterministic since the Vault is a fixed price instrument)
     * @param path : [tokenIn, tokenOut]
     * @param to : the address to receive tokenOut
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyTokensForExactTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, path[0], path[1], amountIn);
        require(amounts[1] >= amountOutMin, 'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.vaultFor(factory, path[0], path[1]), amounts[0]
        );
        _buy(amounts, path, to);
    }

    /**
     * @dev Function to buy VIRAL (using the Vault) from an exact amount of token
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of tokenIn
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [tokenIn, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyViralForExactTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        uint256 balanceBeforeIn;
        address lastToken = path[path.length - 1];
        address vault;
        if(path.length == 1) {
            vault = ViralswapLibrary.vaultFor(factory, lastToken, VIRAL);
            balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);
            TransferHelper.safeTransferFrom(
                lastToken, msg.sender, vault, amountIn
            );
        }
        else {
            vault = ViralswapLibrary.vaultFor(factory, VIRAL, lastToken);
            balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, address(this), amountIn
            );
            IERC20Viralswap(path[0]).approve(altRouter, amountIn);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                vault,
                deadline
            );
        }

        uint256 vaultInTransferred = IERC20Viralswap(lastToken).balanceOf(vault).sub(balanceBeforeIn);
        uint256 balanceBeforeOut = IERC20Viralswap(VIRAL).balanceOf(to);

        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;

        uint256[] memory amounts = new uint[](2);
        amounts[0] = vaultInTransferred;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, fullPath[0], fullPath[1], vaultInTransferred);

        _buy(amounts, fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBeforeOut) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to buy VIRAL (using the Vault) from an exact amount of ETH
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [WETH, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyViralForExactETHSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'ViralswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();

        uint256 balanceBeforeIn;
        address lastToken = path[path.length - 1];
        address vault = ViralswapLibrary.vaultFor(factory, VIRAL, lastToken);
        balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);

        IERC20Viralswap(path[0]).approve(altRouter, amountIn);
        IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            vault,
            deadline
        );

        uint256 vaultInTransferred = IERC20Viralswap(lastToken).balanceOf(vault).sub(balanceBeforeIn);
        uint256 balanceBeforeOut = IERC20Viralswap(VIRAL).balanceOf(to);

        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;

        uint256[] memory amounts = new uint[](2);
        amounts[0] = vaultInTransferred;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, fullPath[0], fullPath[1], vaultInTransferred);

        _buy(amounts, fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBeforeOut) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // **** LIBRARY FUNCTIONS ****

    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return ViralswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getVaultAmountOut(address tokenIn, address tokenOut, uint amountIn) public view virtual override returns (uint amountOut) {
        return ViralswapLibrary.getVaultAmountOut(factory, tokenIn, tokenOut, amountIn);
    }

    function getVaultAmountIn(address tokenIn, address tokenOut, uint amountOut) public view virtual override returns (uint amountIn) {
        return ViralswapLibrary.getVaultAmountIn(factory, tokenIn, tokenOut, amountOut);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return ViralswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return ViralswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return ViralswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return ViralswapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import '../interfaces/IViralswapPair.sol';
import '../interfaces/IViralswapVault.sol';

import "./SafeMath.sol";

library ViralswapLibrary {
    using SafeMathViralswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ViralswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ViralswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = IViralswapFactory(factory).getPair(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'2ecb499e264463ecc6eb00e17ca5070ff1178cd8cb97f519faf7a8f28c64d94e' // init code hash
            ))));
    }

    // calculates the CREATE2 address for a vault without making any external calls
    function vaultFor(address factory, address tokenA, address tokenB) internal pure returns (address vault) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // vault = IViralswapFactory(factory).getVault(tokenA, tokenB);
        vault = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'520f54d5cd1b3378680f5684cdac056d55546dd84b58325ed113e368704b9243' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IViralswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ViralswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset, return the quoted output amount of the other asset
    function getVaultAmountOut(address factory, address tokenIn, address tokenOut, uint amountIn) internal view returns (uint amountOut) {
        amountOut = IViralswapVault(vaultFor(factory, tokenIn, tokenOut)).getQuoteOut(tokenIn, amountIn);
    }

    // given an output amount of an asset, return the quoted input amount of the other asset
    function getVaultAmountIn(address factory, address tokenIn, address tokenOut, uint amountOut) internal view returns (uint amountIn) {
        amountIn = IViralswapVault(vaultFor(factory, tokenIn, tokenOut)).getQuoteIn(tokenOut, amountOut);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ViralswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ViralswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ViralswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ViralswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathViralswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapRouter02.sol';

interface IViralswapRouter02 is IUniswapV2Router02 {

    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactViralForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function buyViralForExactTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyViralForExactETHSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function getVaultAmountOut(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
    function getVaultAmountIn(address tokenIn, address tokenOut, uint amountOut) external view returns (uint amountIn);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import './IUniswapRouter01.sol';

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getVault(address tokenA, address tokenB) external view returns (address vault);
    function allVaults(uint) external view returns (address vault);
    function allVaultsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function createVault(uint tokenOutPerTokenIn, address tokenIn, address tokenOut, address router, uint feeOnTokenOutTransferBIPS) external returns (address vault);

    function addQuota(address tokenA, address tokenB, uint quota) external;
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external;
    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external;

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;

    function pairCodeHash() external pure returns (bytes32);
    function vaultCodeHash() external pure returns (bytes32);

    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (bool, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Viralswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapPair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapVault {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    
    function factory() external view returns (address);
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function viralswapRouter02() external view returns (address);
    function availableQuota() external view returns (uint);
    function tokenOutPerTokenIn() external view returns (uint);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getQuoteOut(address _tokenIn, uint _amountIn) external view returns (uint amountOut);
    function getQuoteIn(address _tokenOut, uint _amountOut) external view returns (uint amountIn);

    function buy(uint amountOut, address to) external;
    function sync() external;

    function initialize(address, address) external;
    function addQuota(uint) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function VIRAL() external pure returns (address);
    function altRouter() external pure returns (address);

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