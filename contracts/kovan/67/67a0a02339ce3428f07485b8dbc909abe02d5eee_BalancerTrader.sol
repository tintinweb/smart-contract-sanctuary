// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "SafeMath.sol";



interface PoolInterface {
    function getNumTokens() external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function totalSupply() external view returns (uint);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns (uint poolAmountOut);
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
    function calcPoolOutGivenSingleIn(
    uint tokenBalanceIn,
    uint tokenWeightIn,
    uint poolSupply,
    uint totalWeight,
    uint tokenAmountIn,
    uint swapFee
) external pure returns (uint poolAmountOut);
    function calcSingleOutGivenPoolIn(
    uint tokenBalanceOut,
    uint tokenWeightOut,
    uint poolSupply,
    uint totalWeight,
    uint poolAmountIn,
    uint swapFee
) external pure returns (uint tokenAmountOut);
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

contract BalancerTrader {
    using SafeMath for uint256;

    PoolInterface public bPoolSTBL;
    PoolInterface public bPoolETHDAI;
    TokenInterface public daiToken;
    TokenInterface public weth;
    TokenInterface public BPT;
    address liquidity;

    constructor() {
        bPoolSTBL = PoolInterface(0x208A560D57e25c74b4052c9baD253BBaF507f126); // I tried different test-pool versions but none seemed to work while using payETH/payDAI
        bPoolETHDAI = PoolInterface(0xB7402204753DD10FBfc74cF4Ee6FCA05017B716D);
        daiToken = TokenInterface(0x1528F3FCc26d13F7079325Fb78D9442607781c8C);
        weth = TokenInterface(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
        BPT = TokenInterface(0x208A560D57e25c74b4052c9baD253BBaF507f126);
        liquidity = address(0xb116Fe64202cF18eBf5345D8B6C0B60a19Dc253E);
    }

    function payETH() public payable returns (uint256){ // SOME WEIRD ERROR
        require(msg.value > 0, "No ETH sent!");
        uint256 ethToDaiAmount = ethToDaiSpotPrice().mul(msg.value).mul(97).div(100);
        _swapEthForDai(ethToDaiAmount);
        uint256 poolTokensOut = _swapDaiForBPT(ethToDaiAmount);
        uint256 rate = 1;
        BPT.transfer(liquidity, poolTokensOut);

        return poolTokensOut.mul(rate);
      }

    function payDAI(uint paymentAmountInDai) public returns (uint256){
        require(daiToken.transferFrom(msg.sender, address(this), paymentAmountInDai)); // Dai needs to be approved for the contract beforehand
        uint256 poolTokensOut = _swapDaiForBPT(paymentAmountInDai);
        uint256 rate = 1;
        BPT.transfer(liquidity, poolTokensOut);

        return poolTokensOut.mul(rate);
    }

    function _swapEthForDai(uint daiAmount) private {
    _wrapEth(); // wrap ETH and approve to balancer pool

    PoolInterface(bPoolETHDAI).swapExactAmountOut(
        address(weth),
        type(uint).max, // maxAmountIn, set to max -> use all sent ETH
        address(daiToken),
        daiAmount,
        type(uint).max // maxPrice, set to max -> accept any swap prices
    );

    require(daiToken.transfer(msg.sender, daiToken.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        _refundLeftoverEth();
    }

    function ethToDaiSpotPrice() public view returns (uint256){
      return bPoolETHDAI.getSpotPrice(address(weth), address(daiToken));
    }

    function _swapDaiForBPT(uint256 daiAmount) private returns (uint256){
      uint256 calcPoolAmountOut;
      uint256 minPoolAmountOut;
      uint256 PoolAmountOut;
      calcPoolAmountOut = PoolInterface(bPoolSTBL).calcPoolOutGivenSingleIn(
        PoolInterface(bPoolSTBL).getBalance(address(daiToken)),  // DAI in pool
        PoolInterface(bPoolSTBL).getDenormalizedWeight(address(daiToken)),  // Weight of DAI in pool
        PoolInterface(bPoolSTBL).totalSupply(), // Pool supply
        PoolInterface(bPoolSTBL).getTotalDenormalizedWeight(), // Total weight
        daiAmount, // Amount of DAI to be pooled
        PoolInterface(bPoolSTBL).getSwapFee() // Swap fee
      );
      minPoolAmountOut = calcPoolAmountOut.mul(97).div(100); // 3% slippage
      PoolAmountOut = PoolInterface(bPoolSTBL).joinswapExternAmountIn(address(daiToken), daiAmount, minPoolAmountOut);
      return PoolAmountOut;
    }

    function _wrapEth() private {
        weth.deposit{ value: msg.value }();

    if (weth.allowance(address(this), address(bPoolETHDAI)) < msg.value) {
        weth.approve(address(bPoolETHDAI), type(uint).max); // MUST APPROVE ALL TOKENS, USE uINT_MAX FOR UNLIMITED
    }

    }

    function _refundLeftoverEth() private {
        uint wethBalance = weth.balanceOf(address(this));

        if (wethBalance > 0) {
            // refund leftover ETH
            weth.withdraw(wethBalance);
            (bool success,) = msg.sender.call{ value: wethBalance }("");
            require(success, "ERR_ETH_FAILED");
        }
    }

    receive() external payable {}
}