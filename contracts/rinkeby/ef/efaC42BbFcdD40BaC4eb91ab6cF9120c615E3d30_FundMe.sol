/**
 *Submitted for verification at Etherscan.io on 2021-10-04
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

// Part: smartcontractkit/[email protected]/SafeMathChainlink

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

// File: FundMe.sol

contract FundMe {
    // allaw us to do math operations using +-/
    using SafeMathChainlink for uint256;

    // maps the address to the value
    mapping(address => uint256) public addressToAmountFunded;
    // lists all the funders in this contract
    address[] public funders;
    // list the owner address
    address public owner;

    // this constructor stablish the owner (us) of this contract instantly when deployed
    constructor() public {
        // the sender is the owner of the address
        owner = msg.sender;
    }

    // function to create a payable event
    function fund() public payable {
        // min amount is $50 in this eg. we need to multiply by *10 n raised to the **18 so everythin has 18 decimals
        uint256 minimumUSD = 50 * 10**18;
        // the require statements works similar to the "if" statement - checks if the argument if true, if so then it continues
        // the below line says if we were not sent enought eth, we will stop here. Then revert the TX
        // "msg.value" == the amount of eth being sent by the "msg.sender" == owner of address
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // this line updates the funds added by the funders
        addressToAmountFunded[msg.sender] += msg.value;
        // this line appends the funders to the funders empty list so we can iterate
        funders.push(msg.sender);
    }

    // interacting with the interface of the contracts
    function getVersion() public view returns (uint256) {
        // the below lines is saying that we have a interface living in this contrct address "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //vv "priceFeed" is the variable that will call the version vv
        return priceFeed.version();
    }

    // the function below calls the price data using the interface from the contract
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // the latestRoundData will return 5 params the "," is to ignore the params we dont need.
        // latestRoundData will return the following data:
        //> function latestRoundData() {
        //>     uint256 roundId,
        //>     int256 answer, <- this is the price
        //>     uint256 startedAt,
        //>     uint256 updatedAt,
        //>     uint80 answeredInRound };

        // in this live we are only using the "int256 answer" param
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // the "answer" data is in type "int256", but the function is calling for a type "uint256" - then use "type casting" uint256(answer)
        // the "answer" will return the price + 8 additional decimals, to convert it to "Wei" standar it has to return 18 decimals after price.
        return uint256(answer * 10000000000);
    }

    // this function wil convert the amount to USD DOLLARS
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // this like will call the above function and assign it to "ethPrice" var
        uint256 ethPrice = getPrice();
        // this line will convert any valu they sent to USD | eg. this was the amount sent: 1000000000
        // since the value will return with 18 decimals places we devided by 18 decimals places to get the USD amount
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // modifier (keyword) == are used to changed the behavior of a function in declarative way.
    modifier onlyOwner() {
        require(msg.sender == owner);
        // the "_" underscore is to let tell the modifier to run rest of the code after the require stattement is satisfied
        _;
    }

    // this function allows to withdraw our funds from the contract
    // onlyOwner can withdraw
    function withdraw() public payable onlyOwner {
        // "transfer" is a function that we can call on any address to send eth from 1 address to another
        // msg.sender == owner | "this" == keyword in solidity, it refes to the contract that you're currently in | "balace" == entire amount on that address\contract
        msg.sender.transfer(address(this).balance);
        // this lines resets everything to 0 when we withdraw all the balance
        // this reset every one in that mapping to 0 | source: https://www.youtube.com/watch?v=M576WGiDBdQ&t=12008s  timestamp: 3:19:00
        // we set the funderIndex to start from 0, and then the loop will finish when the funderIndex is greater or equal to the amount of funders.
        // "funderIndex++" will add an index after every sinle loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // this line resets the funders array after all the fundersindex is reseted
        funders = new address[](0);
    }
}