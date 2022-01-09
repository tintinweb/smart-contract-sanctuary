// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "AggregatorV3Interface.sol";
contract FundMe{
    AggregatorV3Interface public priceFeed ;
    address public owner ;
    constructor(address conversion_address) public{
        priceFeed = AggregatorV3Interface(conversion_address);
        owner = msg.sender;
    }
    mapping (address => uint256) public address_to_amount;


    function fund() payable public{
        address_to_amount[msg.sender] = msg.value;
        uint256 minimum_amount = 1  ;
        require( getConvertedUSD(msg.value/(10**9))  > minimum_amount , "You Stupid Customer " );
    }

    function getversion() public view returns(uint256){
        return priceFeed.version();
    }

    function get_usd_price() public view returns(uint256){
        ( , int256 answer,  ,  ,   ) =priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConvertedUSD(uint256 eth_amount_gwei) public view returns (uint256){
        return(uint256( (eth_amount_gwei) * get_usd_price()/10**17 ));
    }

    function withdraw() payable public{
        address cur_address = payable(address(this));
        require(msg.sender == owner);
        payable(msg.sender).transfer((cur_address).balance) ;
    }
    uint256 public current_money = address(this).balance;
    address public contract_address = address(this);
    address public sender_address =  msg.sender;
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