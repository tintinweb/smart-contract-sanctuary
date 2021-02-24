/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity ^0.6.6;

interface IPancakeRouter01 {
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

contract Swap{

	address payable owner;
	//address internal constant PANCAKE_ROUTER = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
	address internal constant PANCAKE_ROUTER = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a; //Uniswap on Ropsten
	
	IPancakeRouter01 public pancakeswapRouter;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public{
		owner = msg.sender;
		pancakeswapRouter = IPancakeRouter01(PANCAKE_ROUTER);
    }

   function swapBNBForTokenPancakeswap (uint bnbAmount, address tokenAddress) public onlyOwner{
		// Verify we have enough funds
		require(bnbAmount <= address(this).balance, "Not enough BNB in contract to perform swap.");

		// Build arguments for uniswap router call
		address[] memory path = new address[](2);
		path[0] = pancakeswapRouter.WETH();
		path[1] = tokenAddress;

		// Make the call and give it 15 seconds
		// Set amountOutMin to 0 but no success with larger amounts either
		pancakeswapRouter.swapExactETHForTokens.value(bnbAmount)(0, path, address(this), now + 15);	
	}
	
	function depositBnb() external payable {
	}
	
	function withdrawBnb() external onlyOwner{
		owner.transfer(address(this).balance);
	}	
}