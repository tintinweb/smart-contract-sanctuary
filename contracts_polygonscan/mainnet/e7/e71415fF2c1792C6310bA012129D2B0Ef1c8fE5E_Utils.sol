/**
 *Submitted for verification at polygonscan.com on 2021-09-27
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


contract Utils{
    IPancakeswapFactory factory = IPancakeswapFactory(address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32));
    IPancakeswapRouter router = IPancakeswapRouter(address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff));
    IPancakeLPToken lpToken = IPancakeLPToken(address(0x6b2187b2E431bF0A7485a4F0963F42c1EE2B975F));
    IPancakeLPToken lpTokenFinal = IPancakeLPToken(address(0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827));
    IKingDeFiFarm kingDeFiFarm = IKingDeFiFarm(address(0x1DB4ADb2981865e0B63DED83bBeE2701A6d78962));
    
    function prezzoKrown() view public returns(uint256){
        (uint112 reserveLP0, uint112 reserveLP1, ) = lpToken.getReserves();
        uint256 prezzoToken = router.quote(1000000000000000000, reserveLP1, reserveLP0);
        return prezzoToken;
    }
    
    function prezzoMatic() view public returns(uint256){
        (uint112 reserveLP01, uint112 reserveLP11, ) = lpTokenFinal.getReserves();
        reserveLP11 = reserveLP11 * 10**12;
        uint256 prezzoTokenFinal = router.quote(1000000000000000000, reserveLP01, reserveLP11);
        return prezzoTokenFinal;
    }
    
    function prezzoKRWinUSDC() view public returns(uint256){
        return (prezzoKrown() * prezzoMatic()) /10**18;
    }
    
    function token0(uint256 _pid) view public returns(address){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        address token = factory.getPair(tokenLP.token0(), address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174));
        return token;
    }
    
    function token1(uint256 _pid) view public returns(address){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        address token = factory.getPair(tokenLP.token1(), address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174));
        return token;
    }
    
    function prezzoToken0(uint256 _pid) view public returns(uint256){
        (uint112 reserveLP0, uint112 reserveLP1, ) = IPancakeLPToken(token0(_pid)).getReserves();
        uint256 prezzoToken = router.quote(1000000000000000000, reserveLP0, reserveLP1);
        return prezzoToken;
    }
    
    function prezzoToken1(uint256 _pid) view public returns(uint256){
        (uint112 reserveLP0, uint112 reserveLP1, ) = IPancakeLPToken(token1(_pid)).getReserves();
        uint256 prezzoToken = router.quote(1000000000000000000, reserveLP0, reserveLP1);
        return prezzoToken;
    }
    
    function reverseToken0(uint256 _pid) view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        (uint112 reserveLP0, , ) = tokenLP.getReserves();
        uint256 quantity = (kingDeFiFarm.getTotalSupply(_pid) * reserveLP0) / tokenLP.totalSupply();
        return quantity;
    }
    
    function reverseToken1(uint256 _pid) view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        ( , uint112 reserveLP1 , ) = tokenLP.getReserves();
        uint256 quantity = (kingDeFiFarm.getTotalSupply(_pid) * reserveLP1) / tokenLP.totalSupply();
        return quantity;
    }
    
    function tvl(uint256 _pid) view public returns (uint256) {
        return (prezzoToken0(_pid) * reverseToken0(_pid) / 10**18) + (prezzoToken1(_pid) * reverseToken1(_pid) / 10**18);
    }
    
    function apr(uint256 _pid) view public returns(uint256){
        uint256 blockPerYear = (365 * 24 * 60 * 60) / 3;
        uint256 busdPerYear = blockPerYear * kingDeFiFarm.getKrwPerBlock(_pid) * prezzoKrown();
        return ((busdPerYear / (tvl(_pid) + 1)) * 100) / 10**18;
    }
    
    function reverseToken0Total(uint256 _pid, address account) view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        (uint256 amount, ) = kingDeFiFarm.userInfo(_pid, account);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        (uint112 reserveLP0, , ) = tokenLP.getReserves();
        uint256 quantity = (amount * reserveLP0) / tokenLP.totalSupply();
        return quantity;
    }
    
    function reverseToken1Total(uint256 _pid, address account) view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        (uint256 amount, ) = kingDeFiFarm.userInfo(_pid, account);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        ( , uint112 reserveLP1 , ) = tokenLP.getReserves();
        uint256 quantity = (amount * reserveLP1) / tokenLP.totalSupply();
        return quantity;
    }
    
    function tvlTotal(uint256 _pid, address account) view public returns (uint256) {
        return (prezzoToken0(_pid) * reverseToken0Total(_pid, account) / 10**18) + (prezzoToken1(_pid) * reverseToken1Total(_pid, account) / 10**18);
    }
    
    function totalDeposit(address account) view public returns(uint256){
        uint256 tt;
        for(uint256 i = 0; i < kingDeFiFarm.poolLength(); i++){
            tt = tt + tvlTotal(i, account);
        }
        return tt;
    }
    
    function totalPending(address account) view external returns(uint256){
        uint256 tt = 0;
        for(uint256 i = 0; i < kingDeFiFarm.poolLength(); i++){
            tt = tt + kingDeFiFarm.getPending(i, account);
        }
        return tt;
    }
    
    function totalSupply(uint256 _pid) view public returns(uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        return tokenLP.totalSupply();
    }
    
    function totalSupplyBusdPool() view public returns (uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(2);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        return tokenLP.totalSupply();
    }
    
    function reserve0(uint256 _pid) view public returns(uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        (uint112 reserveLP0, , ) = tokenLP.getReserves();
        return reserveLP0;
    }
    
    function reserve1(uint256 _pid) view public returns(uint256){
        (address tokenAddr, , , , , , , ,) = kingDeFiFarm.poolInfo(_pid);
        IPancakeLPToken tokenLP = IPancakeLPToken(tokenAddr);
        ( , uint112 reserveLP1 , ) = tokenLP.getReserves();
        return reserveLP1;
    }
    
    function dollariPerUnita(uint256 _pid) view public returns(uint256){
        return (((1000000000000000000 * reserve0(_pid)) / totalSupply(_pid) * prezzoToken0(_pid)) / 10**18) + (((1000000000000000000 * reserve1(_pid)) / totalSupply(_pid) * prezzoToken1(_pid)) / 10**18); 
    }
}