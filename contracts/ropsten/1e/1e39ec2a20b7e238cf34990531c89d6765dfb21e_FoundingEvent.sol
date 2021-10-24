/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.6.6;
// author: SamPorter1984
interface I{
	function getPair(address t, address t1) external view returns(address pair);
	function createPair(address t, address t1) external returns(address pair);
	function genesis(uint Ftm,address pair,uint gen) external;
	function transfer(address to, uint value) external returns(bool);
	function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline)external payable returns(uint amountToken,uint amountETH,uint liquidity);
	function deposit() external payable;
	function mint(address to) external returns (uint liquidity);
	function balanceOf(address owner) external view returns (uint);
//  function approve(address spender, uint256 amount) external returns (bool);
}



contract FoundingEvent {
	address private _letToken;

	constructor() public {_letToken=0x15D2fb015f8895f35Abd702be852a9Eb23c16E2F;}
	function deposit() external payable {}

	function createLiquidity() public {
		address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
		address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address pair = I(factory).getPair(_letToken,WETH); if (pair == address(0)) {pair=I(factory).createPair(_letToken, WETH);}
		pair = pairFor(factory, _letToken, WETH);
        //I(router).safeTransferFrom(_letToken, address(this), pair, 1e23);
        (bool success, bytes memory data) = _letToken.call(abi.encodeWithSelector(0x23b872dd, address(this), pair, I(_letToken).balanceOf(address(this))));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        I(WETH).deposit{value: address(this).balance}();
        assert(I(WETH).transfer(pair, address(this).balance));
        uint liquidity = I(pair).mint(msg.sender);
		//I(_letToken).approve(address(router), 1e23);//careful, if token contract does not have hardcoded allowance for the router you need this line
		//I(router).addLiquidityETH{value: address(this).balance}(_letToken,1e23,0,0,staking,2**256-1);//this might still fail like with other idos
	}

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        ))));
    }
}