//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "AggregatorV3Interface.sol";

/* interface AggregatorV3Interface {
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
} */

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    address chainlinkaddress = 0x0715A7794a1dc8e42615F059dD6e406A6594651A; // ETH/USD Polygon Mumbai

    address owner;

    address[] funders;

    constructor() {
        owner = msg.sender;
    }

    function whos() public view returns (address) {
        return owner;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(conversion(msg.value) >= minimumUSD, "insufficient Fund");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getDecimals() public view returns (uint8) {
        return AggregatorV3Interface(chainlinkaddress).decimals();
    }

    function getDescription() public view returns (string memory) {
        return AggregatorV3Interface(chainlinkaddress).description();
    }

    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).version;
        //return priceFeed.version();
        //or
        return AggregatorV3Interface(chainlinkaddress).version();
    }

    function getLatestRoundData()
        public
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return AggregatorV3Interface(chainlinkaddress).latestRoundData();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(chainlinkaddress)
            .latestRoundData();
        return uint256(answer * 10000000000);
    }

    function conversion(uint256 _amount) public view returns (uint256) {
        uint256 converted = (getPrice() * _amount) * 1000000000000000000;
        return converted;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++)
            addressToAmountFunded[funders[i]] = 0;
        funders = new address[](0);
    }

    modifier onlyOwner() {
        //require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,"nop");
        //directly write address or
        // revert
        //if(msg.sender != owner){
        //  revert("only owner");
        //}
        // assert using gas!!
        //assert(msg.sender == owner);
        //require best way instead of revert(need if else statement) - assert(gas cost)
        require(msg.sender == owner, "only owner");
        _; // necessary bottom or top of the modifier
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