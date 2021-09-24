// SPDX-License-Identifier : MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";

/**
 * Uses Chainlink pricefeed for kovan
 */

contract FundMe is Ownable {
    using SafeMathChainlink for uint256;

    AggregatorV3Interface internal pricefeed;
    uint256 public minUSDValue = 50;

    uint256 public round = 1;
    mapping(address => uint256) public contributions;
    address[] public contributors;

    event Withdrawal(uint256 timestamp, uint256 totalAmount, uint256 round);

    // for convenience of querying history.
    // - more simple than looking for transactions that called
    // fund() and withdraw() for a particular addresss,
    // but no guarantee of very long-term persistence
    event ContributionReset(uint256 timestamp, uint256 amount, uint256 round);

    constructor(address _priceFeed) public {
        pricefeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * change the entrance fee, i.e. the minimum required
     * @param newValue for funding contributions, expressed in USD
     */
    function changeMinContribution(uint256 newValue) public onlyOwner {
        minUSDValue = newValue;
    }

    function getContribution(address contributor)
        public
        view
        returns (uint256)
    {
        return contributions[contributor];
    }

    /** Only funding > the current entrance fee is accepted */
    function fund() public payable {
        uint256 usd = toUSD(msg.value);
        require(
            usd >= minUSDValue,
            "contribution is below minimum required, as currently valued in USD"
        );
        bool isNewContributor = contributions[msg.sender] == 0;
        contributions[msg.sender] += msg.value;
        if (isNewContributor) {
            contributors.push(msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        uint256 total = address(this).balance;
        msg.sender.transfer(total);
        Withdrawal(block.timestamp, total, round);
        resetRound();
    }

    function resetRound() public {
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributorAddress = contributors[i];
            uint256 amount = contributions[contributorAddress];
            contributions[contributorAddress] = 0;
            emit ContributionReset(block.timestamp, amount, round);
        }
        contributors = new address[](0);
        round++;
    }

    /** 8 decimals, according to the price feed */
    function getLatestPrice() internal view returns (uint256) {
        (, int256 price, , , ) = pricefeed.latestRoundData();
        return uint256(price);
    }

    function toUSD(uint256 _weiValue) internal view returns (uint256) {
        return (getLatestPrice() * _weiValue) / 10**8 / 10**18;
    }

    function weiToUSD(uint256 weiValue) public view returns (uint256) {
        return toUSD(weiValue);
    }

    /**
     * @return how much eth (expressed in wei) is the minimum to contribute
     * when funding, given the current eth - usd - conversion rate
     */
    function getEntranceFee() public view returns (uint256) {
        // Since we return in wei, and the eth/usd price is expressed per 1 whole eth,
        // our minimum usd amount should also be treated as if 1 dollar had 10**18 units,
        // and we operated on these finer units, to begin with.
        // The value returned eventually is hence already expressing an amount in wei.
        // By doing it this way we get the desired precision in the calculation.
        uint256 minimumUSD = minUSDValue * 10**8;
        uint256 price = getLatestPrice(); // usd per eth
        uint256 precision = 1 * 10**8;
        return ((minimumUSD * precision) / price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * This contract has been modified to remove the revokeOwnership function
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}