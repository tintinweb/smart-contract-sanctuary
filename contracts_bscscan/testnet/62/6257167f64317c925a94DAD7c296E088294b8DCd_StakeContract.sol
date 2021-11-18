/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: staker.sol

pragma solidity ^0.4.24;


/* @title Mock Staking Contract for testing Staking Pool Contract */
contract StakeContract {
  using SafeMath for uint;

  /** @dev creates contract
    */
  constructor() public { }

  /** @dev trigger notification of withdrawal
    */
  event NotifyWithdrawalSC(
    address sender,
    uint startBal,
    uint finalBal,
    uint request
  );

  /** @dev withdrawal funds out of pool
    * @param wdValue amount to withdraw
    * not payable, not receiving funds
    */
  function withdraw(uint wdValue) public {
    uint startBalance = address(this).balance;
    uint finalBalance = address(this).balance.sub(wdValue);

    // transfer & send will hit payee fallback function if a contract
    msg.sender.transfer(wdValue);

    emit NotifyWithdrawalSC(
      msg.sender,
      startBalance,
      finalBalance,
      wdValue
    );
  }

    event FallBackSC(
      address sender,
      uint value,
      uint blockNumber
    );

  function () external payable {
    // only 2300 gas available
    // storage data costs at least 5000 for initialized values, 20k for new
    emit FallBackSC(msg.sender, msg.value, block.number);
  }
}