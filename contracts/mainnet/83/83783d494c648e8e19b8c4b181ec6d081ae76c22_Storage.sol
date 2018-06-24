pragma solidity ^0.4.21;

contract Storage {
    address owner; // This address has permission to upload data
    
    bytes32[] public data; // Storage container in pieces of 32 byte
    uint remainder; // Where the previous uploadData() left off
    
    bool readOnly; // Set the contract to read only once upload is finished

    constructor() {
        owner = msg.sender;
    }
    
    // Data is uploaded over many transactions, until the whole file is stored in the contract
    function uploadData(bytes _data) public {
        require(msg.sender == owner);
        require(readOnly != true);
        uint startPoint;

        if(remainder != 0) {

            startPoint = 32 - remainder;
            bytes memory rest = new bytes(32);
            for(uint i = 0; i < remainder; i++) {
                rest[i] = data[data.length - 1][i];
            }
            for(i = 0; i < startPoint; i++) {
                rest[remainder + i] = _data[i];
            }
            bytes32 p;
            assembly {
                p := mload(add(rest, 32))
            }
            data[data.length - 1] = p;
        }
        for(i = 0; i < (uint(_data.length - startPoint) / 32); i++) {
            bytes32 word;
            assembly {
                word:= mload(add(_data, add(add(32, startPoint), mul(i, 32))))
            }
            data.push(word);
        }
        uint loose = (_data.length - startPoint) % 32;
        if(loose != 0) {
            uint position = _data.length - loose;
            bytes32 leftover;
            assembly {
                leftover := mload(add(_data, add(32, position)))
            }
            data.push(leftover);
        }
        remainder = loose;
    }
    // If a mistake is done during upload, reverse using erase()
    function erase(uint _entriesToDelete) public {
        require(msg.sender == owner);
        require(readOnly != true);
        if(data.length < _entriesToDelete) { 
            delete data;
        }
        else data.length -= _entriesToDelete;
        remainder = 0;
    }
    function uploadFinish() public {
        require(msg.sender == owner);
        readOnly = true;
    }

    // This loads the entire file as a single byte array. Since it does not
    // affect the contract state, there are no gas costs
    function getData() public view returns (bytes){
        bytes memory result = new bytes(data.length*0x20);
        for(uint i = 0; i < data.length; i++) {
            bytes32 word = data[i];
            assembly {
                mstore(add(result, add(0x20, mul(i, 32))), word)
            }
        }
        return result;
    }
}