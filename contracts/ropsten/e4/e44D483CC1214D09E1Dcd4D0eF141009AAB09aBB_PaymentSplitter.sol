/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title PaymentSplitter
 * @dev This contract can be used when payments need to be received by a group
 * of people and split proportionately to some number of shares they own.
 */
contract PaymentSplitter {
  using SafeMath for uint256;

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  /**
   * @dev Constructor
   */
  constructor(address[] payees, uint256[] shares) public payable {
    require(payees.length == shares.length);
    require(payees.length > 0);

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shares[i]);
    }
  }

  /**
   * @dev payable fallback
   */
  function () external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   * @return the total shares of the contract.
   */
  function totalShares() public view returns(uint256) {
    return _totalShares;
  }

  /**
   * @return the total amount already released.
   */
  function totalReleased() public view returns(uint256) {
    return _totalReleased;
  }

  /**
   * @return the shares of an account.
   */
  function shares(address account) public view returns(uint256) {
    return _shares[account];
  }

  /**
   * @return the amount already released to an account.
   */
  function released(address account) public view returns(uint256) {
    return _released[account];
  }

  /**
   * @return the address of a payee.
   */
  function payee(uint256 index) public view returns(address) {
    return _payees[index];
  }

  /**
   * @dev Release one of the payee's proportional payment.
   * @param account Whose payments will be released.
   */
  function release(address account) public {
    require(_shares[account] > 0);

    uint256 totalReceived = address(this).balance.add(_totalReleased);
    uint256 payment = totalReceived.mul(
      _shares[account]).div(
        _totalShares).sub(
          _released[account]
    );

    require(payment != 0);

    _released[account] = _released[account].add(payment);
    _totalReleased = _totalReleased.add(payment);

    account.transfer(payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  function _addPayee(address account, uint256 shares_) private {
    require(account != address(0));
    require(shares_ > 0);
    require(_shares[account] == 0);

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares.add(shares_);
    emit PayeeAdded(account, shares_);
  }
}