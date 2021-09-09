// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Mock implementation of Chainlink aggregator, for testnet
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract MockAggregator is AggregatorInterface {
    string public name;

    uint256 _round;

    mapping(uint256 => int256) _answers;

    mapping(uint256 => uint256) _timestamps;

    constructor(string memory _name) {
        name = _name;
    }

    function setAnswer(int256 answer) external {
        _round++;
        _answers[_round] = answer;
        _timestamps[_round] = block.timestamp;

        emit NewRound(_round, msg.sender, block.timestamp);
        emit AnswerUpdated(answer, _round, block.timestamp);
    }

    function latestAnswer() external view override returns (int256) {
        return _answers[_round];
    }

    function latestTimestamp() external view override returns (uint256) {
        return _timestamps[_round];
    }

    function latestRound() external view override returns (uint256) {
        return _round;
    }

    function getAnswer(uint256 roundId)
        external
        view
        override
        returns (int256)
    {
        return _answers[roundId];
    }

    function getTimestamp(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        return _timestamps[roundId];
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}