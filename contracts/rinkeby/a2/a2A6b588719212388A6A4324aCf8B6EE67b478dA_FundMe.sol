// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

//We are going to import data from @chainlink npm package.
//This package doesn't have contracts, it instead uses intercfaces and those interfaces compile into ABI's. The ABI tells solidity and other programming languages how it can interact with another contract. We always need ABI to interact with another contract.
import "AggregatorV3Interface.sol";
//SafeMath is a library that checks for overflows and is a contrqact from Openzepplin directory. However, if we are using solidity that is bnever than  0.8, we don't need it. In this case we will import it instead from the chainlink directory.
import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    //We will create a mapping to track who sent us the funding.
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    //When we define a function as payable, it means that this function can be used to pay for things with ETH.
    function fund() public payable {
        //Let's say we will only allow fundings that are minimum $50. To do so we will need to add a condition, multiply it by 10 because everything is in wei on ehtereum and then raise it to 18 to get 18 decimals.
        uint256 minimumUSD = 50 * 10**18;
        //To require the above condition, we will write the following line that reverts the insufficient fundings
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //This mapping show us the funding accounts fund value in wei. If we want it in the USD value, we will need oracles for the real life conversion.
        addressToAmountFunded[msg.sender] += msg.value;
        //Here, we are goin to push the addresses of funders into the funders array so that when they later on withdraw, we can keep track and update their balances.
        funders.push(msg.sender);
    }

    //From the imported chainlink contract, we first are going to use get version function.
    //To get the eth usd price feed for Rinkeby devnet, we will get the address from https://docs.chain.link/docs/ethereum-addresses/ website.
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //Originally latestRoundData function from the imported chainlink npm returns five values. However we only want to get the ETH/USD price so we will leave the other spots to look clean.
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //default chainlink function returns int256 format for the answer. Luckly wrapping it to uint256 is easy.
        return uint256(answer * 10000000000);
    }

    //Finally we will create a function to make the conversion for the recieved funding from wei value to dollar value.
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //To restrict anyone from withdrawing from our smart contract, we will use a modifier.Modifiers are used in a way to change the behaviour of a smart contract in a declarative way. Whereever you put the "_;" in a modifier, rest of the function resumes from there
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Since we funded our smart contract, now we are going to need a way to get out money back. So we will add a withdraw function. Below line says who ever sends the message, check the balance of this smart contract address and tranfer the balance to sender.
    //msg.sender.transfer(address(this).balance);
    //Now that we have a withdrawal function, we wouldn't want anyone to be able withdraw what is in this contract. In this case we will add constructor into the contract which will be called as soon as contract is deployed.
    //And will grant the contract deployer as the admin.
    function withdraw() public payable onlyOwner {
        //require(msg.sender == owner);                       //Instead of this line of code to restrict withdrawals we could also use a modifier.
        msg.sender.transfer(address(this).balance);
        //We will loop through the funders to reset their balances in their index order. funderIndex++ means add 1 to funderIndex everytime we loop.
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // And finally we will reset the funders array
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