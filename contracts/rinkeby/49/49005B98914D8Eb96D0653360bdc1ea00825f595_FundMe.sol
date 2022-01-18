// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    // This 'using A for B;' can be used to attach library functions(A) to any type(B) within a contract.
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    /*
        Constructor - this function runs when a contract is deployed.
    */
    constructor() public {
        // in this case, the owner is the person who deployed the contract.
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minUSD = 50 * (10**18); // Minimum of $50 in wei.
        // if(msg.value < minUSD) {
        //     revert?
        // }

        // Solidity style would use 'require' which is a check before a function executes.
        require(
            getConversionRate(msg.value) >= minUSD,
            "You need to spend more ETH!"
        );
        // 'revert' unspent gas and funds are returned to the user.

        /*
            msg.sender & msg.value are predefined values in every contract.
            1. msg.sender - the sender of funds
            2. msg.value - the amount of funds
        */
        addressToAmountFunded[msg.sender] += msg.value;

        // Oracles are used to connect contracts to "outside world data".
        // Find ETH -> USD conversion.

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // Addresss from https://docs.chain.link/docs/ethereum-addresses/ Rinkeby: ETH->USD
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // This returns a Tuple of 5 values.
        // priceFeed.latestRoundData()

        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();

        // To fix unused variables warning, use blanks.
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        /* 
            returns 320120819731 which is 3201.20819731
            
            Reason being that Solidity doesn't work with decimals,
            and these values should be seen as having 8 decimals places
        */
        // return uint256(answer);

        // Returns the answer in wei (18 decimal places).
        return uint256(answer * 10000000000);
    }

    // 100000000 = 1 gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();

        // 320801998386.000000000000000000
        // uint256 ethAmountInUSD = (ethPrice * ethAmount);

        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        // 3208019983860
        // add 0s to get 18 decimal places
        // 0.000003208019983860

        // 0.000003208019983860 * 1 Gwei = USD price.
        return ethAmountInUSD;
    }

    // Modifiers are used to change the behavior of a function in a declaritive way.
    modifier onlyOwner() {
        require(msg.sender == owner);
        // this underscore means 'rest of the function code.'
        _;
    }

    // function withdraw() payable public {
    //     // Add a require to make sure only the contract owner/admin can withdraw funds.
    //     require(msg.sender == owner);

    //     // tansfer is a function that can be called on any address to send ETH from one address to another.
    //     // 'this' refers to the current contract.
    //     // 'balance' is the current value of funds at that address.
    //     msg.sender.transfer(address(this).balance);
    // }

    // withdraw function using a modifier.
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        // Reset all the funder's fund value to 0.
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        // reset the funders array to a blank array.
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