// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// from https://docs.chain.link/docs/get-the-latest-price/
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

// remix understands the @chainlink
// brownie can download from github, the external 3rd party contracts


contract FundMe {
    // if using less than 0.8, need safemath to auto check for overflow errors
    using SafeMathChainlink for uint256; 

    mapping(address => uint256) public addressToAmountFunded;

    // create an array to keep the funders' addresses 
    // so that we can use it to erase all funder's amount funded to 0 after withdrawal
    address[] public funders;

    // initialize a address variable called owner
    address owner; // it doesn't need to be public

    // a constructor function is called immediately when the contract is deployed
    // not sure why it has to be public though.
    constructor() public {
        owner = msg.sender; // assign the msg sender as the owner
    }


    function fund() public payable {
    // set a minimum sum
        uint256 minimumUSD = 50 * (10 ** 18); // power of 18 so that it has 18 decimals behind
        // will call revert if not met
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!"); 
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);          
    }

    function getVersion() public view returns (uint256) {
        // address below is from the chainlink Eth-USD docs
        // Eth data feeds at https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version(); 

    }

    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // ( uint80 roundID, 
        //     int answer,
        //     uint startedAt,
        //     uint timeStamp, 
        //     uint80 answeredInRound ) = priceFeed.latestRoundData(); 

            ( , 
            int answer,
            ,
            , 
            ) = priceFeed.latestRoundData(); 
        //   return uint256(answer);    // typecast the answer
        // If just answer is 391202492790 , 12 digit number with 8 decimal places = 3912.02492790 price of 1 Eth

        return uint256(answer * (10**10));
        // The above returns 391202492790,0000000000 , adds 10 zeros to make it a 22 digit number with 18 decimal places.
        // i.e. 3912.02492790,0000000000
    
    }


    function getConversionRate(uint256 weiAmount) public view returns(uint256) {
        // Get price of 1 eth that is 391202492790,0000000000 (22 digit number with 18 decimals to deduct from it)
        uint256 ethPrice = getPrice(); 
        // divide the 22 digit number by 18 decimal places to get the 1 Eth price
        uint256 ethAmountInUSD = (ethPrice * weiAmount) / (10**18); 
        return ethAmountInUSD; 

        // But we cannot enter 0.000000001 for 1 Gwei price since solidity cannot do decimals.
        // So we just treat as 1 WEI, indivisible unit. And since 1 Wei = 18 decimal places.
        // the answer must divide by 10**18 decimals.
        
        // Example 1:
        // Entering 1 wei returns 3870 => 0.000000000000003870 USD for 1 Wei

        // Example 2:
        // Entering 1000000000 wei (10**9 = 1 gwei) returns 3843623127810
        // Take the answer 3843623127810 divide by 10**18 = 0.000003843623127810
        // Above, 1 gwei = 0.000003843623127810 USD

        // Example 3: 
        // Entering 1000000000000000000 wei (10**18 = 1 eth) returns 3834520600260000000000
        // 1 eth unit = 3834.520600260000000000 (divide by 18 decimal places) 

    } 

    // Basic version of withdraw function
    // function withdraw() payable public {
    //     // transfer function to send from one address to another
    //     // .transfer(ethAmount) to whoever calls it, e.g. msg.sender.transfer(1000)
    //     // this refers to the contract, "address of this" refers to the contract's address
    //     // msg.sender.transfer(address(this).balance);

    //     // to check that withdraw is only for owner of contract
    //     require(msg.sender == owner, "You are not the owner!");
    //     msg.sender.transfer(address(this).balance);

    // }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner!");
        _; // runs the rest of the code
    }

    // modifier to restrict function calling to owner only, only owner can see it
    function withdraw() payable onlyOwner public {
        msg.sender.transfer(address(this).balance);

        // reset everyone's funding to zeros
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // also need to reset the funders array to an empty array of addresses.
        funders = new address[](0);
    }



    function checkBalance() public view returns(uint256) {
        return address(this).balance;
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