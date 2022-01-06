/**
 *Submitted for verification at Etherscan.io on 2022-01-06
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

/*
 * Library: a library is similar to contracts, but their purpose is that they
 * are deployed only once at a specifed address and their code is reused.
 *
 * 'using' keyword: the directive 'using A for B' can be used to attach library
 * functions (from libary A) to any type (B) in the context of a contract
 **/

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // the address that deploys the contract is the owner of the contract.
    // only owner can withdraw the funds from the contract
    // AggregatorV3Interface contract address must be specified to deploy the contract
    // contract address for AggregatorV3Interface deployed on Rinkeby testnet for ETH /USD can be obtained from https://docs.chain.link/docs/ethereum-addresses/
    // the address is actually deployed in the testnet. Hence the contract needs to be deployed on test net as well
    // the interface implementation of AggregatorV3Interface can be found on https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payablel keyword indicates that ETH is transacted through the function
    // fund() allows funds to be paid to the contract owner
    // msg.sender refers otthe address that called the fund() function
    // msg.value refers to the amount of eth specified for funding
    function fund() public payable {
        uint256 minimumUSD = 50 * (10**18); // in denominations of Wei
        // line below specifies the requirement for the function to be called
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // takes in amount in wei, and returns the current USD value of the ethAmount in denominations of wei.
    // To get the return value in decimal place price (price of 1 wei) => ethAmountInUSD / 10*18
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // ethPrice and ethAmount are both in denominations of wei, hence, we must / 1000000000000000000 to get back ethAmountInUSD in correct denominations of Wei
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / (10**18);
        return ethAmountInUSD;
    }

    // returns the mimimum amount of Eth to fund in denominations of wei
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * (10**18);
        uint256 price = getPrice();
        uint256 precision = 1 * (10**18);
        return (minimumUSD * precision) / price;
    }

    // calls the version() function of the AggregatorV3Interface contract that has been deployed on the rinkeby testnet
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // 1eth = 1000000000 Gwei = 1000000000000000000 Wei
    // e.g., 2000.12345678 USD can buy 1eth = 1000000000 Gwei = 1000000000000000000 Wei
    // Note_that there are no decimals in solidity, so 2000.12345678 USD = 1000000000 Gwei
    // is represented by 200012345678 = 1000000000 Gwei
    // and 200012345678 * 1000000000 = 1000000000000000000 Wei
    // To get the price of an ETH with decimal place: 200012345678 * 1000000000 / 1000000000000000000 = 2000.12345678 USD

    // returns the current price of an eth in denominations of wei
    function getPrice() public view returns (uint256) {
        // (A,B,C) is the syntax for a tuple => tuple is a list of objects of potentially different types whoe number is a constant at compile-time
        // a tuple (structure) is first defined then values are assigned to the tuple using latestRoundData() function
        // in this case, priceFeed.latestRoundData() returns data in exactly the same format as the defined tuple
        // To clean up the code, we simply remove the unused variables from the tuple.
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // 'answer' is returned in denominations of Gwei. Hence, we need to multiply the answer by (10 ** 10) to get answer in denominations of wei
        return uint256(answer * (10**10)); // type casting is needed as answer is of type int256
    }

    function withdraw() public payable onlyOwner {
        // transfer: sends eth from one address to the caller
        // this: refers to the contract that you're currently in
        // balance: refers to the balance of the contract.
        msg.sender.transfer(address(this).balance);
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