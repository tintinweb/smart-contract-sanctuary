pragma solidity >=0.6.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "AggregatorV3Interface.sol";

contract FundMe
{
    uint256 num;
    address owner;
    AggregatorV3Interface A3;
    mapping(address=>uint256) addressToMapping;
    constructor(address price_feed)
    {
        A3=AggregatorV3Interface(price_feed);
        owner=msg.sender;
    }
    function addFundings() payable public
    {
        addressToMapping[msg.sender]=msg.value;
    }
    function withdraw() payable public 
    {
        payable(msg.sender).transfer(address(this).balance);
    }
    function contractBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
    function ETHtoUSD() public view returns(uint256)
    {
        (,int256 ans,,,) =A3.latestRoundData();
        return uint256(ans);
    }
    function setNum(uint256 _num) public
    {
        num=_num;
    }
    function show() public view returns(uint256)
    {
        return num;
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