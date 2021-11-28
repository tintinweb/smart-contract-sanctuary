/**
 *Submitted for verification at FtmScan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// import all dependencies and interfaces:

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);
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

    struct TokenObj{
        address token_add;
        uint8 decimals;
    }
    struct PairObj {
        address pair_address;
        TokenObj token0;
        TokenObj token1;
    }

    function getAllFactoryPairs(
        address factory_address,
        uint256 skip,
        uint256 limit
    ) public view returns(PairObj[] memory){

        uint256 j = 0;
        limit += skip; 
        uint256 count = limit  - skip;
        IUniswapV2Factory factory = IUniswapV2Factory(factory_address);
        uint256 total_count =  factory.allPairsLength();
        if (total_count < limit) {
            limit = total_count;
        }
        PairObj[] memory pairs = new PairObj[](count);
        for(uint256 i = skip ; i < limit ; i ++){
            address pair_address = factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            address t0 = pair_obj.token0();
            address t1 = pair_obj.token1();
            pairs[j] = PairObj(
                pair_address,
                TokenObj(
                    t0,
                    IERC20(t0).decimals()
                ),
                TokenObj(
                    t1,
                    IERC20(t1).decimals()
                )
            );
            j++;
        }
        return pairs;
    }

}