// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address => uint256) public amountToAddress;
    address public owner;
    address[] funders;
    AggregatorV3Interface public priceFeed;


    constructor(address _priceFeedAddress){
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        owner = msg.sender;
    }

    function fund() public payable {
      
        //here  10**18 means 10^18
        // we multiply $50 by 10^18 to convert into wei. We deal with Wei becuase solidity does not support decimals.
        uint256 minimumAmt = 50 * 10**18;
        /*
        We can use if statement like this or require as below
        if(msg.value < minimumAmt){
            revert?
        } */

        //if getConversionRate(msg.value) >= minimumAmt fails it will not execute the transaction. It will show the given message
        require(getConversionRate(msg.value) >= minimumAmt, "$50 worth of ETH required for this transaction!");
        amountToAddress[msg.sender] += msg.value;
        funders.push(msg.sender);
         
    }

//This is one way of adding the widhdrawal limitation for owner
/* 
    function widthdraw() public payable{
        require(msg.sender == owner,"You are not authorized to widthdraw!");
        payable(msg.sender).transfer(address(this).balance);
    }
*/

    //Second way is to use modifiers
    modifier onlyOwner{
        require(msg.sender == owner,"You are not authorized to widthdraw!");
        _;
    }

    function widthdraw() public onlyOwner payable{
        require(msg.sender == owner,"You are not authorized to widthdraw!");
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            amountToAddress[funder] = 0;
        }
            funders = new address[](0);
    }

    function getPrice() public view  returns(uint256){
        //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e - got this address from https://docs.chain.link/docs/ethereum-addresses/ - Rinkeby Test net
        /*
        Few things about Smart Contracts
        Each smart contracts has an address. 
        Eg - 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        Above is an address for a smart contracts which provides the price feeds ETH/USD in the Rinkeby test net
        So if we deploy our own smart contract it will have its own address as well. That is how they interact with each other, using addresses!

        There are other test network like Rinkeby. for an eg Koven is another test net

        In the Remix ENVIRONMENT 
            JavaScript VM - a private virtual machine
            Injected Web3 - It can be a test net or main net. Depends with your Meta Mask account selection. If it set to Rinkeby then this means we are 
            deploying this to the Rinkeby test net
            Web3 Provider - means your own private node
        */

        //https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
        //AggregatorV3Interface - this is an interface. its functionality is similar to other languages. You can extract functions and call them. 
        //here the  0x8A753747A1Fa494EC906cE90E9f37563A8AF630e is an address of a smart contract which implements the AggregatorV3Interface interface.
        //So we are basically creating an instance of that smart contract and calling it.

       // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (, int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); //converting to Wei
    }

//no idea about this conversion. need to check again
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethprice = getPrice();
        uint256 ethAmountInUsd = (ethprice * ethAmount)/1000000000000000000;
        return ethAmountInUsd;
    }

     function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 51 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
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