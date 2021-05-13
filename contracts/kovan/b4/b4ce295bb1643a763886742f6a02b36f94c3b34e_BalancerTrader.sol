// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "SafeMath.sol";
import "ERC20.sol";
import "Ownable.sol";

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
    function isFinalized() external view returns (bool);

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
    _mint(msg.sender, 1000*10e18);
    _mint(0xc49398Fd8b7ECC7bdA74870A9A33D23E07258630, 100*10e18);
}
}

contract BalancerTrader is Ownable {
    using SafeMath for uint256;
/*
    PoolInterface public bPoolSTBL;
    PoolInterface public bPoolETHDAI;
    TokenInterface public daiToken;
    TokenInterface public weth;
    TokenInterface public BPT;
    */
    address bFactory = address(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);
    BFactory bPool = BFactory(bFactory);
    PoolInterface bPoolSTBL;
    TokenInterface BPT;
    address[] internal poolTokens;
    mapping(address => TokenInterface) internal poolToken;

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

        poolTokens = [
            /*
          addr1,
          addr2,
          addr3,
          addr4,
          addr5,
          addr6,
          addr7,
          addr9
          */
          address(new TokenContract("poolToken1", "PT1")),
          address(new TokenContract("poolToken2", "PT2")),
          address(new TokenContract("poolToken3", "PT3"))
        ];
        for (uint256 s = 0; s < poolTokens.length; s += 1){
          poolToken[poolTokens[s]] = TokenInterface(poolTokens[s]);
        }
    }

    function createBalancerPool() public onlyOwner {
      require(deployBalancerPool(10**12), "Deployment failure!"); // Pass swapFee as argument
      require(approveTokensForPool(), "Approve failure!");
      require(bindTokensToPool(), "Bind failure!");
      require(finalizePool(), "Finalization failure!");
    }

    function pushBPTAddress(address _BPT) public onlyOwner {
      BPT = TokenInterface(_BPT);
    }

    function deployBalancerPool(uint256 _swapFee) internal returns (bool success){
      bPoolSTBL = bPool.newBPool();
      bPoolSTBL.setSwapFee(_swapFee);
      success = true;
    }

    function approveTokensForPool() internal returns (bool success){
      for (uint256 s = 0; s < poolTokens.length; s += 1){
        poolToken[poolTokens[s]].approve(address(bPoolSTBL), poolToken[poolTokens[s]].balanceOf(address(this)));
      }
      success = true;
    }

    function bindTokensToPool() internal returns (bool success){
      for (uint256 s = 0; s < poolTokens.length; s += 1){
        bPoolSTBL.bind(poolTokens[s], poolToken[poolTokens[s]].balanceOf(address(this)), decimals);
      }
      success = true;
    }

    function finalizePool() internal returns (bool success){
      bPoolSTBL.finalize();
      success = true;
    }

    function isFinalized() public view returns (bool finalized) {
      finalized = bPoolSTBL.isFinalized();
    }

    function isPoolToken(address _token)
    public
    view
    returns(bool)
    {
      for (uint256 s = 0; s < poolTokens.length; s += 1){
        if (_token == poolTokens[s]) return (true);
      }
      return (false);
    }

    function swapExactPoolTokenForBPT(address _user, address _token, uint256 _amount, uint256 _slippagePercentage) public returns (uint256){
      uint256 calcPoolAmountOut;
      uint256 minPoolAmountOut;
      uint256 poolAmountOut;
      require(bPoolSTBL.isFinalized(), "Pool not finalized!");
      require(poolToken[_token].transferFrom(_user, address(this), _amount), "Token transfer failure");
      calcPoolAmountOut = bPoolSTBL.calcPoolOutGivenSingleIn(
        bPoolSTBL.getBalance(address(_token)),  // Token amount in pool
        bPoolSTBL.getDenormalizedWeight(address(_token)),  // Weight of token in pool
        bPoolSTBL.totalSupply(), // Pool supply
        bPoolSTBL.getTotalDenormalizedWeight(), // Total weight
        _amount, // Amount of tokens to be pooled
        bPoolSTBL.getSwapFee() // Swap fee
      );
      minPoolAmountOut = calcPoolAmountOut.sub(calcPoolAmountOut.mul(_slippagePercentage).div(100)); // Account for slippage
      poolAmountOut = bPoolSTBL.joinswapExternAmountIn(_token, _amount, minPoolAmountOut);
      require(BPT.transfer(msg.sender, poolAmountOut), "Balancer liquidity token transfer failure!");
      return poolAmountOut;
    }

    function swapExactBPTForPoolToken(address _user, address _tokenOut, uint256 _BPTAmountIn, uint256 _slippagePercentage) public returns (uint256){
      uint256 calcTokenAmountOut;
      uint256 minTokenAmountOut;
      uint256 tokenAmountOut;
      require(bPoolSTBL.isFinalized(), "Pool not finalized!");
      require(BPT.transferFrom(msg.sender, address(this), _BPTAmountIn));
      calcTokenAmountOut = bPoolSTBL.calcSingleOutGivenPoolIn(
        bPoolSTBL.getBalance(address(_tokenOut)),
        bPoolSTBL.getDenormalizedWeight(address(_tokenOut)),
        bPoolSTBL.totalSupply(),
        bPoolSTBL.getTotalDenormalizedWeight(),
        _BPTAmountIn,
        bPoolSTBL.getSwapFee()
      );
      minTokenAmountOut = calcTokenAmountOut.sub(calcTokenAmountOut.mul(_slippagePercentage).div(100)); // Account for slippage
      tokenAmountOut = bPoolSTBL.exitswapPoolAmountIn(_tokenOut, _BPTAmountIn, minTokenAmountOut);
      require(poolToken[_tokenOut].transfer(_user, tokenAmountOut), "Token transfer failure!");
      return tokenAmountOut;
    }

    receive() external payable {}
}