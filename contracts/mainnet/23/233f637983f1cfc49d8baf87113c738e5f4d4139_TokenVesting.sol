pragma solidity 0.4.21;

// ----------------------------------------------------------------------------
// TokenVesting for &#39;Digitize Coin&#39; project based on:
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/TokenVesting.sol
//
// Radek Ostrowski / http://startonchain.com / https://digitizecoin.com
// ----------------------------------------------------------------------------


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

/**
 * @title CutdownToken
 * @dev Some ERC20 interface methods used in this contract
 */
contract CutdownToken {
  	function balanceOf(address _who) public view returns (uint256);
  	function transfer(address _to, uint256 _value) public returns (bool);
  	function allowance(address _owner, address _spender) public view returns (uint256);
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TokenVesting {
  using SafeMath for uint256;

  event Released(uint256 amount);

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  mapping (address => uint256) public released;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliffInDays duration in days of the cliff in which tokens will begin to vest
   * @param _durationInDays duration in days of the period in which the tokens will vest
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliffInDays, uint256 _durationInDays) public {
    require(_beneficiary != address(0));
    require(_cliffInDays <= _durationInDays);

    beneficiary = _beneficiary;
    duration = _durationInDays * 1 days;
    cliff = _start.add(_cliffInDays * 1 days);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(CutdownToken _token) public {
    uint256 unreleased = releasableAmount(_token);
    require(unreleased > 0);
    released[_token] = released[_token].add(unreleased);
    _token.transfer(beneficiary, unreleased);
    emit Released(unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(CutdownToken _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(CutdownToken _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}