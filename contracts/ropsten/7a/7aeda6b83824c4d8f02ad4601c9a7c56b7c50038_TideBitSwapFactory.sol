// SPDX-License-Identifier: GPLv3

pragma solidity >=0.7.0 <0.9.0;

import './ITideBitSwapFactory.sol';
import './TideBitSwapPair.sol';

contract TideBitSwapFactory is ITideBitSwapFactory {
  address public feeTo;
  address public feeToSetter;

  mapping(address => mapping(address => address)) public getPair;
  address[] public allPairs;

  constructor() {
    feeTo = msg.sender;
    feeToSetter = msg.sender;
  }

  function allPairsLength() external view returns (uint) {
    return allPairs.length;
  }

  function createPair(address tokenA, address tokenB) external returns (address pair) {
    require(tokenA != tokenB, 'TideBitSwap: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'TideBitSwap: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'TideBitSwap: PAIR_EXISTS'); // single check is sufficient
    bytes memory bytecode = type(TideBitSwapPair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    TideBitSwapPair(pair).initialize(token0, token1);
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair; // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setFeeTo(address _feeTo) external {
    require(msg.sender == feeToSetter, 'TideBitSwap: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter, 'TideBitSwap: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }
}