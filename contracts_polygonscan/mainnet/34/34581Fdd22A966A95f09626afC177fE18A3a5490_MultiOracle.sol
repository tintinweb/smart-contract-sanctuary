/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

pragma solidity 0.8.9;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


contract MultiOracle {
    function latestAnswers(address[] calldata oracleAddresses) external view returns (int256[] memory answers) {
        answers = new int256[](oracleAddresses.length);
        
        for (uint256 i = 0; i != oracleAddresses.length; i++) {
            answers[i] = AggregatorInterface(oracleAddresses[i]).latestAnswer();
        }
    }
}