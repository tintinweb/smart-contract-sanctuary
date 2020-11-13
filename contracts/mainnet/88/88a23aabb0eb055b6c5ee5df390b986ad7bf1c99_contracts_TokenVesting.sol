/* solium-disable security/no-block-members */

pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 *
 * Note you do not want to transfer tokens you have withdrawn back to this contract. This will
 * result in some fraction of your transferred tokens being locked up again.
 *
 * Code taken from OpenZeppelin/openzeppelin-solidity at commit 4115686b4f8c1abf29f1f855eb15308076159959.
 * (Revocation options removed by Reserve.)
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

  // beneficiary of tokens after they are released
  address private _beneficiary;

  uint256 private _cliff;
  uint256 private _start;
  uint256 private _duration;

  mapping (address => uint256) private _released;
  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * beneficiary, gradually in a linear fashion until start + duration. By then all
   * of the balance will have vested.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
   * @param start the time (as Unix time) at which point vesting starts
   * @param duration duration in seconds of the period in which the tokens will vest
   */
  constructor(
    address beneficiary,
    uint256 start,
    uint256 cliffDuration,
    uint256 duration
  )
    public
  {
    require(beneficiary != address(0));
    require(cliffDuration <= duration);
    require(duration > 0);
    require(start.add(duration) > block.timestamp);

    _beneficiary = beneficiary;
    _duration = duration;
    _cliff = start.add(cliffDuration);
    _start = start;
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() public view returns(address) {
    return _beneficiary;
  }

  /**
   * @return the cliff time of the token vesting.
   */
  function cliff() public view returns(uint256) {
    return _cliff;
  }

  /**
   * @return the start time of the token vesting.
   */
  function start() public view returns(uint256) {
    return _start;
  }

  /**
   * @return the duration of the token vesting.
   */
  function duration() public view returns(uint256) {
    return _duration;
  }

  /**
   * @return the amount of the token released.
   */
  function released(address token) public view returns(uint256) {
    return _released[token];
  }

  /**
   * @return the amount of token that can be released at the current block timestamp.
   */
  function releasable(address token) public view returns(uint256) {
    return _releasableAmount(IERC20(token));
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(IERC20 token) public {
    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0);

    _released[token] = _released[token].add(unreleased);

    token.safeTransfer(_beneficiary, unreleased);

    emit TokensReleased(token, unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token).sub(_released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(_released[token]);

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _start.add(_duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
    }
  }
}
