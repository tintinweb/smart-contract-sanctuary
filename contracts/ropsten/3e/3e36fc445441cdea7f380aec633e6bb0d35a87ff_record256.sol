pragma solidity ^0.4.24;

contract record256 {

    mapping(uint => uint) public blockTs;
    mapping(uint => uint) public blockNr;
    
    uint public totalRecords;

    event REC(uint h);
    event DUP(uint h);

    constructor() public {}
    
    // check records
    
    function checkRecords(uint[] zz) public view returns (uint r) {
        require(zz.length < 256);
        uint b = 1;
        for (uint i; i < zz.length; i++) {
          if (blockTs[zz[i]] > 0) r += b ;
          b = b << 1;            
        }
    }

    // add a single record

    function addRecordStrict(uint z) public {
        require (z != 0 && blockTs[z] == 0);
        _addRec(z);
    }

    function addRecord(uint z) public {
        if (z == 0 || blockTs[z] != 0) {
          emit DUP(z);
        } else {
          _addRec(z);
        }
    }

    function _addRec(uint z) private {
        blockTs[z] = now;
        blockNr[z] = block.number;
        totalRecords += 1;
        emit REC(z);
    }

    // add multiple records

    function addMultipleRecords(uint[] zz) public returns (uint) {
        uint totalRecordsIni = totalRecords;
        for (uint i; i < zz.length; i++) {
            addRecord(zz[i]);
        }
        return totalRecords - totalRecordsIni;
    }

    function addMultipleRecordsStrict(uint[] zz) public {
        for (uint i; i < zz.length; i++) {
            addRecordStrict(zz[i]);
        }
    }

}