// SPDX-License-Identifier: MIT 

pragma solidity >=0.6.0 <0.9.0;


import "AggregatorV3Interface.sol";

// Github Link for the interface: 
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

contract FundMe {
    mapping (address => uint256) public addressToAmountFunding;
    address public owner;
    address[] public funders;
    address public aggregatorAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    
    constructor(address _admin) public {
        owner = _admin;
    }
    
    function fund() public payable {
        uint256 minUSD = 50 * 10 ** 18;
        addressToAmountFunding[msg.sender] += msg.value;
        funders.push(msg.sender);
        // What eth to usd convesion rate is ?
        require(getConversionRate(msg.value) >= minUSD, "LESS_FUND");
    }
    
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregatorAddress);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregatorAddress);
        (, int256 answer, , ,) = priceFeed.latestRoundData();
        return uint256(answer * 10 ** 10);
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ethPrice * ethAmount / 10 ** 18;
        return ethAmountInUSD;
    }
    
    function getWeiFromUSD(uint usdValue) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        return usdValue * 10 ** 36 / ethPrice;
    }
    
    function withdrawFund() payable public {
        require(msg.sender == owner, "NOT_OWNER");
        require(address(this).balance > 0, "NOT_ENOUGH_BALANCE");
        for (uint256 i=0; i<funders.length; i++) {
            address funderAddress = funders[i];
            addressToAmountFunding[funderAddress] = 0;
        }
        funders = new address[](0);
        msg.sender.transfer(address(this).balance);
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