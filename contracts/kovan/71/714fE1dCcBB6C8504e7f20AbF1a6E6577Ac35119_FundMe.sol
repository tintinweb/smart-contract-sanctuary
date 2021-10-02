/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

//interfaces compile down to an ABI
//ABI = Application BInary Interface tells solidity and other programming languages how it can interact
//with another contract

//Anytime you want to interact with an already deployed smart contract you woll need an ABI

contract FundMe {
    //red button payable function-> receive sendings
    //msg.sender address of sender keyword
    //msg.value value of payment
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    //constructor writes owner to owner variable and makes ti possible for the deployer of this contract, to withdraw
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        //$50
        uint256 minimumUSD = 50 * 10**18; // 18 decimals everything
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        ); //revert money back
        addressToAmountFunded[msg.sender] += msg.value;
        //what the ETH -> USD conversion rate
        funders.push(msg.sender); //save the address of funder
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        //Koven/ rinkeby-testnet smartcontract https://docs.chain.link/docs/ethereum-addresses/
        return priceFeed.version();
    }

    //https://eth-converter.com/
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (
            ,
            //uint80 roundId,
            int256 answer, //uint256 startedAt, //uint256 updatedAt,
            ,
            ,

        ) = //uint80 answeredInRound
            priceFeed.latestRoundData();
        return uint256(answer * 10**10); //292851295371 * 10 **10 = 18 stellen//   Wei 1000000000000000000(18)  Gwei 1000000000(9)  Ether 1
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUsd; // returns 2928512953710 for 1 eth in Gwei = 1000000000||   0.000002928512953710 1 Gewi in USD  X 1000000000 (1eth-gewei) = USD price
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // run require first, then add the rest of the funtion here
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance); // balance of this contract is transferedt to the caller of this msg.sender
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // delete amount of funders
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // clear array
    }
}