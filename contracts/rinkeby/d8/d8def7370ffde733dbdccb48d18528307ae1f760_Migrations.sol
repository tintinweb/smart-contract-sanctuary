/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

pragma solidity ^0.5.0;

/**
 * @title Bounties
 * @dev Simple smart contract which allows any user to issue a bounty in ETH linked to requirements stored in ipfs
 * which anyone can fufill by submitting the ipfs hash which contains evidence of their fufillment
 */
contract Bounties {

  /*
  * Enums
  */

  enum BountyStatus { CREATED, ACCEPTED, CANCELLED }

  /*
  * Storage
  */

  Bounty[] public bounties;

  mapping(uint=>Fulfillment[]) fulfillments;

  /*
  * Structs
  */

  struct Bounty {
      address payable issuer;
      uint deadline;
      string data;
      BountyStatus status;
      uint amount; //in wei
  }

  struct Fulfillment {
      bool accepted;
      address payable fulfiller;
      string data;
  }

  /**
   * @dev Contructor
   */
  constructor() public {}

  /**
  * @dev issueBounty(): instantiates a new bounty
  * @param _deadline the unix timestamp after which fulfillments will no longer be accepted
  * @param _data the requirements of the bounty
  */
  function issueBounty(
      string calldata _data,
      uint64 _deadline
  )
      external
      payable
      hasValue()
      validateDeadline(_deadline)
      returns (uint)
  {
      bounties.push(Bounty(msg.sender, _deadline, _data, BountyStatus.CREATED, msg.value));
      emit BountyIssued(bounties.length - 1,msg.sender, msg.value, _data);
      return (bounties.length - 1);
  }

  /**
  * @dev fulfillBounty(): submit a fulfillment for the given bounty
  * @param _bountyId the index of the bounty to be fufilled
  * @param _data the ipfs hash which contains evidence of the fufillment
  */
  function fulfillBounty(uint _bountyId, string memory _data)
    public
    bountyExists(_bountyId)
    notIssuer(_bountyId)
    hasStatus(_bountyId, BountyStatus.CREATED)
    isBeforeDeadline(_bountyId)
  {
    fulfillments[_bountyId].push(Fulfillment(false, msg.sender, _data));
    emit BountyFulfilled(_bountyId, msg.sender, (fulfillments[_bountyId].length - 1),_data);
  }

  /**
  * @dev acceptFulfillment(): accept a given fulfillment
  * @param _bountyId the index of the bounty
  * @param _fulfillmentId the index of the fulfillment being accepted
  */
  function acceptFulfillment(uint _bountyId, uint _fulfillmentId)
      public
      bountyExists(_bountyId)
      fulfillmentExists(_bountyId,_fulfillmentId)
      onlyIssuer(_bountyId)
      hasStatus(_bountyId, BountyStatus.CREATED)
      fulfillmentNotYetAccepted(_bountyId, _fulfillmentId)
  {
      fulfillments[_bountyId][_fulfillmentId].accepted = true;
      bounties[_bountyId].status = BountyStatus.ACCEPTED;
      fulfillments[_bountyId][_fulfillmentId].fulfiller.transfer(bounties[_bountyId].amount);
      emit FulfillmentAccepted(_bountyId, bounties[_bountyId].issuer, fulfillments[_bountyId][_fulfillmentId].fulfiller, _fulfillmentId, bounties[_bountyId].amount);
  }

  /** @dev cancelBounty(): cancels the bounty and send the funds back to the issuer
  * @param _bountyId the index of the bounty
  */
  function cancelBounty(uint _bountyId)
      public
      bountyExists(_bountyId)
      onlyIssuer(_bountyId)
      hasStatus(_bountyId, BountyStatus.CREATED)
  {
      bounties[_bountyId].status = BountyStatus.CANCELLED;
      bounties[_bountyId].issuer.transfer(bounties[_bountyId].amount);
      emit BountyCancelled(_bountyId, msg.sender, bounties[_bountyId].amount);
  }

  /**
  * Modifiers
  */

  modifier hasValue() {
      require(msg.value > 0);
      _;
  }

  modifier bountyExists(uint _bountyId){
    require(_bountyId < bounties.length);
    _;
  }

  modifier fulfillmentExists(uint _bountyId, uint _fulfillmentId){
    require(_fulfillmentId < fulfillments[_bountyId].length);
    _;
  }

  modifier hasStatus(uint _bountyId, BountyStatus _desiredStatus) {
    require(bounties[_bountyId].status == _desiredStatus);
    _;
  }

  modifier onlyIssuer(uint _bountyId) {
      require(msg.sender == bounties[_bountyId].issuer);
      _;
  }

  modifier notIssuer(uint _bountyId) {
      require(msg.sender != bounties[_bountyId].issuer);
      _;
  }

  modifier fulfillmentNotYetAccepted(uint _bountyId, uint _fulfillmentId) {
    require(fulfillments[_bountyId][_fulfillmentId].accepted == false);
    _;
  }

  modifier validateDeadline(uint _newDeadline) {
      require(_newDeadline > now);
      _;
  }

  modifier isBeforeDeadline(uint _bountyId) {
    require(now < bounties[_bountyId].deadline);
    _;
  }

  /**
  * Events
  */
  event BountyIssued(uint bounty_id, address issuer, uint amount, string data);
  event BountyFulfilled(uint bounty_id, address fulfiller, uint fulfillment_id, string data);
  event FulfillmentAccepted(uint bounty_id, address issuer, address fulfiller, uint indexed fulfillment_id, uint amount);
  event BountyCancelled(uint indexed bounty_id, address indexed issuer, uint amount);

}