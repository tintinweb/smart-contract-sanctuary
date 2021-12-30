// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;




// Brownie can't import from NPM packages but can from Github

//import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

// Interfaces compile down to ABI Application Binary Interface:
// What functions can we use and what function can we call other contracts with
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

contract FundMe { 
    
    // using A for B => attaching library functions from A to a type B
    using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded;
    // There is no easy way to iterate through a map, the we create an array
    address[] public funders;



    address public owner;

    constructor() public {
        owner = msg.sender; // So that the person that deploys it is the owner
    }
    
    // The quilifyer "payable" indicates that the function can be used to
    // To pay for things. The quantity can be specified via the "value" of
    // The transaction. All this info is in the keyword msg.


    
    // Example 50$ minimum fund
    function fund() public payable {
        uint256 minumumUsd = 50 * 10**18;
        
        // This operates the same as if(not enough) revert with message ""
        require(getConversionRate(msg.value) >= minumumUsd, "You need to spend more ETH");
        
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
        
        // Let's set a minmum value. But in USD what is the equivalent?
        // We need an oracle, we will use Chainlink. Centralized Oracles
        // Can ruin all decentrality of all the network.
        
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _; // Mandatory

    }
    // A modifier modifies a certain property of a function
    function withdraw() payable onlyOwner public {
        // Needs to be limited so that only the owner can withdraw funds
        //require(msg.sender == owner);
        msg.sender.transfer(address(this).balance); // address(this) = address of contract 
        for(uint256 i = 0; i < funders.length; ++i) {
          addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
    
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        
        // The return must be divided by 10^8, 3rd version in wei 10^18 decimals
        return uint256(answer*10000000000);
        
    }
    
    function getConversionRate(uint256 _weiAmmount) public view returns(uint256) {
        uint256 weiPrice = getPrice(); // (ETH/USD)*10^18
        uint256 totalUsd = (weiPrice*_weiAmmount); // In wei
        return totalUsd/1000000000000000000;
        // Usd returned in 18 deciamls! 
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}