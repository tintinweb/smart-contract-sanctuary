//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe{

    mapping(address => uint256) public addressFunded;
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    address[] public funders;
    address public owner;

    // when the contract is deployed, we are set as the owner
    constructor(){
        owner = msg.sender;
    }

    // requires a minium of 50 dolars to receive, otherwise, reject.
    function fund() public payable{
        uint256 minimumUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        //add funders
        addressFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    //the owner receives all the amount funded
    function withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        //reset funders
        for (uint256 index=0; index < funders.length; ++index){
            address funder = funders[index];
            addressFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    //Uses interfaces to interact with oracles
    function getPrice() public view returns(uint256){
        (,int answer,,,) = priceFeed.latestRoundData();
        return uint256(answer*10000000000); //18 decimals
    }

    function getDecimals() public view returns(uint256){
        return priceFeed.decimals();
    }

    function getVersion() public view returns(uint256){
        return priceFeed.version();
    }

    //convert ETH (wei) to USD
    function getConversionRate(uint256 weiAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        return ethPrice*weiAmount / 1000000000000000000;
    }

    // Modifiers changes functions behavior.
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
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