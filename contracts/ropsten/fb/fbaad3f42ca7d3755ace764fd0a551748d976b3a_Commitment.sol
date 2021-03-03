/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

// SPDX-License-Identifier: CC0
/**
Contract to enable the management of private fungible token (ERC-20) transactions using zk-SNARKs.
@Author Westlad, Chaitanya-Konda, iAmMichaelConnor
*/

pragma solidity ^0.7.4;
//TODO: Use openzeppelin interfaces inside the timber service
// import "./MerkleTree.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract Commitment is Ownable, MerkleTree {
contract Commitment{
    // ENUMS:
    enum TransactionTypes { createContract, createPO, issueInvoice, confirmReceipt }

    struct CommitType { 
      string customer;
      string supplier;
   }
    // EVENTS:
    // Observers may wish to listen for nullification of commitments:
    event NewCommitment(string customer, string supplier);

    // For testing only. This SHOULD be deleted before mainnet deployment:
    event GasUsed(uint256 byShieldContract);

    // PRIVATE TRANSACTIONS' PUBLIC STATES:
    mapping(string => CommitType) public contracts; // store contracts
    mapping(string => CommitType) public purchases; // store purchase orders
    mapping(string => CommitType) public invoices; // store invoices
    mapping(string => CommitType) public receipts; // store delivery receipts

    mapping(bytes32 => bytes32) public nullifiers; // store nullifiers of spent commitments
    mapping(bytes32 => bytes32) public roots; // holds each root we've calculated so that we can pull the one relevant to the prover
    bytes32 public latestRoot; // holds the index for the latest root so that the prover can provide it later

    
    /**
    self destruct
    */
    // function close() external onlyOwner returns (bool) {
    //     selfdestruct(address(uint160(msg.sender)));
    //     return true;
    // }

    function getContract(string memory _contractAddress) public view returns (string memory, string memory) {
		return (contracts[_contractAddress].customer, contracts[_contractAddress].supplier);
	}

    function getPO(string memory _poAddress) public view returns (string memory, string memory) {
		return (purchases[_poAddress].customer, purchases[_poAddress].supplier);
	}

    function getInvoice(string memory _invoiceAddress) public view returns (string memory, string memory) {
		return (invoices[_invoiceAddress].customer, invoices[_invoiceAddress].supplier);
	}

    function getReceipt(string memory _receiptAddress) public view returns (string memory, string memory) {
		return (receipts[_receiptAddress].customer, receipts[_receiptAddress].supplier);
	}

    /**
    createContract
    */
    
    function createContract(
        string calldata _contractAddress, 
        string calldata _customer,
        string calldata _supplier
    ) public returns (bool) {

        // gas measurement:
        uint256 gasCheckpoint = gasleft();

        contracts[_contractAddress].customer = _customer;
        contracts[_contractAddress].supplier = _supplier;
        // latestRoot = insertLeaf(_newContractCommitment); // recalculate the root of the merkleTree as it's now different
        // roots[latestRoot] = latestRoot; // and save the new root to the list of roots

        emit NewCommitment(_customer, _supplier);

        // gas measurement:
        uint256 gasUsedByCommitment = gasCheckpoint - gasleft();
        emit GasUsed(gasUsedByCommitment);
        return true;
    }

    /**
    createPO
    */
    function createPO(
        string calldata _poAddress, 
        string calldata _customer,
        string calldata _supplier
        
    ) external returns (bool) {

        // gas measurement:
        uint256 gasCheckpoint = gasleft();

        purchases[_poAddress].customer = _customer;
        purchases[_poAddress].supplier = _supplier;

        emit NewCommitment(_customer, _supplier);

        // gas measurement:
        uint256 gasUsedByCommitment = gasCheckpoint - gasleft();
        emit GasUsed(gasUsedByCommitment);
        return true;
    }

    /**
    confirmReceipt
    */
    function confirmReceipt(
        string calldata _poAddress, 
        string calldata _customer,
        string calldata _supplier
        
    ) external returns (bool) {

        // gas measurement:
        uint256 gasCheckpoint = gasleft();

        // require(purchases[_poAddress] == 0, "The purchase order already exists!");
       
        receipts[_poAddress].customer = _customer;
        receipts[_poAddress].supplier = _supplier;

        emit NewCommitment(_customer, _supplier);
        // gas measurement:
        uint256 gasUsedByCommitment = gasCheckpoint - gasleft();
        emit GasUsed(gasUsedByCommitment);
        return true;
    }

    

    /**
    issueInvoice
    */
    function issueInvoice(
        string calldata _invoiceAddress, 
        string calldata _customer,
        string calldata _supplier
    ) external returns (bool) {

        // gas measurement:
        uint256 gasCheckpoint = gasleft();

        invoices[_invoiceAddress].customer = _customer;
        invoices[_invoiceAddress].supplier = _supplier;

        emit NewCommitment(_customer, _supplier);

        // gas measurement:
        uint256 gasUsedByCommitment = gasCheckpoint - gasleft();
        emit GasUsed(gasUsedByCommitment);
        return true;
    }
}