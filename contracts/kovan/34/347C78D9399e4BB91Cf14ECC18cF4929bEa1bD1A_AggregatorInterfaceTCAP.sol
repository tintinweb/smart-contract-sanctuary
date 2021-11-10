// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract AggregatorInterfaceTCAP {
  int256 value = 297070699644047560000;

  function latestAnswer() public view virtual returns (int256) {
    return value;
  }

  function latestRoundData()
    public
    view
    virtual
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
		36893488147419105170,
      value,
		1636560798,
		1636560798,
		36893488147419105170
    );
  }

  function setLatestAnswer(int256 _tcap) public {
    value = _tcap;
  }

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 timestamp
  );
  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}