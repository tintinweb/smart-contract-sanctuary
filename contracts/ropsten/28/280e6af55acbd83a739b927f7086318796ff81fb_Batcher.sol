pragma solidity ^0.4.24;

contract Batcher{


    struct Batch {
        string batchNumber;
        uint numberOfSuppliers;
        string[2][] suppliers;
        uint addedSuppliers;
    }
    mapping(string => Batch) private batches; 

    function createSupplier(string _hashCode, string _unix, string _batchNumber, uint _index) public {
        batches[_batchNumber].suppliers[0][_index] = _hashCode;
        batches[_batchNumber].suppliers[1][_index] = _unix;
        batches[_batchNumber].addedSuppliers++;



    }


    function createBatch(string _batchNumber, uint _numberOfSuppliers) public{
        string[2][] memory newStringArray;
        batches[_batchNumber] = Batch(_batchNumber, _numberOfSuppliers, newStringArray, 0);
        for(uint i = 0; i < _numberOfSuppliers; i++){
            batches[_batchNumber].suppliers.push(["",""]);
        }
    }

    bytes32 public hasherhash;
    
    function generateHash(string _batchNumber) public returns(bytes32) {
        require(batches[_batchNumber].numberOfSuppliers == batches[_batchNumber].addedSuppliers, "Not enough suppliers");
        bytes32 batchNumberHash = keccak256(abi.encodePacked(_batchNumber));
        bytes32 firstHash = keccak256(abi.encodePacked(batches[_batchNumber].suppliers[0][0], batchNumberHash));
        bytes32 newString;
        for(uint i = 1; i < batches[_batchNumber].numberOfSuppliers; i++){
            newString = keccak256(abi.encodePacked(firstHash,batches[_batchNumber].suppliers[0][i], firstHash));
            firstHash = newString;

        }
        hasherhash = firstHash;
        return firstHash;
        
    }
    
}