pragma solidity ^0.4.18;

// File: contracts/Ownable.sol

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {

  address public owner;

  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }

  }
}

// File: contracts/Deployer.sol

contract Deployer {

  address public deployer;

  function Deployer() public { deployer = msg.sender; }

  modifier onlyDeployer() {
    require(msg.sender == deployer);
    _;
  }
}

// File: contracts/ModultradeStorage.sol

contract ModultradeStorage is Ownable, Deployer {

  bool private _doMigrate = true;

  mapping (address => address[]) public sellerProposals;

  mapping (uint => address) public proposalListAddress;

  address[] public proposals;

  event InsertProposalEvent (address _proposal, uint _id, address _seller);

  event PaidProposalEvent (address _proposal, uint _id);

  function ModultradeStorage() public {}

  function insertProposal(address seller, uint id, address proposal) public onlyOwner {
    sellerProposals[seller].push(proposal);
    proposalListAddress[id] = proposal;
    proposals.push(proposal);

    InsertProposalEvent(proposal, id, seller);
  }

  function getProposalsBySeller(address seller) public constant returns (address[]){
    return sellerProposals[seller];
  }

  function getProposals() public constant returns (address[]){
    return proposals;
  }

  function getProposalById(uint id) public constant returns (address){
    return proposalListAddress[id];
  }

  function getCount() public constant returns (uint) {
    return proposals.length;
  }

  function getCountBySeller(address seller) public constant returns (uint) {
    return sellerProposals[seller].length;
  }

  function firePaidProposalEvent(address proposal, uint id) public {
    require(proposalListAddress[id] == proposal);

    PaidProposalEvent(proposal, id);
  }

  function changeOwner(address newOwner) public onlyDeployer {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}