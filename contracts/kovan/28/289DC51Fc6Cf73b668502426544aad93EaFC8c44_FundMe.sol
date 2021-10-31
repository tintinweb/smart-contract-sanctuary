// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

//https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

//interfaces combine down to ABI

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // you can use the constructor to initialize the contarct. before anyone can do anything else to it!
    constructor() {
        owner = msg.sender;
    }

    // "paybale" is keyword used to describe a function that can make payments.
    function fund() public payable {
        //let say we want to have a minumun value for each transaction
        uint256 minimumUSD = 50 * 10**18; //the minimum in usd is 50$ nut converted in wei raise it to the 18th
        //with require, if a certain condition is not met, we'll stop executing and we are going to revert the transaction.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "you need to spend more ETH!"
        );

        //msg.sender and msg.value are keywords in every transaction
        //here we are adding the amount funded to anything that was funded before. (if any)
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //modifier: is used to change the hebavior of a function in a declarative way.
    // you can include this in a function and it will run the function only if require is true

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // the rest of the function is ran after "_;"
    }

    function withdraw() public payable onlyOwner {
        //transfer is a function we can call to send 1 eth from one address to an other!
        //"this" -> refers to the contract you are currently on
        //address(this), means we want the address of the contrac we are currently in!
        //with the ".balance" you can see the balance in ether of the contract.
        //the "msg.sender" is whoever called the function
        payable(msg.sender).transfer(address(this).balance);

        //reset everyones balance to zero.
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        //reset fundres array to a new blanck array
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        ); //we have a contract with address xx which has the functions and we can interact with them becouse we have imported the interface
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        //Tuple is an objext of potencially different types whose number is a constant at comple-time!
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //leave empty all the variable returned that you will not be using!
        //becase answer is an int, you need to typecast it a.k.a. convert to uint256
        return uint256(answer * 10000000000); //return the price in 18 decimal places
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        //the eth price is expressed in wei which is has 18 more zeros
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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