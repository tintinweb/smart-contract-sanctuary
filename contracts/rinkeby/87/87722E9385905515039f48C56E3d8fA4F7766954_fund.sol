// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
//import "SafeMathChainlink.sol";



contract fund {
    
    mapping(address => uint256) public fundMap;
    address public owner;
    address[] public addresses;

    constructor() public {
        owner = msg.sender;
    }

    modifier ownerAuth() {
        require (owner == msg.sender);
        _;
    }

    function fundMe() public payable {
        uint256 minUSD = 1 * 10 ** 17;  // Add 17 decimals to $1 to compare with current convertETHToUSD units for Gwei
        // min $1

        // Convert wei to gwei
        uint256 gweiValue = msg.value / 1000000000;
        require(convertETHToUSD(gweiValue) >= minUSD, "Give at least 1 buck");
        fundMap[msg.sender] += gweiValue;

        for(uint256 add=0; add<addresses.length; add++) {
            if(msg.sender == addresses[add]) {
                return;
            }
        }
        addresses.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256) {
        return AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331).version();     //  Kovan testNet
    }
    
    // USD price * 10 ** 8: if ETH price = $4129.52488772 then output will be: 412952488772.
    function getPrice() public view returns (uint256) {
        (, int256 answer,,,) = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331).latestRoundData();
        return uint256(answer);
    }
    
    // Input in Gwei (= ETH * 10 ** 9). Output USD price * 10 ** 17 (for 1 Gwei: 412952488772 when ETH = $4129.52488772)
    function convertETHToUSD(uint256 gwei) public view returns (uint256) {
        uint256 price = getPrice(); // from price * 10 ** 8 to price * 10 ** 17 (Gwei)
        return price * gwei;
    }

    function withdrawMoney() payable ownerAuth public {
        msg.sender.transfer(address(this).balance);

        for(uint256 add=0; add<addresses.length; add++) {
            fundMap[addresses[add]] = 0;
        }

        addresses = new address[](0);
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