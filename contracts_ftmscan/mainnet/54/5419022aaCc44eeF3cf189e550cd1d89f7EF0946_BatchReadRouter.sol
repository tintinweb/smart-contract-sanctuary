/**
 *Submitted for verification at FtmScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// import all dependencies and interfaces:

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract BatchReadRouter {
    
    function multiGetReservesWithTimestamp(  
        address[] memory pairs
    ) public view returns(uint[] memory, uint[] memory,uint[] memory ){
        uint256 count = pairs.length; 
        uint[] memory reservesA = new uint[](count);
        uint[] memory reservesB = new uint[](count);
        uint[] memory timestampes = new uint[](count);
        for( uint16 i=0 ; i <  count ; i++ ){
            (reservesA[i], reservesB[i],timestampes[i]) = IUniswapV2Pair(pairs[i]).getReserves();
        }
        return (reservesA, reservesB,timestampes);
    }

    function multiGetReserves(  
        address[] memory pairs
    ) public view returns(uint[] memory , uint[] memory){
        uint256 count = pairs.length; 
        uint[] memory reservesA = new uint[](count);
        uint[] memory reservesB = new uint[](count);
        for( uint16 i=0 ; i <  count ; i++ ){
            (reservesA[i], reservesB[i],) = IUniswapV2Pair(pairs[i]).getReserves();
        }
        return (reservesA, reservesB);
    }

    function multiGetBalance(  
        address[] memory tokens,
        address wallet_address
    ) public view returns(uint[] memory){
        uint256 count = tokens.length; 
        uint[] memory balances = new uint[](count);
        for( uint16 i=0 ; i <  count ; i++ ){
            balances[i] = IERC20(tokens[i]).balanceOf(wallet_address);
        }
        return balances;
    }

    function multiGetBalanceWallets(  
        address[] memory tokens,
        address[] memory wallet_addresses
    ) public view returns(uint[][] memory){
        uint256 token_count = tokens.length; 
        uint256 wallet_count = wallet_addresses.length; 
        uint[][] memory wallets = new uint[][](wallet_count);
        for (uint16 i = 0; i < wallet_count; i++){
            uint[] memory balances = new uint[](token_count);
            for( uint16 j=0 ; j <  token_count ; j++ ){
                balances[j] = IERC20(tokens[j]).balanceOf(wallet_addresses[i]);
            }
            wallets[i] = balances;
        }
        return wallets;
    }

    struct PairObj {
        address pair_address;
        address token0;
        address token1;
    }

    function getAllFactoryPairsSkipLimit(
        address router_address,
        uint256 skip,
        uint256 limit
    ) public view returns(PairObj[] memory){

        IUniswapV2Router router = IUniswapV2Router(router_address);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uint256 count = limit  - skip;
        PairObj[] memory pairs = new PairObj[](count);
        for(uint256 i = skip ; i < limit ; i ++){
            address pair_address = factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            pairs[i] = PairObj(
                pair_address,
                pair_obj.token0(),
                pair_obj.token1()
            );
        }
        return pairs;
    }


    function getAllFactoryPairs(
        address router_address
    ) 
            public
            view 
            returns(PairObj[] memory)
    {

        IUniswapV2Router router = IUniswapV2Router(router_address);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uint256 count = factory.allPairsLength();
        PairObj[] memory pairs = new PairObj[](count);
        for(uint256 i = 0 ; i < count ; i ++){
            address pair_address = factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            pairs[i] = PairObj(
                pair_address,
                pair_obj.token0(),
                pair_obj.token1()
            );
        }
        return pairs;
    }


    struct LP_balance{
        address LP_token;
        uint256 balance;
    }

    function multiGetLPBalancesSkipLimit(
        address router_address,
        address wallet_address,
        uint256 skip,
        uint256 limit
    )public view returns(LP_balance[] memory){
        IUniswapV2Router router = IUniswapV2Router(router_address);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uint256 count = limit  - skip;
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint256 i = skip; i < limit; i ++){
            address pair_address = factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address, 
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
        
    }

    function multiGetLPBalances(
        address router_address,
        address wallet_address
    )public view returns(LP_balance[] memory){

        IUniswapV2Router router = IUniswapV2Router(router_address);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uint256 count = factory.allPairsLength();
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint256 i = 0; i < count; i ++){
            address pair_address = factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address, 
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
    }

}