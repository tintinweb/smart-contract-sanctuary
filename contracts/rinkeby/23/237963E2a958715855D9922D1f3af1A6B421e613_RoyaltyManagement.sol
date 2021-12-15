// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "AggregatorV3Interface.sol";

contract RoyaltyManagement {
    //using SafeMathChainlink for uint256; useless with new solidity version

    // struct SharesOnSale {
    //     address from;
    //     uint8 sharesOnSale;
    //     uint256 sharesPrice;
    // }

    mapping(address => uint8) public addressToPercentage;
    mapping(address => bool) private artistsCheck;
    mapping(address => uint32) public artistsBalance;
    address[] public artists;
    address public owner;
    uint8 public shares;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
        shares = 0;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You have to be the owner of the contract!"
        );
        _;
    }

    modifier onlyArtists() {
        require(
            artistsCheck[msg.sender],
            "You have to be one of the artists involved!"
        );
        _;
    }

    modifier onlyValidBalance() {
        require(artistsBalance[msg.sender] >= 0, "Your balance is 0");
        _;
    }

    modifier sharesAssigned() {
        require(shares == 100, "The sum of the shares is not 100%");
        _;
    }

    function fund() public payable sharesAssigned {
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        for (
            uint8 artistIntex = 0;
            artistIntex < artists.length;
            artistIntex++
        ) {
            address artist = artists[artistIntex];
            artistsBalance[artist] = uint32(
                (msg.value * addressToPercentage[artist]) / 100
            );
        }
        //amount += msg.value;
        //artists.push(msg.sender);
    }

    function addArtist(address artist, uint8 percentage) public onlyOwner {
        addressToPercentage[artist] = percentage;
        artistsCheck[artist] = true;
        artists.push(artist);
    }

    // function sellShares(
    //     address buyer,
    //     uint8 sharesOnSale,
    //     uint256 sharesPrice
    // ) public {
    //     require(
    //         addressToPercentage[msg.sender] >= sharesOnSale,
    //         "You can't offer more shares than you have!"
    //     );

    //     payable(buyer).transfer(sharesPrice);

    //     addressToPercentage[msg.sender] -= sharesOnSale;
    //     addressToPercentage[buyer] += sharesOnSale;
    // }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    function withdraw() public onlyArtists onlyValidBalance {
        //msg.sender.transfer(address(this).balance);

        address artist = msg.sender;
        payable(artist).transfer(artistsBalance[artist]);
        artistsBalance[artist] = 0;
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