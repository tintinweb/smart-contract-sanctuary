/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity >=0.7.0;
//SPDX-License-Identifier: MIT
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
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
contract test1 {
    function get_pair_address(address token0, address token1) public pure returns (address){
        return address(uint(keccak256(abi.encodePacked(hex'ff', 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 
        keccak256(abi.encodePacked(token0, token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'))));
    }
    function get_amount_token1(address token0, address token1, uint amount_token0) external view returns(uint){
        address tokenA;
        address tokenB;
        if (token0 > token1) {
            tokenA = token1;
            tokenB = token0;
        } else {
            tokenA = token0;
            tokenB = token1;
        }
        IUniswapV2Pair pair = IUniswapV2Pair(get_pair_address(tokenA, tokenB));
        (uint112 Res0, uint112 Res1,) = pair.getReserves();
        if (token0 > token1) {
            return (amount_token0 * Res0 / Res1);
        } else {
            return (amount_token0 * Res1 / Res0);
        }
    }
}
contract test2 {
    IUniswapV2Factory internal constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    function get_amount_token1(address token0, address token1, uint amount_token0) external view returns(uint){
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        (uint112 Res0, uint112 Res1,) = pair.getReserves();
        if (token0 > token1) {
            return (amount_token0 * Res0 / Res1);
        } else {
            return (amount_token0 * Res1 / Res0);
        }
    }
}