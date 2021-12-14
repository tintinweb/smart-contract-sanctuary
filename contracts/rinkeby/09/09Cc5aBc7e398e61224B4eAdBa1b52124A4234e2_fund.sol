// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";



contract fund {
    
    mapping(address => uint256) public fundMap;
    address public owner;
    address[] public addresses;

    constructor() public {
        owner = msg.sender;
    }

    modifier ownerAuth() {
        require (owner == msg.sender);
        _;
    }

    function fundMe() public payable {
        uint256 minUSD = 1 * 10 ** 17;  // Add 17 decimals to $1 to compare with current convertETHToUSD units for Gwei
        // min $1

        // Convert wei to gwei
        uint256 gweiValue = msg.value / 1000000000;
        require(convertETHToUSD(gweiValue) >= minUSD, "Give at least 1 buck");
        fundMap[msg.sender] += gweiValue;

        for(uint256 add=0; add<addresses.length; add++) {
            if(msg.sender == addresses[add]) {
                return;
            }
        }
        addresses.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256) {
        return AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331).version();     //  Kovan testNet
    }
    
    // USD price * 10 ** 8: if ETH price = $4129.52488772 then output will be: 412952488772.
    function getPrice() public view returns (uint256) {
        (, int256 answer,,,) = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331).latestRoundData();
        return uint256(answer);
    }
    
    // Input in Gwei (= ETH * 10 ** 9). Output USD price * 10 ** 17 (for 1 Gwei: 412952488772 when ETH = $4129.52488772)
    function convertETHToUSD(uint256 gwei) public view returns (uint256) {
        uint256 price = getPrice(); // from price * 10 ** 8 to price * 10 ** 17 (Gwei)
        return price * gwei;
    }

    function withdrawMoney() payable ownerAuth public {
        msg.sender.transfer(address(this).balance);

        for(uint256 add=0; add<addresses.length; add++) {
            fundMap[addresses[add]] = 0;
        }

        addresses = new address[](0);
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