/**
 *Submitted for verification at Etherscan.io on 2021-12-21
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
    address owner;
    mapping(address => uint) contributions;
    address[] contributors;
    uint public minimumDonationUsd = 1;
    uint minimumDonationUsdDecimals = 0;

    // Rinkeby Chainlink Price Feed Addressee
    address ethFeedAddr = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

    constructor() public {
        owner = msg.sender;
    }

    function getEthPrice() public view returns(uint priceUsd, uint decimals) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ethFeedAddr);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        uint _decimals = priceFeed.decimals();
        return (
            uint(answer),
            _decimals
        );
    }

//    function getEthPrice() public pure returns(uint priceUsd, uint decimals) {
//        return (420000000000, 8);
//    }

    function getCurrentWeiPerUsd() public view returns(uint weiPerUsd) {
        uint weiPerEth = 10**18;
        // ans = (usd/eth)*10**decimals
        (uint ans, uint decimals) = getEthPrice();
        // wei/usd = wei/eth * 10**decimals * (1 / ((usd/eth)*10*decimals))
        uint currentWeiPerUsd = weiPerEth * (10**decimals) / ans;
        return currentWeiPerUsd;
    }

    function convertUsdToWei(uint usd, uint decimals) public view returns(uint gwei) {
        return usd * getCurrentWeiPerUsd() / (10 ** decimals);
    }

    function donate() public payable {
        require(
            msg.value > convertUsdToWei(minimumDonationUsd, minimumDonationUsdDecimals),
            "must meet minimumDonationUsd"
        );
        contributions[msg.sender] += msg.value;
        bool alreadyContributed = false;
        for (uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == msg.sender) {
                alreadyContributed = true;
            }
        }
        if (!alreadyContributed) {
            contributors.push(msg.sender);
        }
    }

    function showContributors() public view returns(address[] memory contributorAddresses) {
        return contributors;
    }

    function showContributionUsd(address contributorAddress) public view returns(uint contributionUsd) {
        uint _contributionWei = contributions[contributorAddress];
        uint _contributionUsd = _contributionWei / getCurrentWeiPerUsd();
        return _contributionUsd;
    }

    modifier ownerOnly {
        require(
            msg.sender == owner,
            "Only the contract owner may call this function"
        );
        _;
    }

    function withdrawFunds() public payable ownerOnly {
        msg.sender.transfer(address(this).balance);
    }
}