pragma solidity ^0.4.24;

contract R256 {

    mapping(uint => uint) public record;

    event R(uint z);

    constructor() public {}

    function addRecord(uint z) public {
        require(record[z] == 0);
        record[z] = now;
        emit R(z);
    }

    function addMultipleRecords(uint[] zz) public {
        for (uint i; i < zz.length; i++) {
            addRecord(zz[i]);
        }
    }

}