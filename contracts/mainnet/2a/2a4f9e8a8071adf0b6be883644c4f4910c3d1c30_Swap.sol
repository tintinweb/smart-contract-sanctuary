/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IUniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(
        uint amountIn, 
        address[] memory path
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
    
    function approve(
        address spender, 
        uint256 amount
    ) external returns (bool);
    
    function balanceOf(
        address account
    ) external view returns (uint256);
}

contract Swap {
    address owner;
    mapping(address => bool) private whitelistedMap;

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    IUniswap public uniswapRouter;
    
    event Swap(address indexed account, address[] indexed path, uint amountIn, uint amountOut);

    // MODIFIERS
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onWhiteList {
        require(whitelistedMap[msg.sender]);
        _;
    }

    constructor() {
        uniswapRouter = IUniswap(UNISWAP_ROUTER_ADDRESS);
        owner = msg.sender;
        setAddress(owner,true);
    }

    function setAddress(address _address,bool flag) public onlyOwner {
        whitelistedMap[_address] = flag;
    }
    // WITHDRAW
    function withdrawToken(address to,address token) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) > 0);
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }

    // GET BALANCE
    function getTokenBalance(address token) public view onWhiteList returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }

    // SWAP
    function tradeIn(
        uint amountIn,uint amountMinOut,
        address[] calldata path
    ) external onWhiteList {
        uint256 amount=getTokenBalance(path[0]);//token balance
        if(amount>=amountIn){
            uint256[] memory amounts = getAmountOut(amountIn, path);
            if(amounts[amounts.length - 1]>=amountMinOut){
                IERC20(path[0]).approve(address(uniswapRouter), amountIn);
                uniswapRouter.swapExactTokensForTokens(
                amountIn,
                amountMinOut,
                path,
                address(this),
                block.timestamp + 60*30
                );
            }
            emit Swap(msg.sender, path, amountIn, amounts[amounts.length - 1]);
        }
        

    }
    function tradeOut(
        address[] calldata path,uint amountMinOut
    ) external onWhiteList {
        uint256 amount=getTokenBalance(path[0]);//token balance
        
        if(amount>0){
            uint256[] memory amounts = getAmountOut(amount, path);
            if(amounts[amounts.length - 1]>=amountMinOut){
                IERC20(path[0]).approve(address(uniswapRouter), amount);
                uniswapRouter.swapExactTokensForTokens(
                amount,
                amountMinOut,
                path,
                address(this),
                block.timestamp + 60*30
                );
            }
            emit Swap(msg.sender, path, amount, amounts[amounts.length - 1]);
        }
        
    }
    
    
    // UTILS    
    function getAmountOut(uint amountIn, address[] memory path) private returns(uint256[] memory){
        return uniswapRouter.getAmountsOut(amountIn, path);
    }
}