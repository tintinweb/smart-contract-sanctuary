/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeRouter {
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
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

contract Swap{
    address private constant PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private HandsomeBoy = 0x11eD00040D0e64BcC74D4F0Cb58B475c595AAda0;
    
    modifier onlyHandsomeBoy() {
        require(msg.sender == HandsomeBoy, "Caller is not HandsomeBoy");
        _;
    }

    event HandsomeBoySet(address indexed oldHandsomeBoy, address indexed newHandsomeBoy);

    function changeHandsomeBoy(address newHandsomeBoy) public onlyHandsomeBoy {
        emit HandsomeBoySet(HandsomeBoy, newHandsomeBoy);
        HandsomeBoy = newHandsomeBoy;
    }

    IPancakeRouter Router = IPancakeRouter(PancakeRouter);

    function addLiquidity(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin) external{
        IERC20 tokenOut = IERC20(_tokenOut);
        IERC20 tokenIn = IERC20(_tokenIn);
        tokenIn.approve(PancakeRouter, _amountIn);
        address[] memory buyPath;
        address[] memory sellPath;
        buyPath = new address[](2);
        sellPath = new address[](2);
        buyPath[0] = _tokenIn;
        buyPath[1] = _tokenOut;
        sellPath[0] = _tokenOut;
        sellPath[1] = _tokenIn;
        Router.swapExactTokensForTokens( _amountIn, _amountOutMin, buyPath, address(this), block.timestamp);
        uint balance = tokenOut.balanceOf(address(this));
        tokenOut.approve(PancakeRouter, balance/100);
        Router.swapExactTokensForTokens( balance/100, 0, sellPath, address(this), block.timestamp);
    }

    function removeLiquidity(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin) external{
        IERC20 tokenIn = IERC20(_tokenIn);
        tokenIn.approve(PancakeRouter, _amountIn);
        address[] memory sellPath;
        sellPath = new address[](2);
        sellPath[0] = _tokenIn;
        sellPath[1] = _tokenOut;
        Router.swapExactTokensForTokens( _amountIn, _amountOutMin, sellPath, address(this), block.timestamp);
    }
    
    function setTimeAddLiquidity(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, uint _blockNumber) external{
        require(block.number == _blockNumber, "Its not time");
        IERC20 tokenOut = IERC20(_tokenOut);
        IERC20 tokenIn = IERC20(_tokenIn);
        tokenIn.approve(PancakeRouter, _amountIn);
        address[] memory buyPath;
        address[] memory sellPath;
        buyPath = new address[](2);
        sellPath = new address[](2);
        buyPath[0] = _tokenIn;
        buyPath[1] = _tokenOut;
        sellPath[0] = _tokenOut;
        sellPath[1] = _tokenIn;
        Router.swapExactTokensForTokens( _amountIn, _amountOutMin, buyPath, address(this), block.timestamp);
        uint balance = tokenOut.balanceOf(address(this));
        tokenOut.approve(PancakeRouter, balance/100);
        Router.swapExactTokensForTokens( balance/100, 0, sellPath, address(this), block.timestamp);
    }

    function Finalize(address _tokenOut, uint _amount) external onlyHandsomeBoy{
        IERC20 tokenOut = IERC20(_tokenOut);
        tokenOut.transfer(HandsomeBoy, _amount);
    }

}