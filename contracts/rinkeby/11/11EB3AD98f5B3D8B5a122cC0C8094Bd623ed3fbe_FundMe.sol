/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //  Constructor.

    constructor(address _priceFeed) public {
        //  Set the owner of this contract.
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        uint256 minUSD = 31 * 10**18;
        require(
            getConversionRate(msg.value) >= minUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function anonofund() public payable {}

    function getBalance() public view returns (uint256) {
        return (address(this).balance);
    }

    function getVersion() public view returns (uint256) {
        return (priceFeed.version());
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return (uint256(answer * 10000000000));
    }

    function getConversionRate(uint256 _ethInWei)
        public
        view
        returns (uint256)
    {
        uint256 price = getPrice();
        uint256 ethInUSD = (price * _ethInWei) / 1000000000000000000;
        return (ethInUSD);
        //  31.244086089800000000
    }

    //  Create a function modifier that can be used to set
    //  provide a set of stpes to execute for any function modified by this
    //  modifier.  In this case, we are using the require statement to
    //  make sure only the owner executes this function.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; //   This is a spacial construct that ends up executing the function here.
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmountFunded[funders[funderIndex]] = 0;
        }
    }
}