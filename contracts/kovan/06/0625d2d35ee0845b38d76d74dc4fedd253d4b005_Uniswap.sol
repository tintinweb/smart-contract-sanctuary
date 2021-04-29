/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.0;


interface ERC20Interface {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface UniswapInterface {
    function factory() external pure returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

contract Uniswap {
    UniswapInterface public constant uniswapRouter = UniswapInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function liquidity(address tokenA, address tokenB, uint _amountADesired, uint _amountBDesired) public {
        ERC20Interface _tokenContractA = ERC20Interface(tokenA);
        ERC20Interface _tokenContractB = ERC20Interface(tokenB);
        require(_tokenContractA.approve(address(uniswapRouter), _amountADesired), 'approve failed.');
        require(_tokenContractB.approve(address(uniswapRouter), _amountBDesired), 'approve failed.');
        require(_tokenContractA.transferFrom(msg.sender, address(this), _amountADesired), 'transferFrom-failed.');
        require(_tokenContractB.transferFrom(msg.sender, address(this), _amountBDesired), 'transferFrom-failed.');
        uniswapRouter.addLiquidity(tokenA, tokenB, _amountADesired, _amountBDesired, 0, 0, msg.sender, block.timestamp);
    }
        
    function removeLiquidity(address tokenA, address tokenB, uint _liquidity) public {
        address _liquidityaddress = uniswapRouter.getPair(tokenA, tokenB);
        ERC20Interface _liquidityContract = ERC20Interface(_liquidityaddress);
        require(_liquidityContract.approve(address(uniswapRouter), _liquidity), 'approve failed.');
        require(_liquidityContract.transferFrom(msg.sender, address(this), _liquidity), 'transferFrom-failed.');
        uniswapRouter.removeLiquidity(tokenA, tokenB, _liquidity, 0, 0, msg.sender, block.timestamp);
    }
    
}