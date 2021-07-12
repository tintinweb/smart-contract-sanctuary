/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

// File: contracts/TokenVesting.sol

pragma solidity ^0.4.13;

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Released(uint256 amount);

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  uint256 public released;

  ERC20 public token;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _token address of the ERC20 token contract
   */
  function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    address _token
  ) {
    require(_beneficiary != 0x0);
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    start       = _start;
    cliff       = _start.add(_cliff);
    duration    = _duration;
    token       = ERC20(_token);
  }

  /**
   * @notice Only allow calls from the beneficiary of the vesting contract
   */
  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary);
    _;
  }

  /**
   * @notice Allow the beneficiary to change its address
   * @param target the address to transfer the right to
   */
  function changeBeneficiary(address target) onlyBeneficiary public {
    require(target != 0);
    beneficiary = target;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(beneficiary);
  }

  /**
   * @notice Transfers vested tokens to a target address.
   * @param target the address to send the tokens to
   */
  function releaseTo(address target) onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(target);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function _releaseTo(address target) internal {
    uint256 unreleased = releasableAmount();

    released = released.add(unreleased);

    token.safeTransfer(target, unreleased);

    Released(released);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function releasableAmount() public constant returns (uint256) {
    return vestedAmount().sub(released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public constant returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }

}