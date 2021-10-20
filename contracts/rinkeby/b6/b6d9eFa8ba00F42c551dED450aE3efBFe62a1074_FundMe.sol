// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    // Funders list of addresses
    address[] public funders;

    // Create the owner of the contract.
    address public owner;

    // Constructor is executed once we create the contract
    constructor() public {
        owner = msg.sender; // is equal to msg.sender because we are creating the contract
    }

    function fund() public payable {
        //payable functions can be used for paying

        // Minimum value of $50
        uint256 minimumUSD = 50 * 10**18;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        ); // checks the truth of whatever we put inside , return the msg otherwise

        // msg.sender is the address of the person
        // msg.value is the amount that they send
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender); // add the funder address to the array
    }

    // Function to check the version of the interface (v3)
    function getVersion() public view returns (uint256) {
        // type variableName = initialize the contract(address of the contract (for rinkeby) from chainlink website (USD/ETH conversion)
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    // Function to get the price
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // latestRoundData is one of the functions in the AggregatorV3Interface and we get a tuple as result. We are only interested in the price
        return uint256(price * 10**10); // to transform to wei
    }

    //
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18); // we have to divide in 10^18
        return ethAmountInUsd;
    }

    // Modifiers modify a function. In this case checks that who wants to witdraw is the owner
    modifier onlyOwner() {
        require(msg.sender == owner); // require to be the owner to be able to withdraw
        _; // _; at the end
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance); // this is the contract we are in, with balance we send all the money that is into the contract

        // set to 0 the mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // replace funders array with a new one
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