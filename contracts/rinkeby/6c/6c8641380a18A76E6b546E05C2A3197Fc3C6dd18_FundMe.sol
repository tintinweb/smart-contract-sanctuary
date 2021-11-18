//SPDX-License-Identifier: MIT

//define solidity version
pragma solidity ^0.6.0;

//import the chainlink interface from the chainlinks npm package
// Interfaces compile down to an ABI
//ABIs tell solidity and othger programming languages how it can interact with another contract
// Anytime you interact with a smart another contract you need an ABI
import "AggregatorV3Interface.sol";

//Import safeMath from chainlink
import "SafeMathChainlink.sol";

contract FundMe {
    //Use SafeMathChainlink for all math involving uint256 variables in order to avoid overflow.
    using SafeMathChainlink for uint256;

    //create a mapping function so we can track payments
    mapping(address => uint256) public addressToAmountFunded;

    //Create a new array to loop through and set everyones balancer to 0
    address[] public funders;

    // Set the address type to be named owner
    address public owner;

    //Contructors are immediately executed at the start of the creatipono of a contract
    constructor() public {
        //Set the owner of the contract address to msg.sender
        owner = msg.sender;
    }

    //function to acept payment (paybale functions show up as red)
    function fund() public payable {
        //Set the minimum that some can fund the contract with
        uint256 minimumUSD = 50 * 10**18;

        //Use a require statement to make sure that the value of the funds is greater than the minimumUSD
        // if statmeentr is false the user will recieve all their money back and any gas as well
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more to complete your transaction"
        );

        //msg.sender = sender of a function call
        //msg.value = how much the sender sent
        addressToAmountFunded[msg.sender] += msg.value;

        //When a funder funds a contract we push them, to the funders array
        funders.push(msg.sender);
    }

    //Call the interface to check the version of a interface
    function getVersion() public view returns (uint256) {
        //name the type, visability, name
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    //Create a function that calls a price
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        // You can add blanks for any unused variables in the function
        // Original tuple stored 5 variables
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // Convert the price from a int to a uint256
        // Price is in Gwei orininally
        // to convert to Wei multiply by 10 decimal places
        // Will cost more gas to convert to more decimal points
        return uint256(price * 1000000000);
    }

    //Create a convesion  rate for our transaction
    function getConversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 100000000000000000;

        return ethAmountInUsd;
    }

    //modifiers used to change the behavor of funcitons in a declaritive way
    modifier onlyOwner() {
        require(msg.sender == owner);
        //Will not run the rest of the code until the statement above "_" are true
        _;
    }

    //Add a withdraw function so the money can leave the contract to an account
    function withdraw() public payable onlyOwner {
        // Transfer function allows us to send something from one address to another
        //This is key word that refers to the current contract
        //Calling address(this).baloance checks gets the balance of the current address of the contract we are in
        // This line will transfer the balance of this contract to the sender
        msg.sender.transfer(address(this).balance);

        //reset everyones balances after they withdraw
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //Reset funder array by setting funders to a new array
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