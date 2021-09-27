pragma solidity =0.5.16;
import './IMy_Factory.sol';
import './My_pair.sol';
//工厂合约,存储/产生配对合约
contract My_Factory is IMy_Factory{
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    constructor() public {
        createPair(0x90CEEF0bB3fB7F7c616931bB23eC7cb6761A20aa,0xA3803463C5cA2A7108fD417533DBAb726189cA66);
        createPair(0x5e4AB0253667523Eb87a49920F887E50D2A70150,0xA3803463C5cA2A7108fD417533DBAb726189cA66);
        createPair(0x90CEEF0bB3fB7F7c616931bB23eC7cb6761A20aa,0x5e4AB0253667523Eb87a49920F887E50D2A70150);
    }
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) public returns (address pair) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient
        My_pair new_pair = new My_pair(token0, token1);
        pair = address(new_pair);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}