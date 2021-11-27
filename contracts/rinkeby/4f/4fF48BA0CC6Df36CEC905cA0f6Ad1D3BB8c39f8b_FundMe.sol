//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;


// Below import is to bring AggregatorV3Interface.sol file in our contract.
// We bring it in order to reach to PriceConsumerV3 contract which gives us currency rate 

import "AggregatorV3Interface.sol";

// Below import is for the chainlink SafeMath Library
import "SafeMathChainlink.sol";

contract FundMe{

    /* Using keyword: The directive using A for B; can be used to attach library functions (from the library A)
    to any type (B) in the context of a contract */

    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    /* constructor is the constructor of the contract. It executed imediately after contract is created.
    it is like __init__ function in python classes */

    constructor() public {
        owner = msg.sender;
    }


    // payable keyword makes the function accept some type of payment. 

    function fund() public payable {

        uint256 minimumUSD = 50 * 10 ** 18;

        /* require keyword means if the requirement does not meet it will stop executing.
        in below line of code if the msg.Value is smaller than minimumUSD than it will stop executing
        and revert a message "You need to spend more ETH"
        */
        
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");

        // msg.sender and mg.value are keywords in every contract call or every transaction
        // msg.sender is the account address of the sender of the function call
        // msg.value is how much they send

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {

        // .version() function is defined inside AggregatorV3Interface interface that we imported above

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){

        // .latestRoundData() function is defined inside AggregatorV3Interface interface that we imported above

        /* AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e) We put the contract address
        from the chainlink documentation. This is the price feed contract of the Rinkeby network 
        ETH/USD contract (https://docs.chain.link/docs/ethereum-addresses/)*/

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (, int256 answer,,,) = priceFeed.latestRoundData();

        // we can write below tuple as shown above format to shorten

        /*(uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) = priceFeed.latestRoundData(); */
        
        // we can convert int256 to uint256 as below

        /* We multiply the answer by 10**10 because the answer is in Gwei we 
        for the consistency multiplay by 10 to convert it to wei */

        return uint256(answer*10**10);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUSD;
    }


    /* Modifier: A modifier is used to change the behavior of a function in a declarative way.
        modifiers are like decorators in python
    */

    /* _; wherever we put _; operator inside a modifier it will run the respective function.
    In below case it will run the respective function after check for the require parameter. */ 
    
    // We use modifier to run the same code in multiple functions 
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        // transfer send amount of eth to an account whoever is call it.
        /* this referring to the contract that we are currently in. when we call it with address
         means address of the contract that weare currently in */
        //  balance is the balance of the contract
        msg.sender.transfer(address(this).balance);

        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        //we are set funders array to new empty array
        
        funders = new address[](0);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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