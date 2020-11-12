// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol

pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: contracts/oracleIterators/IOracleIterator.sol



pragma solidity >=0.4.21 <0.7.0;

interface IOracleIterator {
    /// @notice Proof of oracle iterator contract
    /// @dev Verifies that contract is a oracle iterator contract
    /// @return true if contract is a oracle iterator contract
    function isOracleIterator() external pure returns(bool);

    /// @notice Symbol of the oracle iterator
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbol
    function symbol() external view returns (string memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    //  finds the value closest to a given timestamp
    /// @param _oracle iteratable oracle through
    /// @param _timestamp a given timestamp
    /// @param _roundHint specified round for a given timestamp
    /// @return the value closest to a given timestamp
    function getUnderlingValue(address _oracle, uint _timestamp, uint _roundHint) external view returns(int);
}

// File: contracts/oracleIterators/ChainlinkOracleIterator.sol

// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity >=0.4.21 <0.7.0;



contract ChainlinkOracleIterator is IOracleIterator {
    int public constant NEGATIVE_INFINITY = type(int256).min;

    function isOracleIterator() external override pure returns(bool) {
        return true;
    }

    function symbol() external override view returns (string memory) {
        return "ChainlinkIterator";
    }

    function getUnderlingValue(address _oracle, uint _timestamp, uint _roundHint) public override view returns(int) {
        require(_timestamp > 0, "Zero timestamp");
        require(_oracle != address(0), "Nullable oracle");
        AggregatorInterface oracle = AggregatorInterface(_oracle);

        if(_roundHint > 0) {
            uint roundHintTimestamp = oracle.getTimestamp(_roundHint);
            uint nextRoundHintTimestamp = oracle.getTimestamp(_roundHint + 1);

            if(roundHintTimestamp > 0 && roundHintTimestamp <= _timestamp &&
                (nextRoundHintTimestamp == 0 || nextRoundHintTimestamp > _timestamp)) {
                return oracle.getAnswer(_roundHint);
            } else {
                revert('Incorrect hint');
            }
        }

        uint roundTimestamp = 0;
        uint roundId = oracle.latestRound() + 1;

        do {
            roundId -= 1;
            roundTimestamp = oracle.getTimestamp(roundId);
        } while(roundTimestamp > _timestamp && roundId > 0);

        if(roundId == 0 && oracle.getTimestamp(roundId) > _timestamp) {
            return NEGATIVE_INFINITY;
        }

        return oracle.getAnswer(roundId);
    }
}