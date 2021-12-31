//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

//library to prevent int overflow

contract FundMe {
    using SafeMathChainlink for uint256; //this is how to use the safemathlibrary to prevent
    //overflow

    /*----Constructor are the ones that gets executed first as well-----**/
    address public owner;
    address[] public funderList;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        /**
        msg : it is a sepecial global variable that contain the properties which allow 
        access to the blockchain's contracts, their functions, and their values.
        msg.sender: person who is currently connecing with the contract i.e the address
        msg.value: transaction amount of the sender.
        */
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;

    /**-----------------Payable Solidity------------------ */
    /*Use of "payable" modifier enables you to process transaction in your smart contract. */
    function fund() public payable {
        /**Here we will be creating a minimum payable for any sender*/
        uint256 minimumUSD = 50 * 10**18;
        //require(condition, else revert with error)
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more than $50 worth of ETH"
        );
        // this is a short way of setting the minimum using "require" instead of a loop.

        addressToAmountFunded[msg.sender] += msg.value;
        funderList.push(msg.sender);
    }

    /**---------------Get conversion rate, prices and versions using interfaces-------------------*/
    function getVersion() public view returns (uint256) {
        //what we are saying here is get me the access to all the functions defined in that
        //interface with that address
        /***
        In brownie we changed the hard coded version of Aggregator and instead will be getting
        the value from the constructor when called from another module.
         */
        return priceFeed.version();
    }

    //getting the price of Eth; default with 8 more zeros
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // changing to wei
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        //dividing by 18 zeros because of multiplication of 10
        //above and 8 by default.
        //4070050000000 => 0.000004070050000000 in Gwei
        return ethAmountInUsd;
    }

    /**---------Withdrawing the payabale by only the owner of the contract---------*/
    function withdraw() public payable onlyOwner {
        /**
        Here msg.sender grabs the address of whoeever is sending the money and this
        keywords get the address of the contract where the money is sent to. meaning
        we transfer all the balance from the contract to the sender address.*/

        //require(msg.sender == owner, "You are not the owner to receive fund.");//there might
        //be a time where the use of require might be extensive so to mitigate that for cleaner
        //code, we will be using ******modifier*********;

        msg.sender.transfer(address(this).balance);
        /*-----------------Resetting----------------------------------
        Once you fund your account, you reset the sender's value;
        */
        for (
            uint256 funderIndex = 0;
            funderIndex < funderList.length;
            funderIndex++
        ) {
            address funder = funderList[funderIndex]; //grabbing the address
            addressToAmountFunded[funder] = 0; // mapping that address value to 0
        }
        //type[] memory typearray = new type[](n)// where n is the total capacity of array
        funderList = new address[](0);
    }

    /**-------------------Helper  function for fund and withdraw-------------------- */
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice(); //current price of Eth
        uint256 precision = 10**18; //because the measurement is in wei so for extra precision
        return (minimumUSD * precision) / price;
    }

    /**----------------------Working with modifier------------------------------*/
    /*A modifier is use to change the behavior of a function in a declarative way.*/
    modifier onlyOwner() {
        /**Means that wherever this modifier is called check the criteria and _ means that
        if the criteria is meet, then run the code below it. 
        */
        require(msg.sender == owner, " You are not the owner boiiiii!");
        _;
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