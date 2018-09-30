pragma solidity ^0.4.6;
contract CarRegistry1 {



// Saves the wallet address of the owner.
address public owner;
string public name;

uint numCarTokens;

struct CarToken {
    address beneficiary;
    string carDescription;
    string serialNumber;
    uint dateIssued;
}

mapping (uint => CarToken) public carTokens;

// http://solidity.readthedocs.io/en/develop/common-patterns.html#restricting-access
modifier onlyBy(address account) {
    if (msg.sender != account) throw;
    _;
}


// --- This sets you as the contract owner. ---

function CarRegistry() {  //function CarRegistry(string contractName) {
    owner = msg.sender;
		// Set the name for display purposes
    name = "TLC 200 Vehicle";  //    name = contractName;
    // Making a Token for testing and demonstration purposes.
    NewToken(0xfcE1a37420dFc6AB128df20e10C0B14c89d23095, "Something about the car", "VIN-0000-0004");
}


// --- NewToken. Lets the owner create Tokens. ---

function NewToken(address receiver, string carDescription, string serialNumber) onlyBy(owner) returns (uint carTokenID) {
    carTokenID = numCarTokens++;
    carTokens[carTokenID] = CarToken(receiver, carDescription, serialNumber, block.timestamp);
}


// --- Transfer. Lets the beneficiary of a Token transfer his Token. ---

function Transfer(address receiver, uint carTokenID) {
		CarToken t = carTokens[carTokenID];
		if (t.beneficiary != msg.sender) throw;
		t.beneficiary = receiver;
}        
}