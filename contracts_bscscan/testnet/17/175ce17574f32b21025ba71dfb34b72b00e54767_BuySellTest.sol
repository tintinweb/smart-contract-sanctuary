/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external pure returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BuySellTest is Ownable {
    address public _RouterAddress;
    address public _FactoryAddress;
    IUniswapV2Router public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    constructor() {
        // BSC MainNet
        //_RouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        //_FactoryAddress = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

        // BSC TestNet
        _RouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        _FactoryAddress = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;

        // Polygon Main
        //_RouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        //_FactoryAddress = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
 
        uniswapRouter = IUniswapV2Router(_RouterAddress);
        uniswapFactory = IUniswapV2Factory(_FactoryAddress);
    }

    function setRouter(address newAddress) external onlyOwner() {
        _RouterAddress = newAddress;
        uniswapRouter = IUniswapV2Router(_RouterAddress);
    }

    function setFactory(address newAddress) external onlyOwner() {
        _FactoryAddress = newAddress;
        uniswapFactory = IUniswapV2Factory(_FactoryAddress);
    }

    function safeBuyToken(address token, uint256 slippage, uint testBuyAmount) public payable {
        //uint deadline = block.timestamp;
        uint256 buyAmount = address(this).balance - testBuyAmount;

        // Actual Buy
        uint256 minAmount = getQuote(token, buyAmount) * slippage / 100;
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: buyAmount }(minAmount, getPathForETHtoToken(token), _msgSender(), block.timestamp);


        //uint testAmount = 20000000000000000;
        
        // Test Buy
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: testBuyAmount }(1, getPathForETHtoToken(token), address(this), block.timestamp);
        uint initialbalance = IERC20(token).balanceOf(address(this));

        // Simple Approval Test
        IERC20 tkn = IERC20(token);
        tkn.approve(address(_RouterAddress), type(uint256).max);
        require(tkn.allowance(address(this), address(_RouterAddress)) == type(uint256).max, "allowance not working");

        // Sell Tokens back to Pancake Swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            initialbalance,
            0, // accept any amount of ETH
            getPathForTokentoETH(token),
            address(this),
            block.timestamp
        );

        

        // refund leftover ETH to user
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "refund failed");
    }


    function safeBuyTokenOld(address token) public payable {
        uint testAmount = 1000000;
        uint deadline = block.timestamp + 10;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: testAmount }(1, getPathForETHtoToken(token), address(this), deadline);
        uint testBalance = IERC20(token).balanceOf(address(this));

        // Simple Approval Test
        IERC20 tkn = IERC20(token);
        tkn.approve(address(_RouterAddress), type(uint256).max);
        require(tkn.allowance(address(this), address(_RouterAddress)) == type(uint256).max, "allowance not working");

        // Simulate Sell Test, Send
        address toSend = uniswapFactory.getPair(token, uniswapRouter.WETH());
        tkn.transfer(address(toSend), testBalance);

        // Verify transferred balances
        uint balanceAfter = tkn.balanceOf(address(this));
        require(balanceAfter < testBalance / 2, "unable to sell");

        // Real Purchase
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: address(this).balance }(1, getPathForETHtoToken(token), _msgSender(), deadline);

        // refund leftover ETH to user, why? idk
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "refund failed");
    }


    function safeBuyTokenWithSlippageOld(address token, uint256 slippage) public payable {
        uint testAmount = 1000000;
        uint deadline = block.timestamp + 10;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: testAmount }(1, getPathForETHtoToken(token), address(this), deadline);
        uint testBalance = IERC20(token).balanceOf(address(this));

        // Simple Approval Test
        IERC20 tkn = IERC20(token);
        tkn.approve(address(_RouterAddress), type(uint256).max);
        require(tkn.allowance(address(this), address(_RouterAddress)) == type(uint256).max, "allowance not working");

        // Simulate Sell Test, Send
        tkn.approve(address(this), type(uint256).max);
        address toSend = uniswapFactory.getPair(token, uniswapRouter.WETH());
        tkn.transferFrom(address(this), address(toSend), testBalance);

        uint256 minAmount = getQuote(token, address(this).balance) * slippage / 100;
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: address(this).balance }(minAmount, getPathForETHtoToken(token), _msgSender(), deadline);

        // refund leftover ETH to user
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "refund failed");
    }

    function getQuote(address token, uint256 ethAmount) public view returns (uint256) {
        return uniswapRouter.getAmountsOut(ethAmount, getPathForETHtoToken(token))[1];
    }

    function getPair(address token) public view returns (address) {
        address toSend = uniswapFactory.getPair(token, uniswapRouter.WETH());
        return toSend;
    }

    function getPathForETHtoToken(address token) public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;
        
        return path;
    }

    function getPathForTokentoETH(address token) public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        
        return path;
    }
    

    function getTokenBalance(address token) public view returns (uint) {
        IERC20 tkn = IERC20(token);
        
        uint balance = tkn.balanceOf(address(this));
        
        return balance;
    }

    function storeEth() public payable {}

    function recoverEth() onlyOwner() public {
        // refund leftover ETH to user
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "refund failed");
    }

    function recoverToken(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    receive() external payable {}
}