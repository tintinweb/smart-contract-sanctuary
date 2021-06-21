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

contract BalancerTrader is Ownable {
    using SafeMath for uint256;

    BFactory bPool;
    PoolInterface bPoolSTBL;
    TokenInterface BPT;
    address[] internal poolTokens;
    mapping(address => TokenInterface) internal poolToken;

    uint256 decimals = 10e18;

    constructor() {
      bPool = BFactory(0x8f7F78080219d4066A8036ccD30D588B416a40DB); ////0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
      poolTokens = [
        0x8b1c886a6468cfA53C46F3c925e242F199fD6894,
        0x85D6a6B844092cB260406d30878b5c97362897d7,
        0x32e5F12F6faf242b4098E5621AF4E80a3C197DCb,
        0xb7a4F3E9097C08dA09517b5aB877F7a917224ede

            /*
          addr1,
          addr2,
          addr3,
          addr4,
          addr5,
          */
        ];
        for (uint256 s = 0; s < poolTokens.length; s += 1){
          poolToken[poolTokens[s]] = TokenInterface(poolTokens[s]);
        }
        pushBPTAddress(0x04c4e4770868CE87e7e434228e804c794F217Bc2);
    }

    function pushBPTAddress(address _BPT) public onlyOwner {
      require(bPool.isBPool(_BPT), "Address is not a Balancer pool!");
      BPT = TokenInterface(_BPT);
      bPoolSTBL = PoolInterface(_BPT);
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
      poolToken[_token].approve(address(BPT), _amount);
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