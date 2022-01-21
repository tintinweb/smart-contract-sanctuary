// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract Lottery {

    address payable[] public Players; // The array is payable, public and called Players.
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdRate; 

    constructor(address rate_contract) public {
        usdEntryFee = 50 * (10**18); // In wei.
        ethUsdRate = AggregatorV3Interface(rate_contract);
    }

    function enter() public payable {
        // 50USD minimum.
        Players.push(msg.sender);

    }


    function getEntranceFee() public view returns (uint256) {
    
        (, int256 rate,,,) = ethUsdRate.latestRoundData(); // INT
        // Everything in wei. As the function returns already with 8 decimals we add 10 more.
        uint256 adjustedPrice = uint256(rate) * 10**10; // UINT  

        //ENTRY ETH PRICE 
        // 5O USD / ETH_USD_RATE

        // IMPORTANT - We should use SafeMath just to be safe. But in latest solidity version we don't need it
        uint256 costToEnter = usdEntryFee / adjustedPrice;
        return costToEnter; 

    }



    function startLottery() public {}
    function endLottery() public {}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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