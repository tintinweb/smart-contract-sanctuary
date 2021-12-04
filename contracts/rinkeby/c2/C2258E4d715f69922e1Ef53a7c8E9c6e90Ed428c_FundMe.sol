/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

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

pragma solidity >=0.6.0 <0.9.0;



contract FundMe{

    mapping(address => uint) public funders;
    uint limit = 50 * 10 ** 18;
    address[] public fundersList;
    address payable owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable{
        require(valueConversion(msg.value) >= limit, "not enough funds");
        funders[msg.sender] += msg.value;
        fundersList.push(msg.sender);
    }

    function withdraw() payable onlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
        for(uint i=0;i<fundersList.length;i++){
            funders[fundersList[i]] = 0;
        }
    }

    function getLatestPrice() public view returns (uint) {

        (,int price,,,) = priceFeed.latestRoundData();
        return uint(price);
    }

    function valueConversion(uint _valueReceived) public view returns(uint){
        uint price = uint(getLatestPrice()) * 10000000000;
        uint value = (price * _valueReceived) / 1000000000000000000;
        return value;
    }


}