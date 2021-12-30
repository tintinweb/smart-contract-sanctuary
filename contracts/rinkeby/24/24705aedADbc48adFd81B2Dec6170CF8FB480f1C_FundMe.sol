// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//This import enables us interract with chainlink
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmt;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        //to set a minimum amount that the address can send, in this case 50usd
        //the require keyword is used to set conditions in solidity

        uint256 minUsd = 50 * 10**18;
        require(
            getCoversionUSD(msg.value) >= minUsd,
            "Amount below minimum amount required"
        );

        // msg.sender represents the sender address
        //msg.value represents how much was sent

        addressToAmt[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        return priceFeed.version();
    }

    //To get real time price of any currenc1
    //In this case we're getting the price of eth in usd
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        //This is a tuple
        //A tuple is a list of unrelated variables
        //This is how to use a tuple in solidity
        //we delete the variables we dont need and leave commas. This lets solidity know that there's something there
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer);
    }

    //To convert the amount funded(which is normally in eth, to USD)

    function getCoversionUSD(uint256 _ethAmount) public view returns (uint256) {
        //1 eth is 1 billion gwei and 1 gwei is 1 billion wei
        uint256 price = getPrice();

        uint256 ethInUSD = (price * _ethAmount) / 1000000000000000000;

        return ethInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //require(msg.sender == owner);

        //transfer allows us to send eth from one address to another
        //this refers to the address of the contract we're working with
        //so this statement allows us to transfer the entire balance to our address
        msg.sender.transfer(address(this).balance);
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