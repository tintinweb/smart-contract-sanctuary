/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-18
*/

pragma solidity >=0.8.0;
interface IVeeERC20 {
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



/** 
 *  SourceUnit: /Users/kou/Desktop/Vee/contract-test/deploy/deploy-avalanche/contracts/periphery/AutoSwapPlus.sol
*/
            
pragma solidity >=0.8.0;

interface IPangolinPair {
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




/** 
 *  SourceUnit: /Users/kou/Desktop/Vee/contract-test/deploy/deploy-avalanche/contracts/periphery/AutoSwapPlus.sol
*/
            
pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
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
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/** 
 *  SourceUnit: /Users/kou/Desktop/Vee/contract-test/deploy/deploy-avalanche/contracts/periphery/AutoSwapPlus.sol
*/

pragma solidity ^0.8.0;
////import "./interface/IPangolinRouter.sol";
////import "./interface/IPangolinPair.sol";
////import "./interface/IVeeERC20.sol";

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

contract AutoSwapPlus {
	address public admin;
	address public vee;
	address public usdt;
	address public wavax;
	address public veeusdtPair;
	address public veeavaxPair;
	address public avaxusdtPair;
	IPangolinRouter public router;
	uint public profitThreshold;  //decimals 1e6
	constructor(address _admin,address _router,address _veeusdtPair,address _veeavaxPair,address _avaxusdtPair,address _vee,address _usdt,address _wavax){
		admin = _admin;
		vee = _vee;
		usdt = _usdt;
		wavax = _wavax;
		veeavaxPair = _veeavaxPair;
		veeusdtPair = _veeusdtPair;
		avaxusdtPair = _avaxusdtPair;
		router = IPangolinRouter(_router);
		profitThreshold = 5e6;
	}
	receive() external payable {}


	function updateProfirThreshold(uint _profitThreshold) external{
		require(msg.sender == admin);
		profitThreshold = _profitThreshold;
	}

	function scan() external{
		(uint veeReserveAVAX,uint avaxReserve) = getReserves(veeavaxPair);
		(uint veeReserveUSDT,uint usdtReserve) = getReserves(veeusdtPair);
		uint avax_usdtPrice = getAVAXPrice();
		uint avax_veePrice = veeReserveAVAX * 1e18 / avaxReserve;
		uint vee_usdtPrice = usdtReserve * 1e30 / veeReserveUSDT;

		uint vee_usdtPriceAVAX = avax_usdtPrice * 1e18 / avax_veePrice;

		uint deadline = (block.timestamp + 99999999);
		address[] memory path = new address[](3);
		
		if(vee_usdtPriceAVAX > vee_usdtPrice){

			// USDT 买 VEE 换 AVAX
			uint usdtAmountIn = getUSDTAmountIn(usdtReserve, veeReserveUSDT, vee_usdtPriceAVAX);
			path[0] = usdt;
			path[1] = vee;
			path[2] = wavax;
			IVeeERC20 usdtToken = IVeeERC20(usdt);
			usdtToken.approve(address(router), usdtAmountIn);
			uint[] memory amounts = router.swapExactTokensForAVAX(usdtAmountIn, 0, path, admin, deadline);
			uint profit = amounts[2] * vee_usdtPriceAVAX / 1e30;
			require(profit >= profitThreshold,"profit not enough");

		}else{
			// AVAX 买 VEE 换 USDT
			uint avaxAmountIn = getAVAXAmountIn(avaxReserve, veeReserveAVAX, vee_usdtPriceAVAX);
			path[0] = wavax;
			path[1] = vee;
			path[2] = usdt;
			uint[] memory amounts = router.swapExactAVAXForTokens{value:avaxAmountIn}(0, path, admin, deadline);
			uint cost = avaxAmountIn * avax_usdtPrice / 1e30;
			require(amounts[2]>cost,"no profit");
			uint profit = amounts[2] - cost;
			require(profit>=profitThreshold,"profit not enough");

		}

	}

	function withdrawAVAX(uint amount) external {
		require(msg.sender == admin);
		payable(admin).transfer(amount); 
	}

	function withdrawUSDT(uint amount) external {
		require(msg.sender == admin);
		IVeeERC20(usdt).transfer(admin, amount);
	}

	function getUSDTAmountIn(uint usdtReserve,uint veeReserve,uint anchoredPrice) internal pure returns(uint amountIn){
		uint kLast = veeReserve * usdtReserve;
		amountIn = kLast/(Math.sqrt(kLast * anchoredPrice / 1e30)) - usdtReserve;
	}

	function getAVAXAmountIn(uint avaxReserve,uint veeReserve,uint anchoredPrice) internal pure returns(uint amountIn){
		uint kLast = avaxReserve * veeReserve;
		amountIn = kLast/(Math.sqrt(kLast * anchoredPrice / 1e30)) - avaxReserve;
	}

	function getAVAXPrice() internal view returns(uint price){
		(uint reserve0,uint reserve1,) = IPangolinPair(avaxusdtPair).getReserves();
		uint avaxReserve;
		uint usdtReserve;
		if(wavax < usdt){
			avaxReserve = reserve0;
			usdtReserve = reserve1;
		}else{
			avaxReserve = reserve1;
			usdtReserve = reserve0;
		}
		price = usdtReserve * 1e30 / avaxReserve;
	}

	function getReserves(address pair) internal view returns(uint veeReserve,uint otherReserve){
		(uint reserve0,uint reserve1,) = IPangolinPair(pair).getReserves();
		if(pair == veeusdtPair){
			if(vee < usdt){
				veeReserve = reserve0;
				otherReserve = reserve1;
			}else{
				veeReserve = reserve1;
				otherReserve = reserve0;
			}
		}
		if(pair == veeavaxPair){
			if(vee < wavax){
				veeReserve = reserve0;
				otherReserve = reserve1;
			}else{
				veeReserve = reserve1;
				otherReserve = reserve0;
			}
		}
	}

	

}