/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity 0.5.12;

pragma experimental ABIEncoderV2;

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



/// @title StandardStaking
/// @dev A set of contracts for people to open stakes, and allow people to claim against them
/// @author Mark Beylin <[email protected]>
contract StandardStaking {

  using SafeMath for uint256;

  /*
   * Structs
   */

  struct Stake {
    address payable staker; // The address of the user who controls the stake
    address payable[] arbiters; // An array of individuals who may rule on claims for the given stake
    uint stakeAmount; // The amount in wei which the user has staked
    uint arbiterFee; // The fee which is paid to the arbiter who rules on the claim
    uint griefingFee; // The fee which is paid to the winning side for the trouble of dealing with the claim
    bool active; // A boolean which stores whether a user's stake is active (ie has the funds and accepts claims)
    uint deadline; // A uint representing the time after which the staker may relinquish their stake
    Claim[] claims; // An array of Fulfillments which store the various submissions which have been made to the bounty
  }

  struct Claim {
    address payable claimant; // The address of the individual who created the claim
    uint claimAmount; // The amount of wei which the user seeks within the claim
    address payable arbiter; // The address of the arbiter who ends up ruling on the claim
    bool ruled; // A boolean which stores whether or not the claim has been ruled upon by one of the available arbiters
    bool correct; // A boolean which stores whether or not the claimant has been deemed correct in their claim
  }
  /*
   * Storage
   */

  mapping (uint => Stake) public stakes; // An array of stakes
  uint public numStakes;

  bool public callStarted; // Ensures mutex for the entire contract

  /*
   * Modifiers
   */

  modifier callNotStarted(){
    require(!callStarted);
    callStarted = true;
    _;
    callStarted = false;
  }

  modifier validateStakeArrayIndex(
    uint _index)
  {
    require(_index < numStakes);
    _;
  }

  modifier onlyStaker(
  uint _stakeId)
  {
    require(msg.sender == stakes[_stakeId].staker);
    _;
  }

  modifier onlyClaimant(
  address _sender,
  uint _stakeId,
  uint _claimId)
  {
    require(_sender == stakes[_stakeId].claims[_claimId].claimant);
    _;
  }

  modifier deadlineIsPassed(
    uint _stakeId)
  {
    require(stakes[_stakeId].deadline < now);
    _;
  }

  modifier deadlineAfterCurrent(
    uint _stakeId,
    uint _deadline)
  {
    require(_deadline > stakes[_stakeId].deadline);
    _;
  }

  modifier claimNotTooLarge(
    uint _stakeId,
    uint _claimAmount)
  {
    // If the claimant's right, the staker loses (claim amount + arbiter fee + griefing fee), so we check they have enough
    require((_claimAmount +
             stakes[_stakeId].arbiterFee +
             stakes[_stakeId].griefingFee) <= stakes[_stakeId].stakeAmount);
    _;
  }

  modifier stakeStillActive(
    uint _stakeId)
  {
    require(stakes[_stakeId].active);
    _;
  }

 /*
  * Public functions
  */

  constructor() public {
  }

  /// @dev createStake(): creates a new stake
  /// @param _staker the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _data the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  function createStake(address payable _staker,
                       address payable[] memory _arbiters,
                       uint _stakeAmount,
                       uint _arbiterFee,
                       uint _griefingFee,
                       uint _deadline,
                       string memory _data)
    public
    payable
    returns (uint)
  {
    require(_deadline > now);
    require(msg.value == _stakeAmount);
    require(_arbiters.length > 0);
    require(_stakeAmount > (_arbiterFee + _griefingFee));

    uint stakeId = numStakes;
    Stake storage newStake = stakes[stakeId];

    newStake.staker = _staker;
    newStake.arbiters = _arbiters;
    newStake.stakeAmount = _stakeAmount;
    newStake.arbiterFee = _arbiterFee;
    newStake.griefingFee = _griefingFee;
    newStake.deadline = _deadline;
    newStake.active = true;

    numStakes = numStakes.add(1);

    emit StakeCreated(stakeId,
                      msg.sender,
                      _staker,
                      _arbiters,
                      _stakeAmount,
                      _arbiterFee,
                      _griefingFee,
                      _data, // Instead of storing the string on-chain, it is emitted within the event for easy off-chain consumption
                      _deadline);
    return (stakeId);
  }


  /// @dev openClaim(): Allows users to contribute tokens to a given bounty.
  ///                    Contributing merits no privelages to administer the
  ///                    funds in the bounty or accept submissions. Contributions
  ///                    are refundable but only on the condition that the deadline
  ///                    has elapsed, and the bounty has not yet paid out any funds.
  ///                    All funds deposited in a bounty are at the mercy of a
  ///                    bounty's issuers and approvers, so please be careful!
  /// @param _stakeId the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _claimAmount the index of the bounty
  /// @param _data the amount of tokens being contributed
  function openClaim(
    uint _stakeId,
    uint _claimAmount,
    string memory _data)
    public
    payable
    validateStakeArrayIndex(_stakeId)
    claimNotTooLarge(_stakeId, _claimAmount)
    callNotStarted
  {
    require(msg.value == (_claimAmount + stakes[_stakeId].arbiterFee + stakes[_stakeId].griefingFee));

    stakes[_stakeId].claims.push(Claim(msg.sender, _claimAmount, address(0), false, false));

    emit ClaimOpened(_stakeId,
                     (stakes[_stakeId].claims.length - 1), // The new contributionId
                     msg.sender,
                     _claimAmount,
                     _data);
  }

  function ruleOnClaim(
    uint _stakeId,
    uint _claimId,
    uint _arbiterId,
    bool _correct,
    string memory _data)
    public
    payable
    validateStakeArrayIndex(_stakeId)
    callNotStarted
  {
    require(_claimId < stakes[_stakeId].claims.length); // checks the claim bounds
    require(!stakes[_stakeId].claims[_claimId].ruled); // checks the claim isn't ruled

    require(_arbiterId < stakes[_stakeId].arbiters.length); // checks the arbiter bounds
    require(msg.sender == stakes[_stakeId].arbiters[_arbiterId]); // checks that the sender is a valid arbiter
    require(stakes[_stakeId].active); // checks that the stake is still active

    stakes[_stakeId].claims[_claimId].ruled = true;
    stakes[_stakeId].claims[_claimId].correct = _correct;
    stakes[_stakeId].claims[_claimId].arbiter = msg.sender;

    if (stakes[_stakeId].claims[_claimId].correct) {
      // Claimant is correct...
      stakes[_stakeId].stakeAmount -= (stakes[_stakeId].claims[_claimId].claimAmount +
                                  stakes[_stakeId].griefingFee +
                                  stakes[_stakeId].arbiterFee);
      stakes[_stakeId].claims[_claimId].claimant.transfer(2 * stakes[_stakeId].claims[_claimId].claimAmount +
                                    2 * stakes[_stakeId].griefingFee +
                                    stakes[_stakeId].arbiterFee);
    } else {
      // Staker is correct
      stakes[_stakeId].staker.transfer(stakes[_stakeId].claims[_claimId].claimAmount +
                                  stakes[_stakeId].griefingFee);
    }

    msg.sender.transfer(stakes[_stakeId].arbiterFee);

    emit ClaimRuledUpon(_stakeId,
                         _claimId,
                         _arbiterId,
                         stakes[_stakeId].claims[_claimId].correct,
                         _data);
  }

  /// @dev reclaimStake(): Allows users to refund the contributions they've
  ///                            made to a particular bounty, but only if the bounty
  ///                            has not yet paid out, and the deadline has elapsed.
  /// @param _stakeId the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  function reclaimStake(
    uint _stakeId)
    public
    validateStakeArrayIndex(_stakeId)
    onlyStaker(_stakeId)
    deadlineIsPassed(_stakeId)
    callNotStarted
  {
    stakes[_stakeId].active = false;
    stakes[_stakeId].staker.transfer(stakes[_stakeId].stakeAmount);

    emit StakeReclaimed(_stakeId);
  }

  function extendDeadline(
    uint _stakeId,
    uint _newDeadline)
    public
    validateStakeArrayIndex(_stakeId)
    onlyStaker(_stakeId)
    deadlineAfterCurrent(_stakeId, _newDeadline)
    callNotStarted
  {
      stakes[_stakeId].deadline = _newDeadline;

      emit DeadlineExtended(_stakeId, _newDeadline);
  }

  function addArbiter(
    uint _stakeId,
    address payable _newArbiter)
    public
    validateStakeArrayIndex(_stakeId)
    onlyStaker(_stakeId)
  {
    stakes[_stakeId].arbiters.push(_newArbiter);

    emit ArbiterAdded(_stakeId, _newArbiter);
  }

  function getStake(
    uint _stakeId
    )
    external
    view
    validateStakeArrayIndex(_stakeId)
    returns (Stake memory)
  {
    return stakes[_stakeId];
  }

  /*
   * Events
   */

  event StakeCreated(uint _stakeId, address creator, address payable _staker, address payable[] _arbiters, uint _stakeAmount, uint _arbiterFee, uint _griefingFee, string _data, uint _deadline);
  event ClaimOpened(uint _stakeId, uint _claimId, address payable _claimant, uint _claimAmount, string _data);
  event ClaimRuledUpon(uint _stakeId, uint _claimId, uint _arbiterId, bool _correct, string _data);
  event StakeReclaimed(uint _stakeId);
  event DeadlineExtended(uint _stakeId, uint _newDeadline);
  event ArbiterAdded(uint _stakeId, address _newArbiter);
}