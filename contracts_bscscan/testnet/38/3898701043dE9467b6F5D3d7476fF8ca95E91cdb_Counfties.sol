/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

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
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b <= a, errorMessage);
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
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b > 0, errorMessage);
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
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns(uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Counfties is Context, Ownable {
  using SafeMath
  for uint256;

  struct Country {
    uint256 price;
    string message;
    address owner;
    string id;
  }

  mapping(string => Country) countries;

  struct leaderboardCountry {
    uint256 price;
    string country;
  }
  leaderboardCountry[5] topCountriesPrice;

  uint256 highest;
  uint256 feeBalance;

  constructor() public {
    topCountriesPrice[0].country = "N/A";
    topCountriesPrice[1].country = "N/A";
    topCountriesPrice[2].country = "N/A";
    topCountriesPrice[3].country = "N/A";
    topCountriesPrice[4].country = "N/A";
  }

  function buyCountry(string memory _country, string memory _message) public payable {
    require(bytes(_message).length <= 140, "Message must be under 140 characters");
    if (countries[_country].price > 0) {
      require(msg.value == countries[_country].price, "Too much money send");
      uint256 transferAmount = countries[_country].price;
      payable(countries[_country].owner).transfer(transferAmount.mul(110).div(120));
      uint256 feeAmount = countries[_country].price;
      feeBalance = feeBalance.add(feeAmount.mul(10).div(120));
    } else {
      require(msg.value == 0.01 ether, "Not enough BNB send");
      feeBalance = feeBalance.add(10000000000000000);
    }

    countries[_country].price = msg.value.mul(120).div(100);
    countries[_country].owner = msg.sender;
    countries[_country].message = _message;
    countries[_country].id = _country;
    addPrice(_country);
    if (countries[_country].price > highest) {
      highest = countries[_country].price;
    }
  }

  function addPrice(string memory _country) internal {
    uint listingNr = 0;
    for (uint i = 4; i > 0; i--) {
      string memory otherCountry = topCountriesPrice[i].country;
      if (compareStrings(otherCountry, _country)) {
        listingNr = i;
        break;
      }
    }

    uint256 price = countries[_country].price;
    for (uint i = 4; i > 0; i--) {
      if (price > topCountriesPrice[i].price ) {
        leaderboardCountry memory info;
        info.price = price;
        info.country = _country;
        topCountriesPrice[listingNr] = info;

        bool swapped;
        uint k;
        uint j;
        uint n = topCountriesPrice.length;
        for (k = 0; k < n - 1; k++) {
          swapped = false;
          for (j = 0; j < n - k - 1; j++) {
            if (topCountriesPrice[j].price > topCountriesPrice[j + 1].price) {
              (topCountriesPrice[j].price, topCountriesPrice[j + 1].price) = (topCountriesPrice[j + 1].price, topCountriesPrice[j].price);
              string memory nextCountry = topCountriesPrice[j + 1].country;
              topCountriesPrice[j + 1].country = topCountriesPrice[j].country;
              topCountriesPrice[j].country = nextCountry;
              swapped = true;
            }
          }
          if (swapped == false) break;
        }

        return;
      }
    }
  }

  function compareStrings(string memory a, string memory b) public view returns(bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function giveCountry(string memory _country, address _target, string memory _message) public onlyOwner {
    require(countries[_country].price == 0, "This country has been bought already");
    countries[_country].price = 12000000000000000;
    countries[_country].owner = _target;
    countries[_country].message = _message;
    addPrice(_country);
  }

  function getTopCountriesPrices() public view returns(leaderboardCountry[5] memory) {
    return topCountriesPrice;
  }

  function getMessage(string memory _country) public view returns(string memory) {
    return countries[_country].message;
  }

  function getHighestPrice() public view returns(uint256) {
    return highest;
  }

  function getCountryOwner(string memory _country) public view returns(address) {
    return countries[_country].owner;
  }

  function getValueOfCountry(string memory _country) public view returns(uint256) {
    return countries[_country].price;
  }

  function getBalance() public view returns(uint256) {
    return feeBalance;
  }

  function withdrawBNB() onlyOwner public {
    payable(owner()).transfer(feeBalance);
    feeBalance = 0;
  }

}