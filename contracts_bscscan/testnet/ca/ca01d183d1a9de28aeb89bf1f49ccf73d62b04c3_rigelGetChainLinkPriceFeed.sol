/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

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
    
    function latestAnswer()
        external
        view
        returns (
          int256
        );

}

library SafeMathChainlink {

  function mul(uint256 a, uint256 b) internal pure returns (
      uint256
    )
  {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract rigelGetChainLinkPriceFeed is Context {
    // using SafeMathChainlink for uint256;
    
    address public owner;
    
    struct allAggregators {
        AggregatorV3Interface priceFeed ;
        uint256 decimals;
    }
    
    mapping(address => bool) public isAdminAddress;
    
    allAggregators[] getAggregator;
    
    constructor(address _aggregator, uint256 _decimal) public {
        owner = _msgSender();
        isAdminAddress[_msgSender()] = true;
        
        getAggregator.push(allAggregators({
            priceFeed: AggregatorV3Interface(_aggregator),
            decimals: _decimal
        }));
    }
    
    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"RGP: YOU ARE NOT THE OWNER.");
        _;
    }
    
    // only allow admin addresses to do specific
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()]);
        _;
    }
    
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            } 
        }
    }
    
    function addMulAggregator(address[] memory _aggregators) public onlyAdmin {
        // require(_aggregators.length == _decimal.length, "kindly verify that equal input data");
      for(uint256 i = 0; i < _aggregators.length; i++) {
            getAggregator.push(allAggregators({
                priceFeed: AggregatorV3Interface(i),
                decimals: 8 * 10**8
            }));
        }
    }
    
    function getLatestPrice(uint256 _aggregatorID) public view returns (int) {
         allAggregators storage refAggregator = getAggregator[_aggregatorID];
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = refAggregator.priceFeed.latestRoundData();
        return price;
    }
    
    function getAggLenght() external view returns (uint256) {
        return getAggregator.length;
    }
}