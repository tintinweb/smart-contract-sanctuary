// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.7.0;

//import "./Ownable.sol";

contract TestContract {
	
	//TODO: Event
    //TODO: Struct
    //TODO: Mapping
    //TODO: Ownable
    //TODO: Upgradable
    //TODO: Safemath
    //TODO: Tests
    //TODO: Compiler version

    event NumberStored(uint myNumber, string trigger, address senderAddress);

    //state variables
    uint public storedInteger;

    function setOwnNumber(uint myNumber) public {
        require(
            myNumber != 1
        );
        storedInteger = myNumber;
        emit NumberStored(storedInteger, "user defined", msg.sender);
    }

    function setRandomNumber(string memory _str) public {
        storedInteger = _generateRandomNumber(_str);
        emit NumberStored(storedInteger, "randomly generated", msg.sender);
    }
    
    //should not be accessible publicly, no gas
    function _generateRandomNumber(string memory _str) private pure returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
		uint dnaDigits = 16;
    	uint dnaModulus = 10 ** dnaDigits;
        return rand % dnaModulus;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}