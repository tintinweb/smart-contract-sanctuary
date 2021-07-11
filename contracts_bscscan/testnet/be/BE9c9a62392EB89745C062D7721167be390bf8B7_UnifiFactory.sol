pragma solidity =0.5.16;

import './interfaces.sol';
import './UnifiPair.sol';

contract UnifiFactory is IUnifiFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UnifiPair).creationCode));

    address public feeTo;
    address public feeToSetter;
    
    address public feeController;
    address public feeControllerSetter;
    address public wbnb;
    address public router;    
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _ufc ,address _wbnb ) public {
        feeToSetter = msg.sender;
        feeControllerSetter       =  msg.sender;
        feeController = _ufc;//change this in future
        wbnb = _wbnb;
        
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Unifi: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Unifi: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Unifi: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UnifiPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
  
        IUnifiPair(pair).initialize(token0, token1,wbnb);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Unifi: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Unifi: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setFeeControler(address _feeController) external {
        require(msg.sender == feeControllerSetter, 'Unifi: FORBIDDEN');
        feeController = _feeController;
    }

    function setFeeControlerSetter(address _feeControllerSetter) external {
        require(msg.sender == feeControllerSetter, 'Unifi: FORBIDDEN');
        feeControllerSetter = _feeControllerSetter;
    }
    
    function setRouter(address _routerAddress) external {
        require(msg.sender == feeControllerSetter, 'Unifi: FORBIDDEN');
        router = _routerAddress;
    }

}