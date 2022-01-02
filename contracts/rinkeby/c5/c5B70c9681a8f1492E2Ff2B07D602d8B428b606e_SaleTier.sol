// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract SaleTier {
    //since deploying on matic test net
    //currency is matic but assuming it as eth

    //tier details
    // Tier A -  50 - 100 USD
    // Tier B - 100+ USD

    mapping(address => uint256) public donorToAmount;
    mapping(address => uint8) public donorToTier;
    address[] public donors;
    address public owner;

    AggregatorV3Interface linkEthToUsdContract;

    constructor(address _address) {
        owner = msg.sender;
        linkEthToUsdContract = AggregatorV3Interface(_address);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Function restricted to owner!");
        _;
    }

    function fund() public payable {
        if (donorToAmount[msg.sender] == 0 && msg.value > 0) {
            donors.push(msg.sender);
        }

        donorToAmount[msg.sender] += msg.value;
        uint256 donationWorth = getDonationWorth(donorToAmount[msg.sender]);

        if (donationWorth > 100) {
            setTier(2);
            return;
        }
        if (donationWorth >= 50) {
            setTier(1);
            return;
        }
    }

    function getDonationWorth(uint256 _weiAmount)
        public
        view
        returns (uint256)
    {
        //returns integer of usd value
        return (getEthPrice() * _weiAmount) / 10**36;
    }

    //configured for mumbai testnet
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = linkEthToUsdContract.latestRoundData();
        uint8 decimals = linkEthToUsdContract.decimals();

        //returning with 18 decimal places
        if (decimals <= 18) {
            return uint256(price) * (10**(18 - decimals));
        }
        return uint256(price) / 10**(decimals - 18);
    }

    function setTier(uint8 _tierType) internal {
        donorToTier[msg.sender] = _tierType;
    }

    function knowTier(address _address) public view returns (uint8) {
        return donorToTier[_address];
    }

    function withdraw() public onlyOwner {
        address payable receiver = payable(owner);
        receiver.transfer(address(this).balance);
    }

    function reset() public onlyOwner {
        for (uint256 i = 0; i < donors.length; i++) {
            address donor = donors[i];
            donorToAmount[donor] = 0;
            donorToTier[donor] = 0;
        }
        delete donors;
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