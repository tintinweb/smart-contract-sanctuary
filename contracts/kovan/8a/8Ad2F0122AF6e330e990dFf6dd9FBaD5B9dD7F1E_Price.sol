pragma solidity >0.6.0;

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available for owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPrice.sol";
import "./Owned.sol";

contract Price is IPrice, Owned {

    /**
     * Network: Binance Smart Chain Testnet
     * Aggregator: BTC/USD
     * Address: 0x5741306c21795FdCBb9b265Ea0255F499DFe515C
     * Decimals: 8
     */
     
    address public lottery;
    
    constructor(address _lottery) public {
        lottery = _lottery;
    }
    
    modifier onlyLottery {
        require(msg.sender == lottery);
        _;
    }
    
    function setLottery(address _lottery) public onlyOwner {
        lottery = _lottery;
    }
    
    function getLastPrice(address _address) public override view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_address);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        string memory description = priceFeed.description();
        return (price,decimals, startedAt, timeStamp, description);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IPrice {
     function getLastPrice(address _address) external view returns (int _price, uint8 _decimals ,uint _startedAt, uint _timeStamp, string memory _description);
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

