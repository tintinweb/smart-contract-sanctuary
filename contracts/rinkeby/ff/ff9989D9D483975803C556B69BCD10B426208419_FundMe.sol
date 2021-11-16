/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // wei olarak depolar
    function fund() public payable {
        uint256 minimumUSD = 50 * (10**18); //wei olarak depoladÄ±ÄŸÄ±mÄ±z iÃ§in 50 * 10^18 yapÄ±yoruz

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to donate at least 50$ dollars worth of ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    // fiyatÄ± gwei olarak dÃ¶ndÃ¼rÃ¼r
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10**10);
    }

    // deÄŸerin kÃ¼suratlarÄ±ndan kurtulup 1 eth kaÃ§ dolar onu anlÄ±k dÃ¶ndÃ¼rÃ¼r
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner); // eÄŸer bu talepte bulunan adress ile parayÄ± yatÄ±ran eÅŸleÅŸmiyorsa iÅŸlemi revert eder
        _; // eÄŸer bu eÅŸleÅŸme True dÃ¶ndÃ¼rÃ¼rse geriye kalan kodu Ã§alÄ±ÅŸtÄ±rÄ±r
    }

    // sÃ¶zleÅŸmeye yatÄ±rÄ±lmÄ±ÅŸ bÃ¼tÃ¼n parayÄ± Ã§eker (sÃ¶zleÅŸmeyle kim iletiÅŸime geÃ§iyorsa(owner) onun cÃ¼zdanÄ±na Ã§eker)
    function withdraw() public payable {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // baÄŸÄ±ÅŸÃ§Ä±larÄ±n balance'larÄ±nÄ± sÄ±fÄ±rlar
        }
        funders = new address[](0); // baÄŸÄ±ÅŸÃ§Ä± listesini sÄ±fÄ±rlar
    }
}