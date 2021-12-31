// SPDX-License-Identifier: MIT

// To create a new project in a folder run
//   brownie init
// To compile the contract use the command
//   brownie compile
// After compiling this file, you should see under build/contracts:
//   A dependencies folder with the imported sol files
//   FundMe.json

pragma solidity ^0.6.6;

// These imports which worked in Remix will not work in Brownie automatically.
//   Remix can download packages directly from npm. Brownie can download directly
//   from Github. Need to create a "remmapping" of "@chainlink" in brownie-config.yaml.
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // sets the owner to whomever deploys this contract
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // Set minimum amount of USD in ETH to send to $50
        uint256 minimumUSD = 50 * 10**18;
        // Will revert the transaction (send money back + unspent gas) if requirement
        //   not met.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Minimum of $50 USD in ETH required!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        // Also adding to this array for the purpose of this training
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // Need to get the address of the interface on the correct TESTNET.
        // Find ETH / USD on this page => https://docs.chain.link/docs/ethereum-addresses/
        // under the appropriate TESTNET. There is only 2: KOVAN and Rinkby.
        // Below address is KOVAN ETH / USD address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); // e.g. returns 3940310000000000000000
    }

    //If buying 1 GWEI which is 1000000000 WEI
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000; // e.g. returns 3897810000000
        return ethAmountInUSD;
    }

    // function modifier
    modifier onlyOwner() {
        // Will only allow the function it modifies to run if the
        //   address making the call (i.e. the sender) is this contract's
        //   address.
        require(msg.sender == owner);
        _; // now run the function here
    }

    function withdraw() public payable onlyOwner {
        // "this" means this contract (at the contract's address)
        msg.sender.transfer(address(this).balance);
        // loop through the array and set everybody's balance to zero
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // grab funder address
            address funder = funders[funderIndex];
            // set funder amount to 0
            addressToAmountFunded[funder] = 0;
        }
        // "reset" the array
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