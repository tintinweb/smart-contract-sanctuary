pragma solidity ^0.4.24;

contract record256 {

    mapping(uint => uint) public record;
    mapping(uint => uint) public blockNr;

    event R(uint z);

    constructor() public {}

    function addRecord(uint z) public {
        require(z != 0 && record[z] == 0);
        record[z] = now;
        blockNr[z] = block.number;
        emit R(z);
    }

    function addMultipleRecords(uint[] zz) public {
        for (uint i; i < zz.length; i++) {
            addRecord(zz[i]);
        }
    }

}