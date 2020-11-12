pragma solidity =0.5.16;

import './IHiSwapFactory.sol';
import './ILiquidityBonusPool.sol';
import './HiSwapPair.sol';

contract HiSwapFactory is IHiSwapFactory {
    address public feeTo;
    address public feeToSetter;
    address public liquidityBonusPool;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'HiSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'HiSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'HiSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(HiSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IHiSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'HiSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setLiquidityBonusPool(address _bonusPool)external{
        require(msg.sender == feeToSetter, 'HiSwap: FORBIDDEN');
        liquidityBonusPool = _bonusPool;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'HiSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
