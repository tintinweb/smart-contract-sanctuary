// SPDX-License-Identifier: MIT
//-- if you dont have this ,solidity yell you
//At the top this important
//Control + S to Save
pragma solidity ^0.8.0;

//Import from NPM Package
import "AggregatorV3Interface.sol";

//import "AggregatorV3Interface.sol";
contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // if you're following along with the freecodecamp video
    // Please see https://github.com/PatrickAlphaC/fund_me
    // to get the starting solidity contract code, it'll be slightly different than this!
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 mimimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Only callable by the owner
    //Before run withdraw code , then go first onlyOwner
    function withdraw() public payable onlyOwner {
        //Only the owner can get his money
        //if you have ton of contracts, this is awful to write this line here    require(msg.sender == owner);
        //Send one amount to another address
        //To send all the money in the contract
        //msg.sender.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
        //Reset balance to 0, funders balance because you withdraw all your balance
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            /*
			[A,20.3]
			[A,40.2]
			*/
            addressToAmountFunded[funder] = 0;
            //Reset one address to zero
        }
        //new blank array index - why new blank array index,beucause its saved in memory
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