// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "SafeMath.sol";
import "ERC20.sol";

interface BFactory {

    function isBPool(address b) external view returns (bool);
    function newBPool() external returns (PoolInterface);

}

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

function setSwapFee(uint swapFee) external;
function setController(address manager) external;
function setPublicSwap(bool public_) external;
function finalize() external;
function bind(address token, uint balance, uint denorm) external;
function rebind(address token, uint balance, uint denorm) external;
function unbind(address token) external;
function gulp(address token) external;
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
contract TokenContract is ERC20 {
  constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
    _mint(msg.sender, 10e22);
}
}

contract BalancerTrader {
    using SafeMath for uint256;
/*
    PoolInterface public bPoolSTBL;
    PoolInterface public bPoolETHDAI;
    TokenInterface public daiToken;
    TokenInterface public weth;
    TokenInterface public BPT;
    */
    BFactory bPool = BFactory(address(0x8f7F78080219d4066A8036ccD30D588B416a40DB));
    PoolInterface bPoolSTBL;
    TokenInterface BPT;
    address factory;
    address liquidity;
    TokenInterface poolToken1;
    TokenInterface poolToken2;
    TokenInterface poolToken3;

    uint256 decimals = 10e18;

    constructor() {
      /*
        bPoolSTBL = PoolInterface(0x208A560D57e25c74b4052c9baD253BBaF507f126); // I tried different test-pool versions but none seemed to work while using payETH/payDAI
        bPoolETHDAI = PoolInterface(0xB7402204753DD10FBfc74cF4Ee6FCA05017B716D);
        daiToken = TokenInterface(0x1528F3FCc26d13F7079325Fb78D9442607781c8C);
        weth = TokenInterface(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
        BPT = TokenInterface(0x208A560D57e25c74b4052c9baD253BBaF507f126);
        liquidity = address(0xb116Fe64202cF18eBf5345D8B6C0B60a19Dc253E);
        */
        poolToken1 = TokenInterface(address(new TokenContract("poolToken1", "PT1")));
        poolToken2 = TokenInterface(address(new TokenContract("poolToken2", "PT2")));
        poolToken3 = TokenInterface(address(new TokenContract("poolToken3", "PT3")));
    }

    function deployBalancerPool(uint256 _swapFee) public {
      bPoolSTBL = bPool.newBPool();
      bPoolSTBL.setSwapFee(_swapFee);
      bPoolSTBL.bind(address(poolToken1), decimals.mul(100), decimals);
      bPoolSTBL.bind(address(poolToken2), decimals.mul(100), decimals);
      bPoolSTBL.bind(address(poolToken3), decimals.mul(100), decimals);
      bPoolSTBL.finalize();
    }

    function _swapPTForBPT(address _token, uint256 _amount) private returns (uint256){
      uint256 calcPoolAmountOut;
      uint256 minPoolAmountOut;
      uint256 PoolAmountOut;
      calcPoolAmountOut = PoolInterface(bPoolSTBL).calcPoolOutGivenSingleIn(
        PoolInterface(bPoolSTBL).getBalance(address(_token)),  // Token amount in pool
        PoolInterface(bPoolSTBL).getDenormalizedWeight(address(_token)),  // Weight of DAI in pool
        PoolInterface(bPoolSTBL).totalSupply(), // Pool supply
        PoolInterface(bPoolSTBL).getTotalDenormalizedWeight(), // T_tokenotal weight
        _amount, // Amount of tokens to be pooled
        PoolInterface(bPoolSTBL).getSwapFee() // Swap fee
      );
      minPoolAmountOut = calcPoolAmountOut.mul(80).div(100); // 20% slippage
      PoolAmountOut = PoolInterface(bPoolSTBL).joinswapExternAmountIn(address(_token), _amount, minPoolAmountOut);
      return PoolAmountOut;
    }

    function balanceOfToken(address _token) public returns (uint256 balance) {
        TokenInterface token = TokenInterface(_token);
        balance = token.balanceOf(_token);
    }
/*
    function payETH() public payable returns (uint256){ // SOME WEIRD ERROR
        require(msg.value > 0, "No ETH sent!");
        uint256 ethToDaiAmount = ethToDaiSpotPrice().mul(msg.value).mul(80).div(100);
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
      minPoolAmountOut = calcPoolAmountOut.mul(80).div(100); // 20% slippage
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
*/
    receive() external payable {}
}