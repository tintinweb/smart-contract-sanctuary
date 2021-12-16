// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "AggregatorV3Interface.sol";

contract FundMe {
    address owner;
    uint256 public minimumUSDToFund = 50 * (10**8);
    address AddressETHUSD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    // any public property will be seen when interacting with the contract (blue buttons on remix)
    mapping(address => uint256) public addressToAmountFundend;
    address[] public funders;

    // It's executed on deploy
    constructor() {
        // whoever deploys the contract
        owner = msg.sender;
    }

    // modifiers work kind of like imports. The _; signal where the code of the function
    // using it will be inserted (when will be executed)
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // pure methods are for mathematical expressions
    function toGwei(uint256 number) internal pure returns (uint256) {
        return number * 10000000000;
    }

    // Payable methods allow to send assets to the contract
    function fund() public payable {
        // it checks the truthness of an expression and revert execution if false
        require(
            getConversionRate(msg.value) >= minimumUSDToFund,
            "Minimum USD amount to fund is 50"
        );

        addressToAmountFundend[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // view methods are read-only and don't register a tx (don't make any state changes)
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(AddressETHUSD);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(AddressETHUSD);
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return toGwei(uint256(answer));
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / (10**18);
        return ethAmountInUsd;
    }

    // function using theh onlyOwner modifier. payable is used any time you're moving funds
    function withdraw() public payable onlyOwner {
        // you can call transfer() on any payable address (or transform it first with payable()
        // balance returns all the money of an address (in this case, contract's address
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFundend[funder] = 0;
        }
        funders = new address[](0);
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