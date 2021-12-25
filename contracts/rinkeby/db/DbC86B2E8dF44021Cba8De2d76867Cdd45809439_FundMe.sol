// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

//brownie cannot download directly from npm, but it can from GitHub
// check brownie-config.yaml

//accept some kind of payment
contract FundMe {
    //prevents overflow
    using SafeMathChainlink for uint256;

    //mappings between addresses and value
    mapping(address => uint256) public addressToAmountFunded;

    //array to loop through all funders balances
    address[] public funders;

    address public owner;

    //this gets called the instant the contract is deployed
    //here is where I should set the owner of the contract to avoid anyone else from taking over as owner
    constructor() public {
        //msg.sender is whoever deploys the smart contract
        owner = msg.sender;
    }

    //this function can be used to pay for things
    function fund() public payable {
        // $0.1
        // uint256 minimumUSD = 0.1 * 10**18;

        //require statement (like an if-statement)
        //stop executing if value sent to us isn't enough
        //require statement is followed by a revert statement
        // require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        //msg.sender and msg.value are keywords in every contract call in every transaction
        //msg.sender is the sender of the function call
        //msg.value is how much they sent
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //this makes a contract call to another contract from our contract using an interface
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    //this also makes a contract call to another contract from our contract using an interface (AggregatorV3Interface)
    //get current price of ETH in USD
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); //ETH / USD under Rinkeby Testnet in Chainlink
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //the commas are deleted entries where unused variables were
        return uint256(answer);
    }

    //convert ETH to USD
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    //modifier is used to change the behavior of a function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner, "Nice try theif!");
        _; //this represents the rest of the code to run after require statement is executed
    }

    //withdraw funded ETH
    function withdraw() public payable onlyOwner {
        //but currently this function allows anyone to withdraw from this account
        //therefore we need a require statement
        //require msg.sender = owner
        //I need a function to get called the instance I deploy this contract to set myself as owner ==> the constructor()
        // require(msg.sender == owner, "Nice try theif!");

        //transfer() is an embedded method that transfers ETH to whoever it's being called on
        //in this case transfer is called on msg.sender
        msg.sender.transfer(address(this).balance);
        //this refers to the contract we are in
        //thefore address(this) refers to the address of the contract we are currently in
        //balance refers to the balance of ETH of the address

        //loop through funders array and reset funder's balance to zero
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
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