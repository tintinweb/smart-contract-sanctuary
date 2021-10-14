//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import {IPepitoAddressesProvider} from "./interfaces/IPepitoAddressesProvider.sol";

contract Pepito {
    IPepitoAddressesProvider internal _addressesProvider;
    int256 public priceFeed;

    constructor(IPepitoAddressesProvider provider) {
        _addressesProvider = provider;
    }

    function start() external {
        address oracle = _addressesProvider.getOracle();
        priceFeed = AggregatorInterface(oracle).latestAnswer();
    }

    
}

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

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IPepitoAddressesProvider {
  function setOracle(address oracle) external;

  function getOracle() external view returns (address);
}