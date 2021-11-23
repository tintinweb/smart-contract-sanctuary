/**
 *Submitted for verification at FtmScan.com on 2021-11-22
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


    struct ShareOfPool{
        address pair_address;
        address token0;
        uint256 share0;
        address token1;
        uint256 share1;
        uint256 share;
        uint256 balance;
    }
    
    uint256 public DIV_PERCISION = 100000;


    function _getShare(IUniswapV2Pair pair_obj, address wallet_address) 
        internal
        view
        returns(ShareOfPool memory)
    {
       (uint256 r0,uint256 r1,) = pair_obj.getReserves();
       uint256 balance = pair_obj.balanceOf(wallet_address);
        uint256 share_with_percision = (balance * DIV_PERCISION ) / pair_obj.totalSupply();
        if (share_with_percision > 1 ){
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                (r0 * DIV_PERCISION )/share_with_percision,
                pair_obj.token1(),
                (r1 * DIV_PERCISION )/share_with_percision,
                share_with_percision,
                balance
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
                0,
                0
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
        result = 0;
        for(uint256 i = 0; i < count; i ++){   
            
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            
            if (pair_obj.token0() == token_address){
                ShareOfPool memory share = _getShare(pair_obj,wallet_address);
                shares[i] = share;
                result += share.share0;
            }
            else if (pair_obj.token1() == token_address ){
                ShareOfPool memory share = _getShare(pair_obj,wallet_address);
                shares[i] = share;
                result += share.share1;
            }
        }
        return (shares,result);
    }




}