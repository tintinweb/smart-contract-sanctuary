// SPDX-Lisence-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    // addressToAmountFunded is a mapping variable that maps address variable to uint256
    // or take it as a dictionary where address variable is the key
    mapping(address => uint256) public addressToAmountFunded;
    // funders is an array of address
    address[] public funders;
    // owner is an public address variable
    address public owner;

    // everything in constructor will be executed first when the contract is deployed
    constructor() public {
        // owner is the sender of this message, which in contructor is the one who deploys the contract
        owner = msg.sender;
    }

    // payable is the type of function that can execute transactions
    function fund() public payable {
        uint256 mimimumUSD = 50 * 10**18;
        // if the requirement cannot be met, the process stops, the transaction reverts, the message returns
        // when we use this fund function, the getConversionRate function embedded will be execute automatically
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "You need to spend more ETH!"
        );
        // store the sent value to addressToAmountFunded that the key is the sender address and the value is the cumulative sent value
        addressToAmountFunded[msg.sender] += msg.value;
        // add sender's addresss to the address array funders
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // the priceFeed is an interface referred to the target address interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // here we use a function in that interface
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // for those functions that return multiple variables, we can use comma to omit those we don't need
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // we use getPrice function we created earlier to get the recent ETH price from chainlink
        uint256 ethPrice = getPrice();
        // we calculate the total dollar value of the input ETH
        uint256 ethAmountInUse = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUse;
    }

    // function directConversion () public view returns (uint256){
    //     uint256 ethPrice = getPrice();
    //     uint256 ethAmountInUse = (ethPrice * addressToAmountFunded(msg.sender) / 1000000000000000000);
    //     return ethAmountInUse;
    // }

    // A modifier is used to change the behavior of a function in a declarative way
    modifier onlyOwner() {
        // in this modifier, we require the msg sender is the owner of the conctract
        require(msg.sender == owner);
        // this means we run the modifier first and then the function in that functions
        // here it means if the executor of the function isn't the owner of the contract, the function won't be executed
        _;
    }

    // withdraw is a payable function and it has modifier onlyOwner to modify its execution
    function withdraw() public payable onlyOwner {
        // all the balance of this contract will be transferred to the executor of this function
        // this is a keyword which means exactly the contract the function is in
        // balance is used to check the balance of a contract
        msg.sender.transfer(address(this).balance);

        // for uint256 variable funderIndex, it starts with 0 in this loop
        // if the funderIndex is smaller than the length address array funders, add 1 to it
        // when it exceeds the length of funders, stops the loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // in every execution of the loop, address variable funder is an address in that address array
            address funder = funders[funderIndex];
            // before the change, the mapping variable addressToAmountFunded stored the cumulative value
            // but because we withdraw all the toekns from this contract, we change the number to 0
            // be aware that this isn't the balance of the whole conctract, but the balance sent by each contributor
            addressToAmountFunded[funder] = 0;
        }

        // after we change all those balance, we clear all the address in that arry by creating a new empty address array
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