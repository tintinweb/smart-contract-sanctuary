/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundStore.sol

contract FundStore {

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => bool) public whitelistedAddress;
    address[] public funders;
    address public owner;
    uint256 public hardCap;
    bool public whitelistEnabled = false;
    bool public depositEnabled = true;

    AggregatorV3Interface public priceFeed;


    modifier onlyOwner {
        require(msg.sender == owner, "Only owner has access to this");
        _;
    }

    constructor() public {
        owner = msg.sender;
        
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }


    // Changing the owner
    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }


    // Setting hard cap
    function setHardCap(uint256 amount) onlyOwner external {
        hardCap = amount;
    }


    // Enabling and disabling depositing
    function enableDeposit() onlyOwner external {
        depositEnabled = true;
    }

    function disableDeposit() onlyOwner external {
        depositEnabled = false;
    }


    // Enabling and disabling whitelist feature
    function enableWhitelist() onlyOwner external {
        whitelistEnabled = true;
    }


    function disableWhitelist() onlyOwner external {
        whitelistEnabled = false;
    }


    // Whitelisting addresses
    function addToWhitelist(address funder) onlyOwner external {
        whitelistedAddress[funder] = true;
    }

    function removeFromWhitelist(address funder) onlyOwner external {
        whitelistedAddress[funder] = false;
    }

    function isWhitelisted(address funder) public view returns (bool) {
        return whitelistedAddress[funder];
    }


    // Funders
    function numberOfFunders() public view returns (uint256){
        return funders.length;
    }

    function funderAtIndex(uint256 index) public view returns (address){
        return funders[index];
    }

    function funderTotalDeposit(address funder) public view returns (uint256){
        return addressToAmountFunded[funder];
    }


    // Funding
    function fund() public payable {
        require(depositEnabled, "Deposits disabled");
        require((!whitelistEnabled) || (whitelistedAddress[msg.sender]), "Sender not whitelisted");
        require((hardCap == 0) || (address(this).balance - msg.value < hardCap), "Hardcap met");

        if (hardCap != 0 && (address(this).balance > hardCap)) {
            payable(msg.sender).transfer(address(this).balance - hardCap);
        }

        if (addressToAmountFunded[msg.sender] == 0) {
            funders.push(msg.sender);
        }

        addressToAmountFunded[msg.sender] += msg.value;
    }

    // directly send without explicit function call
    receive() external payable
    {
        fund();
    }


    // Withdrawing
    function withdraw(uint256 amount) onlyOwner external {
        payable(owner).transfer(amount);
    }
}