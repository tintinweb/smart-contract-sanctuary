// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//Procederemos a trabajar en la BC de Chainlink.
//Para tener en cuenta a los nodos que dan información a partir de API's en la red importamos
//el Aggregator
//import "AggregatorV3Interface.sol";

//This links brings to an interface, not a contract. Interfaces have uncompleted functions.
//Interfaces are a minimalistic view to another contract.

//For easiness and in order to better exemplify the functions we proceed to explicitly write the code.
//Nevertheless, using the link is much easier.

//We also import SafeMath in order to prevent the program from breaking due to memory limitations.
//E.g., uint8 can only be a number from 0 to 255.
import "SafeMathChainlink.sol";

interface AggregatorV3Interface {
    //We point out where we wishh to use safemath.
    using SafeMathChainlink for uint256;

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

//Now that we have copied this interface we can interact with the given functions.

//In this section we will procceed to deal with money.
contract FundMe {
    //We create a map with an Address as an input and a (money) amount as the output.
    mapping(address => uint256) public addressToAmountFunded;

    //We want to be able to reset the money each sender has given. In order to do that we create an address array:
    address[] public funders;

    //We introduce the address of the owner:
    address public owner;

    //We develop a function which will be used to define who is the owner which can withdraw money:
    //The constructor is a statement opened up right after the smartcontract is sent:
    //It CONSTRUCTS the smart contract
    constructor() public {
        owner = msg.sender;
    }

    //We introduce a new command: "payable".
    //Wei is the minimum partition of Ethereum.
    //Gwei is 10^9 Wei.

    //The fund() function is red because it involves a payment.
    function fund() public payable {
        //We define the minimum amount which can come towards our account.
        uint256 minimumUSD = 50; //We multiply *10**18 because we want it in WEY
        //Now we require that the value is no smaller than 50:
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //If the previous function is not staisfied a reversion is applied and the money is given back to the sender.
        //Additionally, a message is sent to the sender saying that he needs to spend more ETH.
        //We make a variable which keeps saving the amount of money a wallet recieves.
        //msg.sender is the hash of the wallet which is sending value
        //msg.value is the amount is the amount of crypto within the message.
        addressToAmountFunded[msg.sender] += msg.value;

        //Now whenever a funder sends money, we push him/her to the funders array
        funders.push(msg.sender);
    }

    //Interacting with the interface is similar to interact with a struct object.

    //We begin by calling the version() function from the interface.

    function getVersion() public view returns (uint256) {
        //In the following line we are saying that we say that priceFeed is an object AggregatorV3Interface with the functions
        //defined at the beginning of the script. Concretely, we refer to the contract with address given in the Chain Link Rinekby
        //addresses which corresponds to the ETH/USD relation.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //Once the given interface is been directed to the address we desire we may obtain some property of it:
        return priceFeed.version();
    }

    //We have made a function which tells us the Version of the contract. We proceed to make
    //a function to tell us the returns from latestRoundData:

    function getPrice() public view returns (uint256) {
        //We begin by introducing the interface and the address we are interested in.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //Now we call the function from the interface we are interested in.
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        //We have placed the variables as a tuple, a list of objects.
        //We convert answer into a uint256 so it is the type of the returned value in the defined function.
        return uint256(answer);
        //Lastly, it is worth mentioning that the result must take into account that the result is the value in exchange
        //times 10^8.
        //In order to make the code much cleaner, we can change the latestRoundData function line into only giving the answer variable.
        //(,int256 answer,,,)=priceFeed.latestRoundData();
    }

    //Our next function will check for a given wallet if it has sent more than a given amount. E.g. 50$.
    //For that, we will precise the latest value of ETH/BTC
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        //We first relate the variable to our earlier defined function:
        uint256 ethPrice = getPrice();
        //
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        //The reason fo which we divide over 10^18 is because both values are multiplied time 10^9.
        //Remember that the price is given in units of 1/10^10$
        return ethAmountInUsd;
        //Now that we have stablished a counter of the money and a conversion into dollars we can go see the fund function and complete it.
    }

    //We also introduce the modifier.
    //Modifiers are used to change the behavior of a function in a declarative way.
    modifier onlyOwner() {
        require(msg.sender == owner);
        //Given that we put this condition here we can take it of the following function.
        _;
        //What this modifier is saying is that before reading the remainder of the script the
        //sender must be the owner of the script.
        //We can then introduce this modifier to whichever functions we desire.
    }

    function withdraw() public payable onlyOwner {
        //First we limit this function to only be used by the owner.
        //require(msg.sender==owner);
        //This is a key word which refers to the contract the command is in.
        //The address(this) is the address of the command itself.
        msg.sender.transfer(address(this).balance);
        //The previous line states that whomever wrote the code, to be sent all the money within the contract (.balance)

        //Whenever we withdraw everything, we want to set the array to 0. We do that through a for loop.
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //The funderIndex goes from 0 to the length of the array -1.
            //The fundersIndex++ indicates that fundersIndex increases by 1 every time the loop is over.

            //We set the address to be the one of the array with the given funderIndex
            address funder = funders[funderIndex];
            //We update the mapping we stablished earlier.
            addressToAmountFunded[funder] = 0;
        }
        //We conclude by setting all the addresses within the array to 0:
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