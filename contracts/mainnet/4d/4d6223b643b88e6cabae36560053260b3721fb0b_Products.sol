pragma solidity ^0.4.13;

/**
 * blocksoft.biz antifake demo
 */

contract Products {

	uint8 constant STATUS_ADDED = 1;

	uint8 constant STATUS_REGISTERED = 2;

	//who can add products
	address public owner;

	//indexed requests storage
	mapping (bytes32 => uint8) items;

	//constructor
	function Products() {
		owner = msg.sender;
	}

	//default
	function() {
		revert();
	}

	//generate public from secret for manufacturer (note this is not going to transactions - just constant!)
	function getPublicForSecretFor(bytes32 secret) constant returns (bytes32 pubkey) {
		pubkey = sha3(secret);
	}

	//add item from manufacturer
	function addItem(bytes32 pubkey) public returns (bool) {
		if (msg.sender != owner) {
			revert();
		}
		items[pubkey] = STATUS_ADDED;
	}

	//check item by customer
	function checkItem(bytes32 pubkey) constant returns (uint8 a) {
		a = items[pubkey];
	}

	//update item by customer
	function updateRequestSeed(bytes32 pubkey, bytes32 secret) returns (bool) {
		if (items[pubkey] != STATUS_ADDED) {
			revert();
		}
		if (!(sha3(secret) == pubkey)) {
			revert();
		}
		items[pubkey] = STATUS_REGISTERED;
	}
}