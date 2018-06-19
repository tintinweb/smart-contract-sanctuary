pragma solidity ^0.4.24;

contract R256Basic {

    event R(uint z);

    constructor() public {}

    function addRecord(uint z) public {
        emit R(z);
    }

    function addMultipleRecords(uint[] zz) public {
        for (uint i; i < zz.length; i++) {
            emit R(zz[i]);
        }
    }

}