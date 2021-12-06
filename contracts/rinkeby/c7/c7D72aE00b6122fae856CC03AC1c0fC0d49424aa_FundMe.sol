// SPDX-License-Identifier: MIT

// declaring the solidity version
pragma solidity ^0.6.6;

// importing the aggregator interface*. This will allow us to get the actual ETH price imported from the chainlink data feed
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

//initializing the contract with the name FundMe
contract FundMe {
    // applies the SafeMathChainlink and automatically checks for the overflows on uint256's.
    using SafeMathChainlink for uint256;

    // This mapping keeps track of which addresses sent us funds. The public declares who can call the function!
    mapping(address => uint256) public addressToAmountFunded;
    // funders array of addresses
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // declares the owner of the contract, in this case whoever deploys the contract!
    constructor(address _pricefeed) public {
        priceFeed = AggregatorV3Interface(_pricefeed);
        owner = msg.sender;
    }

    // declaring a function with name fund which is publicly callable and also payable which means that you can send some ETH with it to the contract
    function fund() public payable {
        // we set a minimum value for funding in USD -> 50USD
        uint256 minimumUSD = 50 * 10**18;
        // the require statement ensures that the value sent by whoever calls this function is greater or equal than the minimum Amount in USD. In case the sent amount is lower than 50USD it will revert the transaction and raise "You need to spend more ETH"
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // Adds the msg sender (whoever calls the function) and the amount of which he has sent to the addressToAmountFunded mapping
        addressToAmountFunded[msg.sender] += msg.value;
        // pushes the funders address to the funders array.
        funders.push(msg.sender);
    }

    // this version allows whoever calls the function to see the actual version of the interface. view = will not modify the state. public = visible externally and internally.
    function getVersion() public view returns (uint256) {
        // Initializing the AggregatorV3Interface contract with the address as seen below. You can find the addresses at https://docs.chain.link/docs/ethereum-addresses/
        return priceFeed.version();
    }

    // this function acutally gets the price from the pricefeed. view = will not modify the state. public = visible externally and internally.
    function getPrice() public view returns (uint256) {
        // latestRoundData returns 5 different values. With the commas we can use typecasting here which means we just take the second value -> "int265 answer".
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // since the smalles unit of measure wei has 18 decimal places so we adjust the answer to have also 18 decimals places instead of only 8 -> therfore * 10000000000.
        return uint256(answer * 10000000000);
    }

    // Converts the USD amount to ETH. view = will not modify the state. public = visible externally and internally.
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // calls the getPrice function
        uint256 ethPrice = getPrice();
        // you can test it out without dividing by 1000000000000000000 and you will see why you need to do this step!
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // is used in the function below to modify it in a way that only the owner/deployer of the contract can withdraw the funds.
    modifier onlyOwner() {
        // the transactions gets reverted in case the person who calls the withdraw function is not the person that deployed the contract.
        require(msg.sender == owner);
        _;
    }

    // this function serves for withdrawing the funds. It is also payable because we transfer eth.
    function withdraw() public payable onlyOwner {
        // we want to transfer all the funds out of the contract. "this" is always referencing to the contract address you are currently in.
        msg.sender.transfer(address(this).balance);
        // We need to update the funders balances. It starts at funderIndex 0 all the way up to the funders.lenght. So it will finish as soon as the end of the list is reached. After every iteration the funderIndex gets incremented by 1 (funderIndex++).
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // grabs the address of the funder from the funders array.
            address funder = funders[funderIndex];
            // funder is set to the index of the funder in the funders array -> to use it as key in the addressToAmountFunded mapping. With the code below we reset the amount to 0.
            addressToAmountFunded[funder] = 0;
        }
        // The funders array is set to a new funders array.
        funders = new address[](0);
    }
}

//* Interfaces compile down to an ABI (Application Binary Interface). The ABI tells solidity and other programming languages how it can interact with another contract.

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