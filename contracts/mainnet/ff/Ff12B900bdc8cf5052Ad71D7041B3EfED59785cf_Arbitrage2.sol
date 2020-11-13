// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ERC20
{
	function name() external view returns (string memory _name);
	function symbol() external view returns (string memory _symbol);
	function decimals() external view returns (uint8 _decimals);

	function totalSupply() external view returns (uint256 _totalSupply);
	function balanceOf(address _owner) external view returns (uint256 _balance);
	function transfer(address _to, uint256 _value) external returns (bool _success);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
	function approve(address _spender, uint256 _value) external returns (bool _success);
	function allowance(address _owner, address _spender) external view returns (uint256 _remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface Exchange is ERC20
{
	function tokenAddress() external view returns (address _token);
	function factoryAddress() external view returns (address _factory);
	function addLiquidity(uint256 _minLiquidity, uint256 _maxTokens, uint256 _deadline) external payable returns (uint256 _mintedLiquidity);
	function removeLiquidity(uint256 _amount, uint256 _minEth, uint256 _minTokens, uint256 _deadline) external returns (uint256 _ethRemoved, uint256 _tokensRemoved);
	function getEthToTokenInputPrice(uint256 _ethSold) external view returns (uint256 _tokensBought);
	function getEthToTokenOutputPrice(uint256 _tokensBought) external view returns (uint256 _ethSold);
	function getTokenToEthInputPrice(uint256 _tokensSold) external view returns (uint256 _ethBought);
	function getTokenToEthOutputPrice(uint256 _ethBought) external view returns (uint256 _tokensSold);
	function ethToTokenSwapInput(uint256 _minTokens, uint256 _deadline) external payable returns (uint256 _tokensBought);
	function ethToTokenTransferInput(uint256 _minTokens, uint256 _deadline, address _recipient) external payable returns (uint256 _tokensBought);
	function ethToTokenSwapOutput(uint256 _tokensBought, uint256 _deadline) external payable returns (uint256 _ethSold);
	function ethToTokenTransferOutput(uint256 _tokensBought, uint256 _deadline, address _recipient) external payable returns (uint256 _ethSold);
	function tokenToEthSwapInput(uint256 _tokensSold, uint256 _minEth, uint256 _deadline) external returns (uint256 _ethBought);
	function tokenToEthTransferInput(uint256 _tokensSold, uint256 _minEth, uint256 _deadline, address _recipient) external returns (uint256 _ethBought);
	function tokenToEthSwapOutput(uint256 _ethBought, uint256 _maxTokens, uint256 _deadline) external returns (uint256 _tokensSold);
	function tokenToEthTransferOutput(uint256 _ethBought, uint256 _maxTokens, uint256 _deadline, address _recipient) external returns (uint256 _tokensSold);
	function tokenToTokenSwapInput(uint256 _tokensSold, uint256 _minTokensBought, uint256 _minEthBought, uint256 _deadline, address _tokenAddr) external returns (uint256 _tokensBought);
	function tokenToTokenTransferInput(uint256 _tokensSold, uint256 _minTokensBought, uint256 _minEthBought, uint256 _deadline, address _recipient, address _tokenAddr) external returns (uint256 _tokensBought);
	function tokenToTokenSwapOutput(uint256 _tokensBought, uint256 _maxTokensSold, uint256 _maxEthSold, uint256 _deadline, address _tokenAddr) external returns (uint256 _tokensSold);
	function tokenToTokenTransferOutput(uint256 _tokensBought, uint256 _maxTokensSold, uint256 _maxEthSold, uint256 _deadline, address _recipient, address _tokenAddr) external returns (uint256 _tokensSold);
	function tokenToExchangeSwapInput(uint256 _tokensSold, uint256 _minTokensBought, uint256 _minEthBought, uint256 _deadline, address _exchangeAddr) external returns (uint256 _tokensBought);
	function tokenToExchangeTransferInput(uint256 _tokensSold, uint256 _minTokensBought, uint256 _minEthBought, uint256 _deadline, address _recipient, address _exchangeAddr) external returns (uint256 _tokensBought);
	function tokenToExchangeSwapOutput(uint256 _tokensBought, uint256 _maxTokensSold, uint256 _maxEthSold, uint256 _deadline, address _exchangeAddr) external returns (uint256 _tokensSold);
	function tokenToExchangeTransferOutput(uint256 _tokensBought, uint256 _maxTokensSold, uint256 _maxEthSold, uint256 _deadline, address _recipient, address _exchangeAddr) external returns (uint256 _tokensSold);

	event TokenPurchase(address indexed _buyer, uint256 indexed _ethSold, uint256 indexed _tokensBought);
	event EthPurchase(address indexed _buyer, uint256 indexed _tokensSold, uint256 indexed _ethBought);
	event AddLiquidity(address indexed _provider, uint256 indexed _ethAmount, uint256 indexed _tokenAmount);
	event RemoveLiquidity(address indexed _provider, uint256 indexed _ethAmount, uint256 indexed _tokenAmount);
}

interface WrappedEther is ERC20
{
	receive() external payable;
	function deposit() external payable;
	function withdraw(uint256 _amount) external;

	event  Deposit(address indexed _address, uint256 _amount);
	event  Withdrawal(address indexed _address, uint256 _amount);
}

interface PoolToken is ERC20
{
	function DOMAIN_SEPARATOR() external view returns (bytes32 _DOMAIN_SEPARATOR);
	function PERMIT_TYPEHASH() external pure returns (bytes32 _PERMIT_TYPEHASH);
	function nonces(address _owner) external view returns (uint256 _nonces);
	function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
}

interface Pair is PoolToken
{
	function MINIMUM_LIQUIDITY() external pure returns (uint256 _MINIMUM_LIQUIDITY);
	function factory() external view returns (address _factory);
	function token0() external view returns (address _token0);
	function token1() external view returns (address _token1);
	function price0CumulativeLast() external view returns (uint256 _price0CumulativeLast);
	function price1CumulativeLast() external view returns (uint256 _price1CumulativeLast);
	function kLast() external view returns (uint256 _kLast);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
	function mint(address _to) external returns (uint256 _liquidity);
	function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);
	function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;
	function skim(address _to) external;
	function sync() external;

	event Mint(address indexed _sender, uint256 _amount0, uint256 _amount1);
	event Burn(address indexed _sender, uint256 _amount0, uint256 _amount1, address indexed _to);
	event Swap(address indexed _sender, uint256 _amount0In, uint256 _amount1In, uint256 _amount0Out, uint256 _amount1Out, address indexed _to);
	event Sync(uint112 _reserve0, uint112 _reserve1);
}

interface Router01
{
	function factory() external pure returns (address _factory);
	function WETH() external pure returns (address _token);
	function addLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB, uint256 _liquidity);
	function addLiquidityETH(address _token, uint256 _amountTokenDesired, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external payable returns (uint256 _amountToken, uint256 _amountETH, uint256 _liquidity);
	function removeLiquidity(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB);
	function removeLiquidityETH(address token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external returns (uint256 _amountToken, uint256 _amountETH);
	function removeLiquidityWithPermit(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256 _amountA, uint256 _amountB);
	function removeLiquidityETHWithPermit(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256 _amountToken, uint256 _amountETH);
	function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapTokensForExactTokens(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function swapTokensForExactETH(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapExactTokensForETH(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function quote(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) external pure returns (uint256 _amountB);
	function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountOut);
	function getAmountIn(uint256 _amountOut, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountIn);
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);
}

interface Router02 is Router01
{
	function removeLiquidityETHSupportingFeeOnTransferTokens(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external returns (uint256 _amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint _amountETH);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
}

contract Arbitrage2
{
	WrappedEther constant WETH = WrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

	receive() external payable { }
	fallback() external payable { }

	function uniswapV2Call(address payable _swapper, uint256 _amount0, uint256 _amount1, bytes calldata _data) external
	{
		Pair _uniswapV2 = Pair(msg.sender);
		uint256 _sellPrice = _amount0 + _amount1;
		(Exchange _uniswapV1, uint256 _size) = abi.decode(_data, (Exchange, uint256));
		ERC20 token = ERC20(_uniswapV1.tokenAddress());

		WETH.withdraw(_sellPrice);

		uint _buyPrice = _uniswapV1.ethToTokenSwapOutput{ value: _sellPrice }(_size, uint256(-1));

		require(token.transfer(address(_uniswapV2), _size));

		uint256 _profit = _sellPrice - _buyPrice;
		_swapper.transfer(_profit);
	}
}