// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";


contract FundMe {

    using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10 * 18;

        // better way for if statement, revert if failed.
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        funders.push(msg.sender);
        // 1 gwei < $50

        addressToAmountFunded[msg.sender] += msg.value; 
        // What the ETH -> USD conversion rate
    }

    //
    // Reading the state of the interface
    //
    function getVersion() public view returns (uint256){
        address ethUsd = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ethUsd);
        return priceFeed.version();
    }

    //
    // Get latest round price
    //
    function getPrice() public view returns (uint256){
        address ethUsd = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ethUsd);
        (,int price,,,) = priceFeed.latestRoundData();

        return uint256(price * 10000000000);
        // 4,096.48337478
    }

    // 1000000000 - 1 GWEI
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // 18 zeroes
        return ethAmountInUsd;
        // 0.0000040964833747800
        // 0.00040964833747800

    }

    // middleware
    modifier onlyOwner {
        require(msg.sender == owner, "You shall not pass");
        _;
    }

    function withdraw() payable onlyOwner public { 
        msg.sender.transfer(address(this).balance);
        for (uint256 i=0;i<funders.length;i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // reset
        funders = new address[](0);
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