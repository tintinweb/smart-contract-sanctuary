// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

/*
 * RequiemSwapFinance 
 * App:             https://Requiemswap.finance
 * Medium:          https://medium.com/@Requiem_swap    
 * Twitter:         https://twitter.com/Requiem_swap 
 * Telegram:        https://t.me/Requiem_swap
 * Announcements:   https://t.me/Requiem_swap_news
 * GitHub:          https://github.com/RequiemSwapFinance
 */

import './IRequiemFactory.sol';
import './RequiemPair.sol';

contract RequiemFactory is IRequiemFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(RequiemPair).creationCode));

    address public feeTo;
    address public feeToSetter;

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
        require(tokenA != tokenB, 'RequiemSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'RequiemSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'RequiemSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(RequiemPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IRequiemPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'RequiemSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'RequiemSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}