// SPDX-Licence-Identifier: MIT

pragma solidity ^0.6.6;

// Brownie can't download from the npm package but can download from GitHub
import "AggregatorV3Interface.sol";
// A library is similar to contracts, but their purpose is that they are deployed
// only once at a specific address and their code is reused.
import "SafeMathChainlink.sol";


// This contract should be able to accept some type of payment
contract FundMe{

    // The directive using A for B; can be used to attach library functions from the library A
    // to any type B in the context of a contract.
    using SafeMathChainlink for uint256;

    // Keep track with who sent us some value with a mapping
    mapping(address => uint256) public addressToAmountFunded;

    // We want now to update the balances of all the contracts but we can't loop 
    // through a mapping. So we create an array.
    address[] public funders;

    address public owner;
    // You want to allow only certain address to withdraw and so you need to initiaize owners
    // To do so you need a constructor that is called in the instance the contract is deployed
    constructor() public {
        // This will be executed when we deploy the contract
        // The owner is the one who deploy the contract
        owner = msg.sender;
    }

    // Function that can accept payments
    // payable means that this function can be used to pay for things
    function fund() public payable {

        // Let's set a threshold of 50$ => I want it in wei so I multiply 
        // it by 10 to the power of 18
        uint256 minimumUSD = 50 * 10 ** 18;

        require(getConversionRate(msg.value) >= minimumUSD, "The amount sent do not match the minimum set");

        // Let's keep track of all the people that sent us money
        // msg.sender is the sender of the function call
        // msg.value is the value sent
        addressToAmountFunded[msg.sender] += msg.value;

        // Add the funder address in the funders array;
        funders.push(msg.sender);
    }

    // I want to set a minimum value of money to send
    // But I need to get the conversion ETH => USD (ORACLE like Chainlink)

    // Anytime you want to interact with an already deployed smart contract you 
    // will need an ABI

    // Interfaces compile down to an ABI

    // Always need an ABI to interact with a contract

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // This is a contract call to another contract from our contract using the interface
        return priceFeed.version(); // 403600181020"
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // This is a contract call to another contract from our contract using the interface
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // function that converts the ETH to USD equivalent
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // What if we have to use this "require" line multiple times?
    // We can use modifiers
    // Modifiers are used to change the behaviour of a function in a declarative way
    modifier onlyOwner {
        require(msg.sender == owner, "You can't withdraw balance because you're not the owner!");
        _;
    }

    function withdraw() payable onlyOwner public{

        // We require that only the owner can withdraw balance
        // require(msg.sender == owner, "You can't withdraw balance because you're not the owner!");

        // "this" is the contract you are currently in
        //  "address(this)" is the address of the contract
        // "address(this).balance" and this is the balance
        // "msg.sender" is whoever call the function
        msg.sender.transfer(address(this).balance);

        // Reset all the funders balance
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // Initialize a new empty array
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