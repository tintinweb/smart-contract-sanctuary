// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";

/**
 * Find information on LINK Token Contracts here: https://docs.chain.link/docs/link-token-contracts/
 */

contract ArbitrumPriceConsumer {
    // Identifier of the Sequencer offline flag on the Flags contract 
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
    FlagsInterface internal chainlinkFlags;
    
    /**
     * Network: Arbitrum Rinkeby
     * Aggregator: ETH/USD
     * Agg Address: 0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8
     * Flags Address: 0x491B1dDA0A8fa069bbC1125133A975BF4e85a91b
     */
    constructor() {
        chainlinkFlags = FlagsInterface(0x491B1dDA0A8fa069bbC1125133A975BF4e85a91b);
    }
    
    /**
     * Returns the latest price
     */
    function getThePrice(address _priceFeedAddress) public view returns (int) {
        bool isRaised = chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
        if (isRaised) {
            // If flag is raised we shouldn't perform any critical operations
            revert("Chainlink feeds are not being updated");
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);
  function getFlags(address[] calldata) external view returns (bool[] memory);
  function raiseFlag(address) external;
  function raiseFlags(address[] calldata) external;
  function lowerFlags(address[] calldata) external;
  function setRaisingAccessController(address) external;
}