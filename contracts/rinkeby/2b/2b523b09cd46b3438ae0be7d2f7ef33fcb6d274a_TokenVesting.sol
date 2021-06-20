/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  event Released(uint256 amount);
  /**
   * Event for token purchase logging
   * @param investor who paid for the tokens
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed investor,
    uint256 amount
  );

  uint256 public cliff;
  uint256 public start;
  uint256 public duration = 86400;//63072000;
  uint256 public interval = 3600;//2628000

  //uint256 public constant ReleaseCap = 150000000000000000000000000;

  mapping (address=>bool) public members;
  mapping (address =>uint) public numReleases;
  mapping (address => uint) public nextRelease;
  mapping (address => uint) public amountInvested;
  uint256 public noOfMembers;
  uint256 public released;
  //uint256 public standardQuantity;
  uint public constant Releases = 24;
  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   */
  constructor(
    uint256 _start,
    uint256 _cliff
   // uint256 _duration,
    // uint256 _interval
  )
    public
  {
    require(_cliff <= duration);

   // duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
    //interval = _interval;
  }

  modifier onlyMember(address _memberAddress) {
    require(members[_memberAddress] == true);
      _;
  }

  function addMember(address _member) public onlyOwner {
      require(members[_member] == false);
      members[_member] = true;
      noOfMembers = noOfMembers.add(1);
  }

  function removeMember(address _member) public onlyOwner {
      require(members[_member] == true);
      members[_member] = false;
      noOfMembers = noOfMembers.sub(1);
  }

  function purchaseTokens (address _investor, uint256 _tokens, IERC20 _token) public onlyMember(_investor){
    uint256 unreleased = releasableAmount(_token);
    require(unreleased > 0);
    if (amountInvested[_investor] == 0){
      amountInvested[_investor] = _tokens;
    }
    else {
   amountInvested[_investor] = amountInvested[_investor] + _tokens;
 }
  emit TokenPurchase(_investor, _tokens);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20  token which is being vested
   */
  function release(IERC20 _token, address _member) onlyOwner public {
    uint256 unreleased = releasableAmount(_token);
    uint256 _amountToSend = amountInvested[_member];
    require(unreleased > 0);
    require( _amountToSend > 0);
    require(numReleases[_member] <= Releases);
    if (numReleases[_member] == 0){
    require(block.timestamp >= interval.add(cliff));

     released = released.add(_amountToSend);
     //unreleased = ReleaseCap.div(noOfMembers.mul(Releases));
     //unreleased =  unreleased.div(noOfMembers);
     _token.transfer(_member, _amountToSend);
     numReleases[_member] = numReleases[_member].add(1);
     nextRelease[_member] = interval.add(cliff).add(interval);
     amountInvested[_member] = amountInvested[_member].sub(_amountToSend);
   }
   else if (numReleases[_member] > 0){
     require(block.timestamp >= nextRelease[_member]);
     released = released.add(_amountToSend);
     //unreleased = ReleaseCap.div(noOfMembers.mul(Releases));
     //unreleased =  unreleased.div(noOfMembers);
     _token.transfer(_member, _amountToSend);
     numReleases[_member] = numReleases[_member].add(1);
     nextRelease[_member] = nextRelease[_member].add(interval);
     amountInvested[_member] = amountInvested[_member].sub(_amountToSend);
   }

    emit Released(_amountToSend);

  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(IERC20 _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 Token which is being vested
   */
  function vestedAmount(IERC20 _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(owner);
    uint256 totalBalance = currentBalance.add(released);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration)) {
      return totalBalance;
    } else {
      return  currentBalance;
    }
  }
}