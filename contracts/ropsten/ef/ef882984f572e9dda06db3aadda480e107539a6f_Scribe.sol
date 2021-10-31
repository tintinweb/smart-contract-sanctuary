/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity ^0.5.12;


interface DadaCollectible {
    function DrawingPrintToAddress(uint256) external view returns (address);
}

/*
 * @title Contract that allows an owner of a Creep to scribe a message attached to the token.
 * There's no limit on the number of messages they can scribe or the length for a single message
 * Each message is an on-chain transaction requiring gas
 * @dev Conlan Rios
 * Modified by sparrow
 */
contract Scribe {
//address creepsContract = 0x068696A3cf3c4676B65F1c9975dd094260109d02;
address creepsContract = 0xbc2Df256FA6FAd53BfBf0a054aBF43561AcAafe3;
// A record event that emits each time an owner dictates a message
	event Record (
	// the address of who dicated this document
	address dictator,
        // The Creep printIndex
	uint printIndex,
        // The text of the dictation
        string text
    );
    
    uint256 creepOwner;

	// A recorded document which tracks the dictator, the text, and the timestamp of when it was created
	struct Document {
		// the address of who dicated this document
		address dictator;
		// the text of the dictation
		string text;
		// the block time of the dictation
		uint creationTime;
	}
	
	function getOwner(uint256 printIndex) public view returns (address) {
     return DadaCollectible(creepsContract).DrawingPrintToAddress(printIndex);
     
    }

	// Mapping of document keys to documents (keys are concated token address + tokenId)
	mapping (uint256 => Document[]) public documents;
	
	// Mapping of document keys to the count of dictated documents
	mapping (uint256 => uint) public documentsCount;

	// Function for dictating an owner message
	function dictate(uint256 printIndex, string memory _text) public {
		// check that the message sender owns the token 
		// the function in DadaCollectible.sol that returns the owner address given a unique printIndex
		// is DrawingPrintToAddress
		require(getOwner(printIndex) == msg.sender, "Sender not authorized to dictate.");

		// push a new document with the dictator address, message, and timestamp
		documents[printIndex].push(Document(msg.sender, _text, block.timestamp));
		// increase the documents counter for this key
		documentsCount[printIndex]++;
		// emit an event for this newly created record
		emit Record(msg.sender, printIndex, _text);
	}

}