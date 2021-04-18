/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

pragma solidity ^0.5.0;

interface IErc20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

interface IWETH {
    function withdraw(uint) external;
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function mint(address to) external returns (uint);
    function burn(address to) external returns (uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

interface IRouter {
    function factory() external returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract Arbitrager {

    address admin;
    address weth;
    mapping (address => bool) senders;

    constructor() public {
        admin = msg.sender;
	senders[msg.sender] = true;
	weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    function() external payable {}

    function setSender(address guy, bool b) public {
        require(msg.sender == admin);
	senders[guy] = b;
    }

    function setWETH(address _weth) public {
        require(msg.sender == admin);
	weth = _weth;
    }


    function _swapOnRouter(IRouter router, address token, uint amountIn) internal {
    	address[] memory path = new address[](2);
	path[0] = weth;
	path[1] = token;
	router.swapExactETHForTokensSupportingFeeOnTransferTokens.value(amountIn)(1, path, address(this), 1e11);
    }

    function _addLiquidity(IRouter router, address token, uint ethAmount, uint tokenAmount) internal {
	_approve(token, address(router));
	router.addLiquidityETH.value(ethAmount)(token, tokenAmount, 1, 1, address(this), 1e11);
    }

    function _swapAndAddLiquidity(IRouter router, address token, uint amount) internal {
    	uint256 input = amount / 2;
	_swapOnRouter(router, token, input);

	input = amount - input;
	_addLiquidity(router, token, input, IErc20(token).balanceOf(address(this)));
    }

    function swapAndAddLiquidity(IRouter router, address token) public payable {
        require(senders[msg.sender]);
	require(IErc20(token).balanceOf(address(router)) > 0);
	_swapAndAddLiquidity(router, token, msg.value);
    }


    function _calUniswapV2Out(
          uint reserve0,
          uint reserve1,
          uint256 amount
      ) internal pure returns(uint256 result) {
          uint256 amountInWithFee = amount * 997;
          uint256 numerator = amountInWithFee * reserve1;
          uint256 denominator = reserve0 * 1000 + amountInWithFee;
          result = (denominator == 0) ? 0 : numerator / denominator;
    }

    function _approve(address token, address spender) internal {
        if (IErc20(token).allowance(address(this), spender) == 0) {
	    IErc20(token).approve(spender, uint(-1));
	}
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
	  (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
          pair = address(uint(keccak256(abi.encodePacked(
                  hex'ff',
                  factory,
                  keccak256(abi.encodePacked(token0, token1)),
                  hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
              ))));
    }
}