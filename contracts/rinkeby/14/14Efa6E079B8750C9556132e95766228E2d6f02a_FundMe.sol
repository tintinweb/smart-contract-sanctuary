/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



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
    
    address private rinkebyAddr = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

    mapping(address => uint256) public addressToAmtFund;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier minETHToUSD(uint256 minimumUSD) {
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");
        _;
    }
 
    function fund() public minETHToUSD(getFundMinUSD()) payable {
        // What ETH => USD conversion rate
        addressToAmtFund[msg.sender] += msg.value;
        funders.push(msg.sender);        
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(rinkebyAddr);
        return priceFeed.version();
    }
    
    function getFundMinUSD() public pure returns(uint256) {
        uint256 minimumUSD = 50 * 10 ** 18;
        return minimumUSD;
    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(rinkebyAddr);
        // (
        //   uint80 roundId,
        //   int256 answer,
        //   uint256 startedAt,
        //   uint256 updatedAt,
        //   uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        
        (,int256 answer,,,) = priceFeed.latestRoundData();
        
        return uint256(answer * 10000000000);
        
        // 24 NOV 2022 1.55 AM price ETH to USD
        // 4,297.56990602
        // 29 NOV 2022 1.55 AM price ETH to USD
        // 4446.15518659
    }
    
    // 1000000000000000000 wei
    // 1000000000 gwei
    // 0.1 eth
    function getConversionRate(uint256 ethAmt) public view returns(uint256) {
        uint256 ethPriceUSD = getPrice();
        uint256 ethAmtUSD = (ethPriceUSD * ethAmt) / 1000000000000000000;
        return ethAmtUSD;

        // 0.000004346620000000 
        // 0.000004346620000000 * 1000000000 = 4346.62
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner!!");
        _;
    }

    function withdraw() public onlyOwner payable {
        payable(msg.sender).transfer(address(this).balance);

        for(uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            addressToAmtFund[funder] = 0;
        }
        // clear funders
        funders = new address[](0);
    }
}