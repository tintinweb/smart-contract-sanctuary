pragma solidity ^0.4.6;
contract CarRegistry2 {



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

mapping (uint => CarToken) public jobreferenceno;

// http://solidity.readthedocs.io/en/develop/common-patterns.html#restricting-access
modifier onlyBy(address account) {
    require (msg.sender != account) ;
    _;
}


// --- This sets you as the contract owner. ---

function CarRegistry(string contractName)public {  //function CarRegistry(string contractName) {
    owner = msg.sender;
		// Set the name for display purposes
    name=contractName;  //    name = contractName;
    // Making a Token for testing and demonstration purposes.
   // NewToken(0xfcE1a37420dFc6AB128df20e10C0B14c89d23095, "TLC200 VR7", "VIN-0000-0004");
}


// --- NewToken. Lets the owner create Tokens. ---

function NewToken(address receiver, string carDescription, string serialNumber)public  onlyBy(owner) returns (uint carTokenID)  {
    carTokenID = numCarTokens++;
    jobreferenceno[carTokenID] = CarToken(receiver, carDescription, serialNumber, block.timestamp);
}


// --- Transfer. Lets the beneficiary of a Token transfer his Token. ---

function Transfer(address receiver, uint carTokenID) public{
		CarToken storage  t = jobreferenceno[carTokenID];
		require (t.beneficiary != msg.sender) ;
		t.beneficiary = receiver;
}        
}