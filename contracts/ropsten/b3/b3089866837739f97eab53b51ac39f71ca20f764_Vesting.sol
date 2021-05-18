/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/*
  This file is part of The Colony Network.

  The Colony Network is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The Colony Network is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with The Network. If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity 0.5.8;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Vesting {
  using SafeMath for uint256;
  using SafeMath for uint128;
  using SafeMath for uint16;
  Token public token;
  address public admin;

  // vesting_01 to 04 should add up to 100 !
  uint256 vesting_01 = 17;
  uint256 vesting_02 = 23;
  uint256 vesting_03 = 23;
  uint256 vesting_04 = 37;


  uint256 public grantAmount;
  address public recipient;

  uint constant internal SECONDS_PER_MONTH = 1800;

  mapping(address => bool) public allowed;

  event GrantAdded(address recipient, uint256 startTime, uint128 amount, uint16 vestingDuration, uint16 vestingCliff);
  event GrantRemoved(address recipient, uint128 amountVested, uint128 amountNotVested);
  event GrantTokensClaimed(address recipient, uint128 amountClaimed);

  struct Grant {
    uint startTime;
    uint128 amount;
    uint16 vestingDuration;
    uint16 vestingCliff;
    uint16 monthsClaimed;
    uint128 totalClaimed;
  }
  mapping (address => Grant) public tokenGrants;

  modifier onlyAdmin {
    require(msg.sender == admin, "vesting-unauthorized");
    _;
  }

  modifier onlyAllowed {
    require(allowed[msg.sender], "not-allowed");
    _;
  }

  modifier nonZeroAddress(address x) {
    require(x != address(0), "token-zero-address");
    _;
  }

  modifier noGrantExistsForUser(address _user) {
    require(tokenGrants[_user].startTime == 0, "token-user-grant-exists");
    _;
  }

  constructor(address _token) public
  nonZeroAddress(_token)
  nonZeroAddress(msg.sender)
  {
    token = Token(_token);
    admin = msg.sender;
    allowed[admin] = true;
  }

  function allow(address _new) public onlyAdmin {
    allowed[_new] = true;
  }

  /// @notice Add a new token grant for user `_recipient`. Only one grant per user is allowed
  /// The amount of CLNY tokens here need to be preapproved for transfer by this `Vesting` contract before this call
      /// Secured to the admin only
  /// @param _recipient Address of the token grant recipient entitled to claim the grant funds
  /// @param _startTime Grant start time as seconds since unix epoch
  /// Allows backdating grants by passing time in the past. If `0` is passed here current blocktime is used.
  /// @param _amount Total number of tokens in grant
  /// @param _vestingDuration Number of months of the grant's duration
  /// @param _vestingCliff Number of months of the grant's vesting cliff
  function addTokenGrant(address _recipient, uint256 _startTime, uint128 _amount, uint16 _vestingDuration, uint16 _vestingCliff) public
  onlyAllowed()
  noGrantExistsForUser(_recipient)
  {
    require(_vestingCliff > 0, "token-zero-vesting-cliff");
    require(_vestingDuration > _vestingCliff, "token-cliff-longer-than-duration");
    uint amountVestedPerMonth = _amount / _vestingDuration;
    require(amountVestedPerMonth > 0, "token-zero-amount-vested-per-month");

    grantAmount = _amount;
    recipient = _recipient;

    Grant memory grant = Grant({
      startTime: _startTime == 0 ? now : _startTime,
      amount: _amount,
      vestingDuration: _vestingDuration,
      vestingCliff: _vestingCliff,
      monthsClaimed: 0,
      totalClaimed: 0
    });

    tokenGrants[_recipient] = grant;
    emit GrantAdded(_recipient, grant.startTime, _amount, _vestingDuration, _vestingCliff);
  }

  /// @notice Terminate token grant transferring all vested tokens to the `_recipient`
  /// and returning all non-vested tokens to the admin
  /// Secured to the admin only
  /// @param _recipient Address of the token grant recipient
  function removeTokenGrant(address _recipient) public
  onlyAdmin
  {
    Grant storage tokenGrant = tokenGrants[_recipient];
    uint16 monthsVested;
    uint128 amountVested;
    (monthsVested, amountVested) = calculateGrantClaim(_recipient);
    uint256 res = uint128((tokenGrant.amount).sub(tokenGrant.totalClaimed));

    uint128 amountNotVested = uint128(res.sub(amountVested));

    require(token.transfer(_recipient, amountVested), "colony-token-recipient-transfer-failed");
    require(token.transfer(admin, amountNotVested), "colony-token-colony-multisig-transfer-failed");

    tokenGrant.startTime = 0;
    tokenGrant.amount = 0;
    tokenGrant.vestingDuration = 0;
    tokenGrant.vestingCliff = 0;
    tokenGrant.monthsClaimed = 0;
    tokenGrant.totalClaimed = 0;

    emit GrantRemoved(_recipient, amountVested, amountNotVested);
  }

  /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
  /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
  function claimVestedTokens() public {
    uint16 monthsVested;
    uint128 amountVested;
    (monthsVested, amountVested) = calculateGrantClaim(msg.sender);
    require(amountVested > 0, "token-zero-amount-vested");

    Grant storage tokenGrant = tokenGrants[msg.sender];
    tokenGrant.monthsClaimed = uint16(tokenGrant.monthsClaimed.add(monthsVested));
    tokenGrant.totalClaimed = uint128(tokenGrant.totalClaimed.add(amountVested));

    require(token.transfer(msg.sender, amountVested), "token-sender-transfer-failed");
    emit GrantTokensClaimed(msg.sender, amountVested);
  }

  /// @notice Calculate the vested and unclaimed months and tokens available for `_recepient` to claim
  /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
  /// Returns (0, 0) if cliff has not been reached
  function calculateGrantClaim(address _recipient) public view returns (uint16, uint128) {
    Grant storage tokenGrant = tokenGrants[_recipient];

    // For grants created with a future start date, that hasn't been reached, return 0, 0
    if (now < tokenGrant.startTime) {
      return (0, 0);
    }

    // Check cliff was reached
    uint elapsedTime = now.sub(tokenGrant.startTime);
    uint elapsedMonths = elapsedTime / SECONDS_PER_MONTH;

    if (elapsedMonths < tokenGrant.vestingCliff) {
      return (0, 0);
    }
    uint amountVestedPerMonth;
    uint128 amountVested;

    // If over vesting duration, all tokens vested
    if (elapsedMonths >= tokenGrant.vestingDuration) {
      uint128 remainingGrant = tokenGrant.amount - tokenGrant.totalClaimed;
      return (tokenGrant.vestingDuration, remainingGrant);
    } else {
      uint16 monthsVested = uint16(elapsedMonths.sub(tokenGrant.monthsClaimed));
      if (monthsVested == 1){
          amountVestedPerMonth = tokenGrant.amount * vesting_01 / 100;
          amountVested = uint128(amountVestedPerMonth);//uint128(monthsVested.mul(amountVestedPerMonth));
      }
      if (monthsVested == 2){
          amountVestedPerMonth = tokenGrant.amount * vesting_02 / 100;
          amountVested = uint128(amountVestedPerMonth);//uint128(monthsVested.mul(amountVestedPerMonth));
      }
      if (monthsVested == 3){
          amountVestedPerMonth = tokenGrant.amount * vesting_03 / 100;
          amountVested = uint128(amountVestedPerMonth);//uint128(monthsVested.mul(amountVestedPerMonth));
      }
      if (monthsVested == 4){
          amountVestedPerMonth = tokenGrant.amount * vesting_04 / 100;
          amountVested = uint128(amountVestedPerMonth);//uint128(monthsVested.mul(amountVestedPerMonth));
      }

      // uint amountVestedPerMonth = tokenGrant.amount / tokenGrant.vestingDuration;
      // uint128 amountVested = uint128(monthsVested.mul(amountVestedPerMonth));

      return (monthsVested, amountVested);
    }
  }
}