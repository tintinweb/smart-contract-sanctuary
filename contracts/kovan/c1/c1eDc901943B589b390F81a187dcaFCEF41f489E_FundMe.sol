/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



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

// File: fund-me.sol

contract FundMe{
    // To use SafeMathChainlink for all our uint256 operations
    using SafeMathChainlink for uint256; 
    
    mapping(address => uint256) public addressToAmountFunding;
    address[] funders;
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }
    
    constructor() public {
        owner=msg.sender;
    }
    
    function fund() public payable{
        uint256 minimumUSDWei = 5 * (10**18);
        
        //If the condition is true, the execution goes on. If not, it stops and give the specified error message
        require(getConversionRate(msg.value)>=minimumUSDWei, "You need to spent more ETH!");
        addressToAmountFunding[msg.sender] += msg.value;
        funders.push(msg.sender);
        
        // What the ETH -> USD conversion rate?
    }
    
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * (10**10)); //value in wei unit for USD (1 ETH = answer * 10**10 USD wei)
        //4.195,48 10 79 66
    }
    
    /*
        @ return ethWeiAmount in usdWei amount
    */
    function getConversionRate(uint256 ethWeiAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsdWei = (ethPrice * ethWeiAmount)/ (10**18);
        return ethAmountInUsdWei;
    }
    
    
    
    function withdraw() public payable onlyOwner{
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex< funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunding[funder]=0;   
        }
        funders = new address[](0);
    }
    
}