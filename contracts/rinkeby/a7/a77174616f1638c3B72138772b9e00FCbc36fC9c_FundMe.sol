/**
 *Submitted for verification at Etherscan.io on 2022-01-24
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

contract FundMe{
    // To prevent overflow issue
    using SafeMathChainlink for uint256;

    // create a mapping variable to map address to amount funded into this contract
    mapping(address => uint256) public addressToAmountFunded; 
    address[] public funders; // create an array to store address named funders
    address public owner; // create an address varible named owner

    // Constructor allows the function to be executed once when the contract is deployed
    // The line below allows address of the owner to be recorded in the contract
    constructor() public {
        owner = msg.sender;
    }



    function fund() public payable{ // payable allows contract to accept some type of payment
        // whenever this "fund()" function is called, someone can send an amount (i.e. value) to this contract and
        // the address is saved in the addressToAmountFunded mapping
        // Sender is sending and storing currency in this contract
        // msg.sender and msg.value are keywords to every contract transactions
        // msg.sender is the sender of the function call (e.g. "fund()")
        // msg.value is how much the sender sent
        // addresstoamountfunded allows the checking of total amount sent by different address
        uint256 minimumUSD = 50; // 50*10**10 Min USD that can be funded into this contract is 50 multiply by 10 raised to power 18
        require(getConversionRate(msg.value) >= minimumUSD, "More ETH needed"); // require function is just like an if statement (similar to below)
        // if(msg.value < minimumUSD){
        //    revert?
        // }
        addressToAmountFunded[msg.sender] += msg.value; 
        funders.push(msg.sender); // address of sender is pushed into the funder array everytime the fund() function is called
        }

    // A modifier is used to change the behaviour of a function in a declarative way
    // The lines below state that only the owners can call the function
    // "_" specifies whether the require function is above or below the rest of the codes
    // In this case, the require function is called first then only the rest of the code "msg.sender.transfer(address(this).balance);"
    modifier onlyOwner {
        require(msg.sender ==  owner);
        _;
    }

    function withdraw() payable onlyOwner public { // The onlyOwner modifier is run first before the rest of the function
        // transfer is a function to send ETH from one address to another
        // address(this) refers to this contract address
        // balance refers to the ETH funded in this contract
        // The require function allows only the owner of this contract to withdraw currency from this contract
        // require(msg.sender ==  owner); replaced with modifier
        msg.sender.transfer(address(this).balance);
        // create a for loop that starts from 0 until max index of the funders array. Each loop is +1 specified by the funderIndex++
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex]; // get address of funder from the funders array
            addressToAmountFunded[funder] = 0; // this line replaces all the amount in the array to 0 when the all currency withdrawed
        }
        funders = new address[](0); // this line resets the funders array to a new blank array
    }



    function getVersion() public view returns(uint256){
        // Type (e.g. interface) > Visibilitiy (e.g. public) > VariableName > VariableValue
        // The line below states that the contract AggregatorV3Interface() has functions defined in its interface
        // located in the contract with address "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"
        // For this example, the address is located in Rinkeby Testnet
        // https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // This function returns the version of the extenal chainlink contract
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // PriceFeed.latestRoundData() returns 5 different types of values
        // They are saved in a tuple: A list of objects of potentially different types whose number is a constant at compile-time
        // The syntax () is used to define the tuple
        // Compiler error unused local variable can be ignored. To remove error, delete variable but remain the ","
        (   
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData(); 
        return uint256(answer/10**8); // as answer is type uint80. Hence converted to uint256
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice*ethAmount);
        return ethAmountInUSD;
    }
}