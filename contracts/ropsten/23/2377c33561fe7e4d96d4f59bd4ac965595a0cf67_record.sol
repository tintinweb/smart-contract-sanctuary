pragma solidity ^0.4.18;
// pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// &#39;record&#39; contract
//
// Deployed to : 0x91ef4140646d39ee957586cb89dbf70739ca19a5

contract mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */
    function mortal () {
        owner = msg.sender;
    }

    /* Function to recover the funds on the contract */
    function kill() {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}


contract record is mortal {
    string[] records;
    address owner;

    function record() public {
        owner = msg.sender;
    }

    function sendNewEntry(string newEntry ) {
        records.push(newEntry);
    }

    function getRecord () returns (uint){
        if (msg.sender == owner) {
            return 1;
        }
    }
}