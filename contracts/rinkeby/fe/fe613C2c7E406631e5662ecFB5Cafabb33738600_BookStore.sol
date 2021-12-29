// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6; 

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract BookStore {
  using SafeMathChainlink for uint256;

  struct Account {
    string name; 
    uint256 balance; 
    bool exists;
  }

  struct Book {
    string title;
    uint256 price;
    bool exists;  
    address[] buyers;
  }

  mapping(address=>Account) public addressToAccount;
  mapping(string=>Book) public titleToBook;
  address public owner; 

  AggregatorV3Interface priceFeed; 

  constructor(address _priceFeed) public {
    owner = msg.sender; 
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  modifier OnlyOwner {
    require(msg.sender == owner, "You are not the owner of this contract.");
    _;
  }

  function getVersion() public view returns(uint256){
    return priceFeed.version();
  }
    
  function getPrice() public view returns(uint256){
    (,int256 answer,,,) = priceFeed.latestRoundData();
      return uint256(answer * 10000000000);
  }
    
  // 1000000000
  function getConversionRate(uint256 ethAmount) public view returns(uint256){
    uint256 ethPrice = getPrice();
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    return ethAmountInUsd;
  } 
  
  function usdToEth(uint256 _usdAmount) public view returns(uint256) {
    uint256 ethPrice = getPrice();
    uint256 precision = 1 * 10**18;
    return (_usdAmount * precision) / ethPrice;
  }

  function createBook(string memory _title, uint256 _priceInUSD) public OnlyOwner {
    address[] memory tmp;
    titleToBook[_title]	 = Book(_title, _priceInUSD, true, tmp);
  }
  
  function deleteBook(string memory _title) public OnlyOwner {
    titleToBook[_title].exists = false;
  }
  
  function isValidBook(string memory _title) public view returns(bool) {
    return titleToBook[_title].exists;
  } 

  function createAccount(string memory _name) public {
    addressToAccount[msg.sender] = Account(_name, 0, true);
  }

  function isValidAccount(address _address) public view returns(bool) {
    return addressToAccount[_address].exists;
  }

  function deposit() payable public {
    require(isValidAccount(msg.sender) == true, "Please, create an account."); 

    addressToAccount[msg.sender].balance += getConversionRate(msg.value);
  }

  function withdrawFunds(uint256 _amount) payable public {
    require(isValidAccount(msg.sender) == true, "Please, create an account."); 
    require(addressToAccount[msg.sender].balance >= _amount, "You can't withdraw more than you have.");

    msg.sender.transfer(usdToEth(_amount));
    addressToAccount[msg.sender].balance -= _amount;
  }

  function purchase(string memory _title) public {
    require(isValidAccount(msg.sender) == true, "Please, create an account."); 
    require(isValidBook(_title) == true, "Invalid book");  
    
    uint256 balance = addressToAccount[msg.sender].balance;
    uint256 price = titleToBook[_title].price;

    require(balance >= price, "Insufficient funds");

    addressToAccount[msg.sender].balance -= price; 
    titleToBook[_title].buyers.push(msg.sender);
  }

  function showBalance(address _address) public view returns(uint256) {
    require(isValidAccount(_address) == true, "This account does not exist."); 
    return addressToAccount[_address].balance;
  }

  function withdrawContractFunds() payable public OnlyOwner {
    msg.sender.transfer(address(this).balance);
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