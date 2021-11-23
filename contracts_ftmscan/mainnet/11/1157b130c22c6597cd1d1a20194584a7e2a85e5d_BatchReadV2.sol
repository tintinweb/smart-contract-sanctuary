/**
 *Submitted for verification at FtmScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// import all dependencies and interfaces:

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BatchReadV2 {

    IUniswapV2Router public default_router;
    IUniswapV2Factory public default_factory;
    address public Owner;

    constructor(address _default_router){
        default_router = IUniswapV2Router(_default_router);
        default_factory = IUniswapV2Factory(default_router.factory());
        Owner = msg.sender;
    }
    
    function change_default_router(address _default_router) public{
        require(msg.sender == Owner, "Owner Call Plaese Bitch !");
        default_router = IUniswapV2Router(_default_router);
        default_factory = IUniswapV2Factory(default_router.factory());

    }
    function change_owner(address new_owner) public{
        require(msg.sender == Owner, "Owner Call Plaese Bitch !");
        Owner = new_owner;
    }
    
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
        uint256 skip,
        uint256 limit
    ) public view returns(PairObj[] memory){
        uint256 count = limit  - skip;
        PairObj[] memory pairs = new PairObj[](count);
        for(uint256 i = skip ; i < limit ; i ++){
            address pair_address = default_factory.allPairs(i);
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
    ) 
            public
            view 
            returns(PairObj[] memory){

        uint256 count = default_factory.allPairsLength();
        PairObj[] memory pairs = new PairObj[](count);
        for(uint256 i = 0 ; i < count ; i ++){
            address pair_address = default_factory.allPairs(i);
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
        address wallet_address,
        uint256 skip,
        uint256 limit
    )public view returns(LP_balance[] memory){
        uint256 count = limit  - skip;
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint256 i = skip; i < limit; i ++){
            address pair_address = default_factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address, 
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
        
    }

    function multiGetLPBalances(
        address wallet_address
    )public view returns(LP_balance[] memory){
        uint256 count = default_factory.allPairsLength();
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint256 i = 0; i < count; i ++){
            address pair_address = default_factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address, 
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
    }

    function getAmountsOutMulti(
        uint256 amountIn, address[][] memory path
    ) public view returns (uint256 , address[] memory){
        uint256 count = path.length;
        uint256 max = 0; 
        uint256 index = 0;
        uint[] memory amountsOut;
        uint256 amountOut = 0;
        for (uint256 i = 0; i < count; i ++){
            amountsOut = default_router.getAmountsOut(amountIn, path[i]);
            amountOut = amountsOut[path[i].length - 1];
            if ( amountOut > max ){
                index = i;
                max = amountOut;
            }
        } 
        return (max , path[index]);
    }

    uint256 MAX_INT_VALUE = 2 ** 255;
    function getAmountsInMulti(
        uint256 amountOut, address[][] memory path
    ) public view returns (uint256 , address[] memory){
        uint256 count = path.length;
        uint256 min = MAX_INT_VALUE; 
        uint256 index = 0;
        uint[] memory amountsIn;
        uint256 amountIn = 0;
        for (uint256 i = 0; i < count; i ++){
            amountsIn = default_router.getAmountsIn(amountOut, path[i]);
            amountIn = amountsIn[0];
            if ( amountIn < min ){
                index = i;
                min = amountIn;
            }
        } 
        return (min , path[index]);
    }



    struct ShareOfPool{
        address pair_address; // Pair Address ( same as LP token address )
        address token0;
        uint256 share0; // Rough Number of tokens user have of token0
        address token1;
        uint256 share1; // Rough Number of tokens user have of token1
        uint256 share; // Divide by 10 ^ 18 and yu will have users share of pool
        uint256 balance; // balance of LPs user have on this pair
        uint256 totalSupply; // Total LP s made for this perticular pair
    }
    
    uint256 public DIV_PERCISION = 10 ** 18;


    function _getShare(IUniswapV2Pair pair_obj, address wallet_address) 
        internal
        view
        returns(ShareOfPool memory)
    {
        (uint256 r0,uint256 r1,) = pair_obj.getReserves();
        uint256 wallet_LP_balance = pair_obj.balanceOf(wallet_address);
        uint256 totalSupply =  pair_obj.totalSupply();
        if (totalSupply == 0) {
            
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                0,
                pair_obj.token1(),
                0,
                0,
                0,
                0
            );
            
        return share;
        }
        uint256 share_with_percision = (wallet_LP_balance * DIV_PERCISION ) /totalSupply;
        if (share_with_percision > 1 ){
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                (r0 * share_with_percision )/DIV_PERCISION,
                pair_obj.token1(),
                (r1 * share_with_percision )/DIV_PERCISION,
                share_with_percision,
                wallet_LP_balance,
                totalSupply
            );
            
        return share;
        }
        else{
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                0,
                pair_obj.token1(),
                0,
                share_with_percision,
                wallet_LP_balance,
                totalSupply
            );
            
        return share;
        }
    }


    function getShareMulti(
        address wallet_address
    ) public view returns(ShareOfPool[] memory){
        uint256 count = default_factory.allPairsLength();
        ShareOfPool[] memory shares = new ShareOfPool[](count);
        for(uint256 i = 0; i < count; i ++){   
            
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            shares[i] = _getShare(pair_obj, wallet_address);
        }
        return shares;

    }



   function getShareMultiExactToken(
        address wallet_address,
        address token_address
    ) public view returns(ShareOfPool[] memory , uint256 result){
        uint256 count = default_factory.allPairsLength();
        ShareOfPool[] memory shares = new ShareOfPool[](count);
        bool[] memory token_share_indecies = new bool[](count);
        uint256 token_pairs_count = 0 ;
        result = 0;
        for(uint256 i = 0; i < count; i ++){   
            
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            
            if (pair_obj.token0() == token_address){
                ShareOfPool memory share = _getShare(pair_obj,wallet_address);
                shares[i] = share;
                result += share.share0;
                token_pairs_count += 1;
                token_share_indecies[i] = true;
            }
            else if (pair_obj.token1() == token_address ){
                ShareOfPool memory share = _getShare(pair_obj,wallet_address);
                shares[i] = share;
                result += share.share1;
                token_pairs_count += 1;
                token_share_indecies[i] = true;
            }
        }
        ShareOfPool[] memory token_shares = new ShareOfPool[](token_pairs_count);   
        uint256 j = 0;
        for ( uint256 i = 0; i < count; i++){
            if (token_share_indecies[i] == true){
                
                token_shares[j] = shares[i];
                j ++;
            }
        }
        return (token_shares,result);
    }
    
    function circulatingSupply(
        address token_address,
        address[] memory locked_walltes
        ) public view returns(uint256 result){
            IERC20 token_obj = IERC20(token_address);
            result = token_obj.totalSupply();
            for (uint256 i = 0 ; i < locked_walltes.length ; i ++){
                result -= token_obj.balanceOf(locked_walltes[i]);
            }
            
        }


}