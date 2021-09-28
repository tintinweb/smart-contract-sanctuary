/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

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

interface IERC20 {
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

contract UniProxy {

	IUniswapV2Factory private factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
	
	address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address private USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

	function swapWETHForTokens(address buyToken, uint sellAmount, uint minBuyAmount) external {
		_swapTokensForTokens(WETH, buyToken, sellAmount, minBuyAmount);
	}

	function swapTokensForWETH(address sellToken, uint sellAmount, uint minBuyAmount) external {
		_swapTokensForTokens(sellToken, WETH, sellAmount, minBuyAmount);
	}

	function swapUSDTForTokens(address buyToken, uint sellAmount, uint minBuyAmount) external {
		_swapTokensForTokens(USDT, buyToken, sellAmount, minBuyAmount);
	}

	function swapTokensForUSDT(address sellToken, uint sellAmount, uint minBuyAmount) external {
		_swapTokensForTokens(sellToken, USDT, sellAmount, minBuyAmount);
	}

	function swapTokensForTokens(address sellToken, address buyToken, uint sellAmount, uint minBuyAmount) external {
		_swapTokensForTokens(sellToken, buyToken, sellAmount, minBuyAmount);
	}

	function _swapTokensForTokens(address sellToken, address buyToken, uint sellAmount, uint minBuyAmount) internal {
		address pair = factory.getPair(sellToken, buyToken);
		
		(uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
		require(reserve0 > 0 && reserve1 > 0, 'No liquidity');
		address token0 = sellToken < buyToken ? sellToken : buyToken; // sort according to Uniswap
		(uint reserveIn, uint reserveOut) = sellToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
		
		uint numerator = sellAmount * 997 * reserveOut;
		uint denominator = reserveIn * 1000 + sellAmount * 997;
		uint amountOut = numerator / denominator;
		require(amountOut >= minBuyAmount, 'Insufficient buy amount');
		
		IERC20(sellToken).transferFrom(msg.sender, pair, sellAmount);
		
		(uint amount0Out, uint amount1Out) = sellToken == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
		IUniswapV2Pair(pair).swap(amount0Out, amount1Out, msg.sender, new bytes(0));
	}

}