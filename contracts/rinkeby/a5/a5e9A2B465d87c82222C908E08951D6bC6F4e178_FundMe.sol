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

    function get_entrance_fee() public view returns(uint256){
        uint256 cur_price = get_usd_price();
        uint256 usd_ent_fee = 50*10**8 ;
        return uint256 ((usd_ent_fee*(10**18))/cur_price) ;

    }
    function fund() payable public{
        uint256 minimum_amount = 50*(10**8)  ; // all usd values has 8 extra zeros
        require( getConvertedUSD(msg.value)  >= minimum_amount , "You Stupid Customer " );
        address_to_amount[msg.sender] += msg.value;
    }

    function getversion() public view returns(uint256){
        return priceFeed.version();
    }

    function get_usd_price() public view returns(uint256){
        ( , int256 answer,  ,  ,   ) =priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConvertedUSD(uint256 eth_amount_wei) public view returns (uint256){
        return(uint256( (eth_amount_wei) * get_usd_price()/10**18 ));
    }

    function withdraw() payable public{
        address cur_address = payable(address(this));
        require(msg.sender == owner);
        uint256 balance_before_withdraw= cur_address.balance;
        payable(msg.sender).transfer((cur_address).balance) ;
        address_to_amount[msg.sender] -= balance_before_withdraw;
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