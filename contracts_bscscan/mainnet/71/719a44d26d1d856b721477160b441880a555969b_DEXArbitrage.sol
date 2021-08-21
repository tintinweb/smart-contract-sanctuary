/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}



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



interface IUniswapV2Router {
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





contract PancakeSwapBackend {
	IUniswapV2Router PancakeRouterV1;
	IUniswapV2Router PancakeRouterV2;
	IUniswapV2Factory PancakeFactoryV1;
	IUniswapV2Factory PancakeFactoryV2;
	address wbnb;
	
	constructor() {
		PancakeRouterV1 = IUniswapV2Router(address(0x3a065f9B30CBA18f39B874748F0e919b5D3c9A01));
		PancakeRouterV2 = IUniswapV2Router(address(0x10ED43C718714eb63d5aA57B78B54704E256024E));
		PancakeFactoryV1 = IUniswapV2Factory(PancakeRouterV1.factory());
		PancakeFactoryV2 = IUniswapV2Factory(PancakeRouterV2.factory());
		wbnb = PancakeRouterV1.WETH();
	}
	
	function getBuyPriceOnV1(address tokenAddress, uint256 bnbAmount) internal view returns (uint256) {
		address PairAddress = PancakeFactoryV1.getPair(wbnb, tokenAddress);
		uint256 wBNBPooled = ERC20Interface(wbnb).balanceOf(PairAddress);
		uint256 tokenPooled = ERC20Interface(tokenAddress).balanceOf(PairAddress);
		return PancakeRouterV1.getAmountOut(bnbAmount, wBNBPooled, tokenPooled);
	}


	
	function getBuyPriceOnV2(address tokenAddress, uint256 bnbAmount) internal view returns (uint256) {
		address PairAddress = PancakeFactoryV2.getPair(wbnb, tokenAddress);
		uint256 wBNBPooled = ERC20Interface(wbnb).balanceOf(PairAddress);
		uint256 tokenPooled = ERC20Interface(tokenAddress).balanceOf(PairAddress);
		return PancakeRouterV2.getAmountOut(bnbAmount, wBNBPooled, tokenPooled);
	}
	
	function getSellPriceOnv1(address tokenAddress, uint256 tokenAmount) internal view returns (uint256) {
		address PairAddress = PancakeFactoryV1.getPair(wbnb, tokenAddress);
		uint256 wBNBPooled = ERC20Interface(wbnb).balanceOf(PairAddress);
		uint256 tokenPooled = ERC20Interface(tokenAddress).balanceOf(PairAddress);
		return PancakeRouterV1.getAmountOut(tokenAmount, tokenPooled, wBNBPooled);
	}
	
	function getSellPriceOnv2(address tokenAddress, uint256 tokenAmount) internal view returns (uint256) {
		address PairAddress = PancakeFactoryV2.getPair(wbnb, tokenAddress);
		uint256 wBNBPooled = ERC20Interface(wbnb).balanceOf(PairAddress);
		uint256 tokenPooled = ERC20Interface(tokenAddress).balanceOf(PairAddress);
		return PancakeRouterV2.getAmountOut(tokenAmount, tokenPooled, wBNBPooled);
	}



	function swapTokensForEthv1(uint256 tokenAmount, address tokenAddress) internal {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = tokenAddress;
		path[1] = wbnb;

		ERC20Interface(tokenAddress).approve(address(PancakeRouterV1), tokenAmount);

		// make the swap
		PancakeRouterV1.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}


	function swapEthForTokensv1(uint256 ethAmount, address tokenAddress) internal {
		address[] memory path = new address[](2);
		path[0] = wbnb;
		path[1] = tokenAddress;

		PancakeRouterV1.swapExactETHForTokens{value:ethAmount}(0, path, address(this), block.timestamp);
	}



	// pancake v2 pair settings


	function swapTokensForEthv2(uint256 tokenAmount, address tokenAddress) internal {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = tokenAddress;
		path[1] = wbnb;

		ERC20Interface(tokenAddress).approve(address(PancakeRouterV2), tokenAmount);

		// make the swap
		PancakeRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}


	function swapEthForTokensv2(uint256 ethAmount, address tokenAddress) internal {
		address[] memory path = new address[](2);
		path[0] = PancakeRouterV2.WETH();
		path[1] = tokenAddress;

		PancakeRouterV2.swapExactETHForTokens{value:ethAmount}(0, path, address(this), block.timestamp);
	}
}


contract bestPriceChecker is PancakeSwapBackend {
	function getBestBuyPrice(address tokenAddress, uint256 bnbAmount) internal view returns (uint8 bestExchange) {
		uint256 v1Price = PancakeSwapBackend.getBuyPriceOnV1(tokenAddress, bnbAmount);
		uint256 v2Price = PancakeSwapBackend.getBuyPriceOnV2(tokenAddress, bnbAmount);
		if (v1Price > v2Price) {
			return 1;
		}
		else {
			return 2;
		}
	}
	
	function getBestSellPrice(address tokenAddress, uint256 tokenAmount) internal view returns (uint8 bestExchange) {
		uint256 v1Price = PancakeSwapBackend.getSellPriceOnv1(tokenAddress, tokenAmount);
		uint256 v2Price = PancakeSwapBackend.getSellPriceOnv2(tokenAddress, tokenAmount);
		if (v1Price > v2Price) {
			return 1;
		}
		else {
			return 2;
		}
	}
	
	function buyAtBestPrice(address tokenAddress, uint256 bnbAmount) internal {
		uint8 bestExchangeForBuying = getBestBuyPrice(tokenAddress, bnbAmount);
		if (bestExchangeForBuying == 1) {
			PancakeSwapBackend.swapEthForTokensv1(bnbAmount, tokenAddress);
		}
		else if (bestExchangeForBuying == 2) {
			PancakeSwapBackend.swapEthForTokensv2(bnbAmount, tokenAddress);
		}
	}
	
	function sellAtBestPrice(address tokenAddress, uint256 tokenAmount) internal {
		uint8 bestExchangeForSelling = getBestSellPrice(tokenAddress, tokenAmount);
		if (bestExchangeForSelling == 1) {
			PancakeSwapBackend.swapTokensForEthv1(tokenAmount, tokenAddress);
		}
		else if (bestExchangeForSelling == 2) {
			PancakeSwapBackend.swapTokensForEthv2(tokenAmount, tokenAddress);
		}
	}
}


interface devAddressInterface {
	function isDev(address to) external view returns (bool);
}

contract DEXArbitrage is bestPriceChecker {

	modifier onlyDev() {
		require(devAddressInterface(0x4eeCD049Cc09664F1aD72d92e8b5FCf3f85dfd67).isDev(msg.sender));
		_;
	}

	function tryArbitrage(address tokenAddress, uint256 minimumProfit) public onlyDev payable {
		uint256 initialBalance = address(this).balance;
		bestPriceChecker.buyAtBestPrice(tokenAddress, initialBalance);
		uint256 tokenBalance = ERC20Interface(tokenAddress).balanceOf(address(this));
		bestPriceChecker.sellAtBestPrice(tokenAddress, tokenBalance);
		uint256 finalBalance = address(this).balance;
		if (finalBalance > (initialBalance + minimumProfit)) {
			uint256 toSendToUser = finalBalance;
			msg.sender.transfer(toSendToUser);
		}
		else {
			revert("ArbitrageMaker: unprofitable trade");
		}
	}
	
	receive() external payable {}
	fallback() external payable {}
}