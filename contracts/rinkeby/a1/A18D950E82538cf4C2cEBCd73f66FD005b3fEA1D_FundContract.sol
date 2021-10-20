// SPDX-License_Identifier: MIT
pragma solidity ^0.6.0;

// Imports are stored as NPM Packages
// A Library is deployed only once at a specific Address and their Code is reused
// Interfaces are compiled down to an ABI
// The ABI tells Solidity and other Programming Languages how it can interact with another Smart Contract
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundContract {
    // Using Keyword: using A for B
    // Keyword "using" can be used to attach Library Functions (from the Library A) to any Type (B) in the Context of a Smart Contract
    // Using the Library SafeMathChainlink for all Variables of Type unit256 - prevent Overflow during arithmetic Operations
    // using SafeMathChainLink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // A Modifier is sued to change the Behavior of a Function in a declarative Manner

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner of Smart Contract can use this Operation");
        // This Modifier will be checked before the Function is executed
        _;
    }

    modifier postFunctionModifier {
        // This Modifier will be checked after the Function is executed
        _;
        require(msg.sender == owner, "Only Owner of Smart Contract can use this Operation");
    }

    // Constructor is instantly invoked when the Smart Contact is deployed
    constructor() public {
        owner = msg.sender;
    }

    function fundContract() public payable {
        uint256 minimumUsd = 42 * 1 ether;
        // If Transaction is reverted the User get his Value and Parts of the unused Gas back
        require(getConversionRate(msg.value) >= minimumUsd, "At least 42USD are necessary");
        // msg.sender: Sender of the Transaction
        // msg.value: Value that was sent by Transaction
        addressToAmountFunded[msg.sender] += msg.value;
        // Push every Funder to the Funders-Array - so there is an Overview of all Funders - Funders can be redundant
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // Address from Price Feed Contract in Chainlink Docs: https://docs.chain.link/docs/ethereum-addresses/
        // Calling the Price Feed Smart Contract with it Address on the Network Kovan
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        // Calling another Contract from Chainlink to get the Aggregator Version
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // Address from Price Feed Contract in Chainlink Docs: https://docs.chain.link/docs/ethereum-addresses/
        // Calling the Price Feed Smart Contract with it Address on the Network Kovan
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        // Calling another Contract from Chainlink - it returns the following Tuple: (roundId, answer, startedAt, updatedAt,answeredInRound)
        // Tuple: A List of Objects of potentially different Types whose Number is a Constant at Compile-Time
        // Calling another Contract from Chainlink to get the Price feed for ETH / USD
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // Type Casting from int256 to uint256
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1 ether;
        return ethAmountInUsd;
    }

    function withdrawFunds() payable onlyOwner public {
        // Transferring all Balances of Smart Contract to msg.sender
        // Keyword "this": points to the current Smart Contract
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            // Resetting all funded Amount in Smart Contract after the Withdraw happened
            addressToAmountFunded[funder] = 0;
        }
        // Resetting all Funders
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