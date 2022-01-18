/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

//SPDX-License-Identifier: MIT
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

contract dENS2_1 {
	// safe math library check uint256 for integer overflows
  using SafeMathChainlink for uint256;
  address public owner = msg.sender;
  uint256 internal indexCount;

  modifier isOwner() {
    require(msg.sender == owner, "Only Owner can send transaction!");
    _;
  }

  struct nameToAddress {
    string name;
    address ethAddress;
  }

  nameToAddress[] internal nametoaddress;

  mapping(string => address) public nameToAddressQuery;

  function registerName(string memory _name) public payable {
    require(msg.value >= getConversionRate(10), "You need to spend more ETH!");
    require(
      bytes(addressToNameQuery(msg.sender)).length == 0,
      "Address is already registered!"
    );
    require(
      nameToAddressQuery[_name] == 0x0000000000000000000000000000000000000000,
      "Name already registered!"
    );
    nametoaddress.push(nameToAddress({ name: _name, ethAddress: msg.sender }));
    nameToAddressQuery[_name] = msg.sender;
    indexCount++;
  }

  function addressToNameQuery(address _address)
    public
    view
    returns (string memory)
  {
    for (uint256 i = 0; i < indexCount; i++) {
      if (nametoaddress[i].ethAddress == _address) {
        string memory name = nametoaddress[i].name;
        return name;
      }
    }
  }

  function getPrice() public view returns(uint256){
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    (,int256 answer,,,) = priceFeed.latestRoundData();
    // ETH/USD rate in 10 digit 
    return uint256(answer * 10000000000);
  }

  function getConversionRate(uint256 usdAmount) public view returns (uint256){
    uint256 ethPrice = getPrice();
    uint256 usdInWei = (usdAmount * 100000000) / ethPrice;
    return usdInWei;
  }

  function transferOwnership(address _newOwner) public isOwner {
    owner = _newOwner;
  }
}