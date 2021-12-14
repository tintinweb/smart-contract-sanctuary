/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract wethContract{
     function balanceOf(address account) external view returns (uint256);
}
contract usdcContract{
     function balanceOf(address account) external view returns (uint256);
}
contract quickSwapContract{
    using SafeMath for uint;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

contract swap {
    using SafeMath for uint;
    address public owner;
    address weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; 

    address weth_usdc_quickSwap = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
    address quickSwap = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address weth_usdc_sushi =  0xcd353F79d9FADe311fC3119B841e1f456b54e858; 
    address sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    wethContract wethcontract_ = wethContract(weth);
    usdcContract usdcContract_ = usdcContract(usdc);
    quickSwapContract quickSwapContract_ = quickSwapContract(quickSwap);
    // sushiSwapContract sushiSwapContract_ = sushiSwapContract(sushiRouter);

    constructor() public {
        owner = msg.sender;
}

    function wethAmountInQuickSwap() public view returns(uint256){
        return wethcontract_.balanceOf(weth_usdc_quickSwap);
    }
    function usdcAmountInQuickSwap() public view returns(uint256){
        return usdcContract_.balanceOf(weth_usdc_quickSwap);
    }
    function wethAmountInSushiSwap() public view returns(uint256){
        return wethcontract_.balanceOf(weth_usdc_sushi);
    }
    function usdcAmountInSushiSwap() public view returns(uint256){
        return usdcContract_.balanceOf(weth_usdc_sushi);
    }




    function EthToQuick(uint256 EthAmount) public view returns(uint256){
        uint256 EthIn = EthAmount.mul(1*(10**18));
        return UsdcToEthBySushi(EthToUsdcByQuick(EthIn));
    }
    function EthToUsdcByQuick(uint256 eth) public view returns(uint256){
        return quickSwapContract_.getAmountOut(eth, wethAmountInQuickSwap(),usdcAmountInQuickSwap());
    }
    function UsdcToEthBySushi(uint256 UsdcIn) public view returns(uint256){
        return quickSwapContract_.getAmountOut(UsdcIn,usdcAmountInQuickSwap(),wethAmountInQuickSwap());
    }



    function EthToSushi(uint256 EthAmount) public view returns(uint256){
        uint256 EthIn = EthAmount.mul(1*(10**18));
        return UsdcToEthByQuick(EthToUsdcBySushi(EthIn));
    }
    function EthToUsdcBySushi(uint256 eth) public view returns(uint256){
        return quickSwapContract_.getAmountOut(eth, wethAmountInSushiSwap(),usdcAmountInSushiSwap());
    }
    function UsdcToEthByQuick(uint256 UsdcIn) public view returns(uint256){
        return quickSwapContract_.getAmountOut(UsdcIn, usdcAmountInSushiSwap(),wethAmountInSushiSwap());
    }


    function withdrawETH(uint256 ethWei) public {
        msg.sender.transfer(ethWei);
    }
    
    
}