// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public fundsByStaker;
    address[] public stakers;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You must be the contract's owner to withdraw the staked funds!"
        );
        _; // rest of the function that calls modifier
    }

    // Stake some funds on the contract
    function stake() public payable {
        uint256 minUSD = 1;
        require(
            getPriceUSD(msg.value) >= minUSD,
            "You need to stake more ETH (min 1 USD)!"
        );
        fundsByStaker[msg.sender] += msg.value;
        stakers.push(msg.sender);
    }

    // Withdraw all funds staked in the contract
    function withdraw() public onlyOwner {
        // Transfer all funds from the contract's balance to the sender (owner)
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < stakers.length; i++) {
            // Zero all stakes after withdrawal
            fundsByStaker[stakers[i]] = 0;
        }
        // Clear all stakers
        stakers = new address[](0); // new blank address array
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    // Return ETH/USD rate in USD
    function getRateUSD() public view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        ).latestRoundData();
        // non-ETH pairs (ETH/USD, etc.) have 8 decimals.
        return uint256(answer) / 10**8;
    }

    // Return ETH/USD price in USD
    function getPriceUSD(uint256 amountWEI) public view returns (uint256) {
        // Amount is in WEI and we need the ETH/USD price
        return (getRateUSD() * amountWEI) / 10**18;
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