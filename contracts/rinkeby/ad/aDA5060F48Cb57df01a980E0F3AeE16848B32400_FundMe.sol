/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: fund_me.sol

//we use an interface (template) so that we don't have to individually import each price feed. instead, since they all follow this pattern, we call the interface, and specify the address to see the specific numbers they hold.
//this exact link is provided by chainlink and they specify they type of interface to use for different purposes

contract FundMe {
    mapping(address => uint256) public addressAmounts;
    address public owner;
    address[] funders;

    constructor() {
        //constructor is a function that gets executed once immediately when the contract is deployed. We will use it to set ourselved as the owner of this contract.
        owner = msg.sender;
    }

    modifier onlyOwner() {
        //it seems like checking that sender is owner may be a common thing in our functions... so what we can do is define a modifier. A modifier is a keyword that creates parameters that modifiy the function where it gets implemented.
        require(msg.sender == owner, "You are not the owner");
        _; //this underscore represents the body of the function that this modifier is used on.
    }

    function fund() public payable {
        //payable keyword means u can use this function to pay for things. it can also apply to addresses
        uint256 minimumUSD = 50 * 10**17;
        require(
            priceOfnGwei(msg.value) >= minimumUSD,
            "Minimum required amount is 50 USD"
        ); //require keyword (condition, message if not met), acts like a gate... also refunds gas. another one is revert, which will undo all state changes, and also returns gas. you can imagine using revert in an if statement
        addressAmounts[msg.sender] = msg.value; //msg.sender is a keyword that shows the address of the person calling this function, and msg.value is a keyword that shows how much they sent in gwei
        funders.push(msg.sender);
    }

    function priceOfOneGwei() public view returns (uint256) {
        AggregatorV3Interface prices = AggregatorV3Interface(
            address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
        ); //casting address to type aggregatorv3interface... anyway this whole thing is like a struct, u need this address to behave like this av3i in order to call the members that are in it... in this case the functions
        (, int256 answer, , , ) = prices.latestRoundData(); //the first thing is called a tuple, it's like a list, but immutable, meaning u can't go back and change what sits in each index.
        return uint256(answer); //we also chose to leave out all the values we considered unnecessary by leaving the slots of the tuple blank
        //actual price of 1 gwei is answer/10**17, because returned answer is price of eth with 8 decimals, so divide by 10**8 and then 10**9 for gwei
    }

    function numOfDecimals() public view returns (uint8) {
        AggregatorV3Interface decimals = AggregatorV3Interface(
            address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
        );
        return decimals.decimals();
    }

    function priceOfnGwei(uint256 numberofgwei) public view returns (uint256) {
        return (priceOfOneGwei() * numberofgwei);
        //again, this divided by 10**17. since we only do int we can't show decimals.
    }

    function withdraw(address payable someAddress) public payable onlyOwner {
        //only want the owner of this contract to be able to call this function
        someAddress.transfer(address(this).balance); //.transfer is a function that transfers specified amount. address.this refers to the address of the contract we are in and .balance refers to all the money in this address.
        //we might also want to reset our mapping after we withdraw.
        for (
            uint256 fundersIndex;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressAmounts[funder] = 0;
        }
        delete funders; //deletes all members of the array funders
    }
}