/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
	mapping(address => uint256) public addressToAmountFunded;
	address public owner;
	address[] public funders;

	constructor() {
	    owner = msg.sender;
	}

	modifier onlyOwner {
	    require(msg.sender == owner);
	    _;
	}

	function fund() public payable {
	    uint256 minimumUSDAmount = 50 * 10 ** 18;
	    require(getConversionRate(msg.value) >= minimumUSDAmount, "Minimum amount is 50 USD!!!");
		addressToAmountFunded[msg.sender] += msg.value;
		funders.push(msg.sender);
	}

	/**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
	function getVersion() public view returns (uint256) {
		AggregatorV3Interface chainInterface = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
		uint256 version = chainInterface.version();
		return version;
	}

	function getLatestPrice() public view returns (uint256) {
	    AggregatorV3Interface chainInterface = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
	    (, int256 answer, , , ) = chainInterface.latestRoundData();
	    return uint256(answer);
	}

	function getConversionRate(uint256 ethAmount) public view returns (uint256) {
	    uint256 latestPrice = getLatestPrice();
	    uint256 amountInUSD = ethAmount * latestPrice;
	    return amountInUSD;

	}

	function withdraw() public onlyOwner payable {
	    payable(owner).transfer(address(this).balance);
	    for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
	        address funder = funders[funderIndex];
	        addressToAmountFunded[funder] = 0;
	    }
	    funders = new address[](0);
	}

}