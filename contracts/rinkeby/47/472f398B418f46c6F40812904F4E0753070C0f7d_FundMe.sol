//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    // Create a function to transfer funds into the contract
    // The fund should not be less than USD50
    // Create a mapping to hold the amount of fund recieved from each account
    // A constructor to set Owner account
    // A function to withdraw selected amount of the funds into the contract owner account

    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public fundProviders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 maxval;
        if (a > b) {
            maxval = a;
        } else {
            maxval = b;
        }
        return maxval;
    }

    function fund() public payable {
        // This function should be enough to recieve funds
        uint256 minFund = 50 * 10**18;
        require(
            (msg.value * getPriceData()) / 10**28 >= minFund,
            "Below minimum fund! Try with more weis..."
        );
        addressToAmountFunded[msg.sender] += msg.value;
        fundProviders.push(msg.sender);
    }

    function viewMinimumWei() public view returns (uint256) {
        // This function returns the minimum Weis that need to be submitted to participate in the fundme project
        uint256 price = getPriceData();
        uint256 minFund = 50 * 10**18;
        return ((minFund * 10**28) / price);
    }

    function getPriceData() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner is allowed to execute this function! If you are the owner, please use the owner address"
        );
        _;
    }

    function withdrawFundToOwner(uint256 _withdrawbal)
        public
        payable
        onlyOwner
    {
        require(
            _withdrawbal <= getContractBalance(),
            "The contract doesn't have this much balance, try a lower amount"
        );
        payable(msg.sender).transfer(_withdrawbal);
        uint256 deduction = _withdrawbal / fundProviders.length;
        for (uint256 i = 0; i < fundProviders.length; i++) {
            address funder = fundProviders[i];
            uint256 currFunderBalance = addressToAmountFunded[funder];
            addressToAmountFunded[funder] = max(
                0,
                currFunderBalance - deduction
            );
        }
        if (getContractBalance() == 0) {
            fundProviders = new address[](0);
        }
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