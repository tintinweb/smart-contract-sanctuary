// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// import chainlink code from (NPM/Github) to implement data feed in this contract
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    // create new mapping between addresses and value
    mapping(address => uint256) public addressToAmountFunded;

    // create funder's array addresses that way we can loop through them and reset everyone's balance to 0
    address[] public funders;

    address public owner;

    // create a constructor. whatever we add in constr block of code it will execute immediatley whenever we deploy crt
    constructor() public {
        owner = msg.sender;
    }

    //  create payable function
    function fund() public payable {
        // Set a threshold in terms of USD (Exp:$50. whatever amount that the users send should be >= $50)
        uint256 minimumUSD = 50 * 10**18; // converted to wei
        // second arg in require is revert error msg
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        // keep track all addresses that send us value (money)
        addressToAmountFunded[msg.sender] += msg.value;

        // append users that fund this contract into funders array
        funders.push(msg.sender);
    }

    // let's create a function that call a version() funct in AggregatorV3Interface
    function getVersion() public view returns (uint256) {
        // since we define a struct. Here we define & initialize priceFeed variable of type AggregatorV3Interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    // create a function that call a price
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // because latestRoundData() return a tuple of (5 values). and we remove unused variables
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // typecasting from int256 to uint 256 for answer. (casting in solid as the python)
        return uint256(answer);
    }

    // create function that convert value that they send to its USD equivalent  (exp 1000000000 wei)
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmoutInUsd = (ethPrice * ethAmount) / 100000000;
        return ethAmoutInUsd;
    }

    // create a modifier
    modifier onlyOwner {
        // but we want only the owner of contract that be able to withdraw money. by(require msg.sender = owner)
        // So we define owner in top and assigned in constructor
        require(msg.sender == owner);
        _; // run the rest of the code
    }

    // create withdraw function to get back money sended by users in fund fonction
    // withdraw() be a payable funct because we're going transferring ETH
    function withdraw() public payable onlyOwner {
        // we call transfer() funct to sends "all" (using "balance") ETH in (this) "contract" to msg.sender
        payable(owner).transfer(address(this).balance);

        // when we withdraw everything we're going to reset everyone's balance to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // we should to reset a funders array as well by creating a new blank address array
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