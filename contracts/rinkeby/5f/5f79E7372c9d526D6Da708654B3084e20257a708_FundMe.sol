// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe{
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address owner;

    constructor() public {
      owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function fund() public payable {
        addressToAmountFunded[msg.sender]+=msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
      AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
      (,int256 answer,,,) = priceFeed.latestRoundData();
      return uint256(answer*10**10);
    }

    function getConversionRate(uint256 ethAmount)public view returns(uint256){
      uint256 ethPrice = getPrice();
      return (ethPrice*ethAmount)/10**18;
    }

    function withdraw()public onlyOwner payable  {
      msg.sender.transfer(address(this).balance);
      for (uint256 i=0; i < funders.length;i++){
        addressToAmountFunded[funders[i]] = 0 ;
      }
      funders = new address[](0);
    }
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