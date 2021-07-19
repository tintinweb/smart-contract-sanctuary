//SourceUnit: Bank.sol

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.9;

import "./SafeMath.sol";

contract Bank {
  struct Account {
    uint amount;
    uint received;
    uint percentage;
    bool exists;
    bool withdraw;
  }

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  mapping(address => Account) internal accountStorage;
  mapping(uint => address) internal accountLookup;
  mapping(uint => uint) internal agreementAmount;
  uint internal reentry_status;
  uint internal totalHolders;
  uint internal systemBalance = 0;

  using SafeMath for uint;

  modifier hasAccount(address _addr) {
    require(accountStorage[_addr].exists, "Restricted Access!");
    _;
  }

  modifier blockReEntry() {      
    require(reentry_status != ENTRY_DISABLED, "Security Block");
    reentry_status = ENTRY_DISABLED;

    _;

    reentry_status = ENTRY_ENABLED;
  }

  modifier canWithdraw(address _addr) {
    require(accountStorage[_addr].withdraw, "Restricted Access!");
    _;
  }

  function initiateDistribute() external hasAccount(msg.sender) {
    uint amount = distribute(systemBalance);

    systemBalance = systemBalance.sub(amount);
  }

  function distribute(uint _amount) internal returns (uint) {
    require(_amount > 0, "No amount transferred");

    uint percentage = _amount.div(100);
    uint total_used = 0;
    uint pay = 0;

    for (uint num = 0; num < totalHolders;num++) {
      pay = percentage * accountStorage[accountLookup[num]].percentage;

      if (pay > 0) {
        if (total_used.add(pay) > _amount) { //Ensure we do not pay out too much
          pay = _amount.sub(total_used);
        }

        deposit(accountLookup[num], pay);
        total_used = total_used.add(pay);
      }

      if (total_used >= _amount) { //Ensure we stop if we have paid out everything
        break;
      }
    }

    return total_used;
  }

  function deposit(address _to, uint _amount) internal hasAccount(_to) {
    accountStorage[_to].amount = accountStorage[_to].amount.add(_amount);
  }

  function() external payable blockReEntry() {
    systemBalance = systemBalance.add(msg.value);
  }

  function getSystemBalance() external view hasAccount(msg.sender) returns (uint) {
    return systemBalance;
  }

  function getBalance() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].amount;
  }

  function getReceived() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].received;
  }
  
  function withdraw(uint _amount) external payable hasAccount(msg.sender) canWithdraw(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount = accountStorage[msg.sender].amount.sub(_amount);
    accountStorage[msg.sender].received = accountStorage[msg.sender].received.add(_amount);

    (bool success, ) = msg.sender.call.value(_amount)("");
    
    require(success, "Transfer failed");
  }

  function withdrawTo(address payable _to, uint _amount) external hasAccount(msg.sender) canWithdraw(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount = accountStorage[msg.sender].amount.sub(_amount);
    accountStorage[msg.sender].received = accountStorage[msg.sender].received.add(_amount);

    (bool success, ) = _to.call.value(_amount)("");
    
    require(success, "Transfer failed");
  }

  function subPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
      accountStorage[_addr].percentage = accountStorage[_addr].percentage.sub(_percentage);
    }

  function addPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
      accountStorage[_addr].percentage = accountStorage[_addr].percentage.add(_percentage);
    }

  function getPercentage() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].percentage;
  }

  function validateBalance() external hasAccount(msg.sender) returns (uint) { //Allow any account to verify/adjust contract balance
    uint amount = systemBalance;

    for (uint num = 0; num < totalHolders;num++) {
      amount = amount.add(accountStorage[accountLookup[num]].amount);
    }

    if (amount < address(this).balance) {
      uint balance = address(this).balance;
      balance = balance.sub(amount);

      systemBalance = systemBalance.add(balance);

      return balance;
    }

    return 0;
  }

  function createAccount(address _addr, uint _amount, uint _percentage, uint _agreementAmount, bool _withdraw) internal {
    accountStorage[_addr] = Account({amount: _amount, received: 0, percentage: _percentage, withdraw: _withdraw, exists: true});
    agreementAmount[totalHolders] = _agreementAmount;
    accountLookup[totalHolders++] = _addr;
  }

  function deleteAccount(address _addr, address _to) internal hasAccount(_addr) {
    deposit(_to, accountStorage[_addr].amount);

    for (uint8 num = 0; num < totalHolders;num++) {
      if (accountLookup[num] == _addr) {
        delete(accountLookup[num]);
        break;
      }
    }

    delete(accountStorage[_addr]);
  }
}

//SourceUnit: P1Distribute.sol

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.9;

import "./Bank.sol";

contract P1Distribute is Bank {

  constructor(address[] memory _addr, uint[] memory _perc, uint[] memory _amount, bool[] memory _withdraw) public {
    reentry_status = ENTRY_ENABLED;

    uint percentage = 0;

    for (uint i = 0;i < _addr.length;i++) {
      percentage = percentage + _perc[i];
    }

    require(percentage == 100, "Percentage does not equal 100%");

    for (uint i = 0;i < _addr.length;i++) {
      if (i == 0) {
        createAccount(_addr[i], address(this).balance, _perc[i], _amount[i], _withdraw[i]);
      } else {
        createAccount(_addr[i], 0, _perc[i], _amount[i], _withdraw[i]);
      }
    }
  }

  function reviewAgreement(uint _account) external hasAccount(msg.sender) {
    require(agreementAmount[_account] > 0, "No agreement on account");

    if (accountStorage[accountLookup[_account]].received > agreementAmount[_account]) {
      agreementAmount[_account] = 0;
      subPercentage(accountLookup[_account], 25);
      deleteAccount(accountLookup[_account], accountLookup[0]);
      addPercentage(accountLookup[1], 25);
    }
  }

  function isAgreementCompleted(uint _account) external view hasAccount(msg.sender) returns (bool) {
    return agreementAmount[_account] == 0;
  }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.9;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}