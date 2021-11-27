//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

//Creating a contract or functional class that can accept payemnts
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public AddressToAmountFunded;

    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        //To check amount sent and to check if the amount is greater than
        //a minimum amount
        //First we need a ETH to USD conversion RATE adn a tool for it
        //After we set up the getPrice function lets set the minimum price to 50$
        uint256 minimumAmount = 400 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumAmount,
            "You need to send more ETH"
        );

        AddressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //What do we do with the funds we recieved
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not authorized to withdraw funds!!"
        );
        _;
    }

    //Modifier will check if the address asking for withdrawl is the rightful owner
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            AddressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    //
    //
    ///
    //
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //the below function will returns 5 data points and to accept
        //such data we will create a tuple
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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