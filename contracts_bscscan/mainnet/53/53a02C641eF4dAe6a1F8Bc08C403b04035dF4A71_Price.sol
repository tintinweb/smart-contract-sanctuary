/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IPancakeswapRouter {
  function WETH (  ) external view returns ( address );
  function addLiquidity ( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB, uint256 liquidity );
  function addLiquidityETH ( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH, uint256 liquidity );
  function factory (  ) external view returns ( address );
  function getAmountIn ( uint256 amountOut, uint256 reserveIn, uint256 reserveOut ) external pure returns ( uint256 amountIn );
  function getAmountOut ( uint256 amountIn, uint256 reserveIn, uint256 reserveOut ) external pure returns ( uint256 amountOut );
  function quote ( uint256 amountA, uint256 reserveA, uint256 reserveB ) external pure returns ( uint256 amountB );
  function removeLiquidity ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline ) external returns ( uint256 amountA, uint256 amountB );
  function removeLiquidityETH ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountToken, uint256 amountETH );
  function removeLiquidityETHSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountETH );
  function removeLiquidityETHWithPermit ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountToken, uint256 amountETH );
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens ( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountETH );
  function removeLiquidityWithPermit ( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns ( uint256 amountA, uint256 amountB );
}

interface IPancakeswapFactory {
  function INIT_CODE_PAIR_HASH (  ) external view returns ( bytes32 );
  function allPairs ( uint256 ) external view returns ( address );
  function allPairsLength (  ) external view returns ( uint256 );
  function createPair ( address tokenA, address tokenB ) external returns ( address pair );
  function feeTo (  ) external view returns ( address );
  function feeToSetter (  ) external view returns ( address );
  function getPair ( address, address ) external view returns ( address );
  function setFeeTo ( address _feeTo ) external;
  function setFeeToSetter ( address _feeToSetter ) external;
}

interface IPancakeLPToken {
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function MINIMUM_LIQUIDITY (  ) external view returns ( uint256 );
  function PERMIT_TYPEHASH (  ) external view returns ( bytes32 );
  function allowance ( address, address ) external view returns ( uint256 );
  function approve ( address spender, uint256 value ) external returns ( bool );
  function balanceOf ( address ) external view returns ( uint256 );
  function burn ( address to ) external returns ( uint256 amount0, uint256 amount1 );
  function decimals (  ) external view returns ( uint8 );
  function factory (  ) external view returns ( address );
  function getReserves (  ) external view returns ( uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast );
  function initialize ( address _token0, address _token1 ) external;
  function kLast (  ) external view returns ( uint256 );
  function mint ( address to ) external returns ( uint256 liquidity );
  function nonces ( address ) external view returns ( uint256 );
  function permit ( address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external;
  function price0CumulativeLast (  ) external view returns ( uint256 );
  function price1CumulativeLast (  ) external view returns ( uint256 );
  function skim ( address to ) external;
  function sync (  ) external;
  function token0 (  ) external view returns ( address );
  function token1 (  ) external view returns ( address );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 value ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 value ) external returns ( bool );
}

interface IKingDeFiFarm {
    
  function changeFee ( uint256 _pid, uint16 _fee ) external;
  function changeLastBlock ( uint256 _lastBlock ) external;
  function changePoolKrwReward ( uint256 _pid, uint256 _krwPerBlock ) external;
  function changeVault ( uint256 _pid, address _vault, bool _isVaultContract ) external;
  function claim ( uint256 _pid ) external;
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function emergencyWithdraw ( uint256 _pid ) external;
  function getDeposit ( uint256 _pid, address account ) external view returns ( uint256 );
  function getFee ( uint256 _pid ) external view returns ( uint256 );
  function getKrwPerBlock ( uint256 _pid ) external view returns ( uint256 );
  function getPending ( uint256 _pid, address account ) external view returns ( uint256 );
  function getTotalSupply ( uint256 _pid ) external view returns ( uint256 );
  function krw (  ) external view returns ( address );
  function lastBlock (  ) external view returns ( uint256 );
  function massUpdatePools (  ) external;
  function massUpdatePoolsInRange ( uint256 startPool, uint256 endPool ) external;
  function owner (  ) external view returns ( address );
  function pause (  ) external;
  function pausePool ( uint256 _pid ) external;
  function paused (  ) external view returns ( bool );
  function pausedPool ( uint256 ) external view returns ( bool );
  function pausedUpdatePools (  ) external view returns ( bool );
  function poolInfo ( uint256 ) external view returns ( address lpToken, string memory symbol, uint16 fee, address vault, bool isVaultContract, uint256 totalSupply, uint256 krwPerBlock, uint256 lastRewardBlock, uint256 rewardsPerShare );
  function poolLength (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function tokenAlreadyInPool ( address ) external view returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function unpausePool ( uint256 _pid ) external;
  function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardMinus );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
  function withdrawAll ( uint256 _pid ) external;
}

interface Getter {
  function farm (  ) external view returns ( address );
  function getBlock (  ) external view returns ( uint256 );
  function getFee ( uint256 _pid ) external view returns ( uint256 );
  function getFirstPerBlock ( uint256 _pid ) external view returns ( uint256 );
  function getSecondPerBlock ( uint256 _pid ) external view returns ( uint256 );
  function getTotalSupply ( uint256 _pid ) external view returns ( uint256 );
}


contract Price{
    IPancakeswapFactory factory = IPancakeswapFactory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73));
    IPancakeswapRouter router = IPancakeswapRouter(address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F));
    IPancakeLPToken lpToken = IPancakeLPToken(address(0xF9592f45cA4975a6672EDE24f10655F320AFCB32));
    IKingDeFiFarm kingDeFiFarm = IKingDeFiFarm(address(0xfddadE65Bf769E1Cd4f7Ef40Fc767175DcaF93c8));
    Getter getter = Getter(address(0xc013A1842a1C4385535FF313813496F9a331CE51));
    
    function prezzoKrown() view public returns(uint256){
        (uint112 reserveLP0, uint112 reserveLP1, ) = lpToken.getReserves();
        uint256 prezzoToken = router.quote(1000000000000000000, reserveLP0, reserveLP1);
        return prezzoToken;
    }
    
    function reverseToken0(uint256 _pid) view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        (uint112 reserveLP0, , ) = tokenLP.getReserves();
        uint256 quantity = (10 * reserveLP0) / tokenLP.totalSupply();
        return quantity;
    }
    
    function price(uint256 _pid) view public returns (uint256) {
        return (reverseToken0(_pid) * prezzoKrown() / 10) * 2;
    }
}