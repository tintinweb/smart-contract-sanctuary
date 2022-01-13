// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1 <0.9.0;

// This is just an interface
import "AggregatorV3Interface.sol"; // this pointing to npm repo

contract FundMe {

    mapping(address => uint256) public wallet;
    address[] funders;
    address owner;

    constructor() public {
        // immediately called as the contract is depoyed
        owner = msg.sender;  // in this context, the sender is whoever deployed the contract onchain
    }

    function fund() public payable {
        // the minimum contribution is 50$
        uint256 minAmount = 50 * (10 ** 18);
        require(convertInUsd(msg.value) >= minAmount, "You need to spend at least 50$");
        wallet[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeedEthUsd = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeedEthUsd.version();
    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeedEthUsd = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeedEthUsd.latestRoundData();
        // chainink has 8 decimal places (guei) → needs to convert to wei (from 10^8 to 10^18)
        return uint256(answer * (10**10));
    }

    // the eth amount is expressed in eth
    function convertInUsd(uint256 ethAmount) public view returns(uint256) {
        uint256 ethUsdRate = getPrice();
        // this price has 18 decimal places: it's the price in dollars if 1 wei was 1 eth
        // so, to turn it back to eth, we need to go back to 18 decimal places
        return ethAmount * ethUsdRate / (10**18);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You're not the owner of this contract.");
        _;
    }

    function balance() onlyOwner public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() onlyOwner payable public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint i = 0; i < funders.length; i++) {
            wallet[funders[i]] = 0;
        }
        funders = new address[](0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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