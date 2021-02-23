pragma solidity =0.5.16;

import './IMateriaFactory.sol';
import './MateriaPair.sol';

contract MateriaFactory is IMateriaFactory, MateriaOwnable {
    address public feeTo;

    uint256 public defaultMateriaFee;
    uint256 public defaultSwapFee;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(uint256 _defaultMateriaFee, uint256 _defaultSwapFee) public MateriaOwnable() {
        defaultMateriaFee = _defaultMateriaFee; //Default value: 5
        defaultSwapFee = _defaultSwapFee; //Default value: 3
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external onlyOwner returns (address pair) {
        require(tokenA != tokenB, 'Materia: identical addresses');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Materia: zero address');
        require(getPair[token0][token1] == address(0), 'Materia: pair already exists'); // single check is sufficient
        bytes memory bytecode = type(MateriaPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMateriaPair(pair).initialize(token0, token1, defaultMateriaFee, defaultSwapFee);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function setDefaultMateriaFee(uint256 _defaultMateriaFee) external onlyOwner {
        defaultMateriaFee = _defaultMateriaFee;
    }

    function setDefaultSwapFee(uint256 _defaultSwapFee) external onlyOwner {
        defaultSwapFee = _defaultSwapFee;
    }

    function setFees(
        address pair,
        uint256 materiaFee,
        uint256 swapFee
    ) external onlyOwner {
        IMateriaPair(pair).setSwapFee(swapFee);
        IMateriaPair(pair).setMateriaFee(materiaFee);
    }
}