/**
 *Submitted for verification at FtmScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// import all dependencies and interfaces:

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
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

contract BatchRead {

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
        uint count = pairs.length; 
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
        uint count = pairs.length; 
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
        uint count = tokens.length; 
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
        uint token_count = tokens.length; 
        uint wallet_count = wallet_addresses.length; 
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

    function getAllFactoryPairsSkipLimit(
        uint skip,
        uint limit
    ) public view returns(address[] memory){
        uint count = limit  - skip;
        address[] memory pairs = new address[](count);
        for(uint i = skip ; i < limit ; i ++){
            pairs[i] = default_factory.allPairs(i);
        }
        return pairs;
    }


    function getAllFactoryPairsSkipLimit() 
            public
            view 
            returns(address[] memory){
        uint count = default_factory.allPairsLength();
        address[] memory pairs = new address[](count);
        for(uint i = 0 ; i < count ; i ++){
            pairs[i] = default_factory.allPairs(i);
        }
        return pairs;
    }

    struct LP_balance{
        address LP_token;
        uint balance;
    }

    function multiGetLPBalancesSkipLimit(
        address wallet_address,
        uint skip,
        uint limit
    )public view returns(LP_balance[] memory){
        uint count = limit  - skip;
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint i = skip; i < limit; i ++){
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
        uint count = default_factory.allPairsLength();
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for(uint i = 0; i < count; i ++){
            address pair_address = default_factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address, 
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
    }

    function getAmountsOutMulti(
        uint amountIn, address[][] memory path
    ) public view returns (uint , address[] memory){
        uint count = path.length;
        uint max = 0; 
        uint index = 0;
        uint[] memory amountsOut;
        uint amountOut = 0;
        for (uint i = 0; i < count; i ++){
            amountsOut = default_router.getAmountsOut(amountIn, path[i]);
            amountOut = amountsOut[path[i].length - 1];
            if ( amountOut > max ){
                index = i;
                max = amountOut;
            }
        } 
        return (max , path[index]);
    }

    uint MAX_INT_VALUE = 2 ** 255;
    function getAmountsInMulti(
        uint amountOut, address[][] memory path
    ) public view returns (uint , address[] memory){
        uint count = path.length;
        uint min = 0; 
        uint index = 0;
        uint[] memory amountsIn;
        uint amountIn = MAX_INT_VALUE;
        for (uint i = 0; i < count; i ++){
            amountsIn = default_router.getAmountsIn(amountOut, path[i]);
            amountIn = amountsIn[0];
            if ( amountIn < min ){
                index = i;
                min = amountIn;
            }
        } 
        return (min , path[index]);
    }

}