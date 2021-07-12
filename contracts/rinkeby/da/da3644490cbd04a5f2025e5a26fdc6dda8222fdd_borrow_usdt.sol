/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity ^0.4.24;




interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
}


contract borrow_usdt {
    
    AggregatorInterface eth_usd = AggregatorInterface(address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e));
    
    function get()public view returns(int){
        return eth_usd.latestAnswer();
    }
    
    
}