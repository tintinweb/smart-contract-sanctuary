// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";
// chanlinks to import data from real world
// there are no chaninlink nodes on simulated JS VMs
// Interfaces : interfaces do not have full function implementations.
//
//  ABI : Application Binary Interface
//        The ABI tells solidity and other programminh languages how it can interact with another contract.
//
//  Anytime we want to interact with an already deployed smart contract we will need wn ABI.
//  Interfaces compile down to an ABI
//  Always need an ABI to interact with a contract

import "SafeMathChainlink.sol";
// SafeMathChainlink is basically the same as Openzeppelin SafeMath


// Library : A library is similar to contracts, but their purpose is that they are
//           deployed only once at a specific adress and their code is reused.

contract FundMe {

    // using keyword : 
    //      The directive 'using A for B' can be used to attach library fumctions (from the library A)
    //      to any type (B) in the sontext of a contract.
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address [] public funders; //
    address public owner; // to store funders accounts

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // Functions and addresses declared payable can receive ether into the contract.
        
        uint256 minimumUSD = 50*10**18;
        require(getConversionRate(msg.value)>=minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        // The msg global variables are special global variables that contain properties which allow access to the blockchain. 
        // msg.sender : sender of the function call, the address where the current (external) function call came from. 
        // msg.value : the amount of wei sent with a message to a contract (wei is a denomination of ETH)

        funders.push(msg.sender); //store funders accounts into an array which called funders
    }
    
    function getVersion() public view returns (uint256){
        // finding price feed adresses : https://docs.chain.link/docs/ethereum-addresses/
        address ETHUSDAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETHUSDAddress);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
        // finding price feed adresses : https://docs.chain.link/docs/ethereum-addresses/
        address ETHUSDAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETHUSDAddress);

        // Tupple : it is a list of potentially different types whise number is a constant at compile-time. 
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        // or :
        // (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); 
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;   
    }

    // Modifier : 
    //     A modifier is used to change the behavior of a function
    //     in a declarative way.
    // "modifier" is a keyword.
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public{
        // only want the contract admin/owner 
        // require(msg.sender == owner); !!!!!! we do not require this line. we used a modifier for same purpose.

        msg.sender.transfer(address(this).balance);
        // we can use msg.sender.transfer to send ETH from one adress to another
        //  to get all the money that funded in this contract :  adress(this).balance
        // this is a reference to contract we are coding in
        // address(this) : we want the adress of contract we are coding
        // address(this).balance : amounth of ETH on this contract
        
        for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); 
    }

}

// Resetting

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