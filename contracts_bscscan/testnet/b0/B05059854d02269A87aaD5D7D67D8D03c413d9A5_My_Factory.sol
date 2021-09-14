pragma solidity =0.5.16;
import './IMy_Factory.sol';
import './My_pair.sol';
//工厂合约,存储/产生配对合约
contract My_Factory is IMy_Factory{
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    constructor() public {
    }
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        My_pair new_pair = new My_pair(token0, token1);
        pair = address(new_pair);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}