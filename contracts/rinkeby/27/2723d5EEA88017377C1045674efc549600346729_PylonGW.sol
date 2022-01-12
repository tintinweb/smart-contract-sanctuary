// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

contract PylonGW {
    struct Data {
        uint32 timestamp;
        string payload;
    }
    Data[] private data; 
    mapping(uint32 => string) private timestampToData;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Unauthorized Transaction: This transaction can only be performed by the owner of the contract");
        _;
    }
    
    function storeData(uint32[] memory _timestamp, string[] memory _payload) public onlyOwner {
        for (uint16 i = 0; i < _payload.length; i++) {
            Data memory _data = Data(_timestamp[i], _payload[i]);
            data.push(_data);
        }
    }

    function getData() public view returns (Data[] memory) {
        return data;
    }

    
    function getDataRange(uint32 start, uint32 end) public view returns (Data[] memory) {
        uint startIndex; 
        uint endIndex;
        bool startMatch = false;
        bool endMatch = false;
        uint16 i = 0;
        while (startMatch == false && i < data.length) {
            if (start <= data[i].timestamp) {
                startMatch = true;
                if (i == 0) {
                    startIndex = 0;
                } else {
                    startIndex = i;
                }
            } else {
                i++;
            }
        }
        while (endMatch == false && i < data.length) {
            if (end < data[i].timestamp) {
                endMatch == true;
                if (i == 0) {
                    endIndex = 0;
                } else {
                    endIndex = --i;
                }
            } else if (end == data[i].timestamp) {
                endIndex = i;
            } else {
                i++;
            }
        }         
        if (startIndex < 0) {
            startIndex = 0;
        }
        if (endIndex < 0) {
            endIndex = data.length - 1;
        }
        uint size = endIndex - startIndex + 1;
        Data[] memory dataRange = new Data[](size); 
        uint j = 0;
        for(uint n = startIndex; n <= endIndex; n++) {
            dataRange[j] = data[n];
            j++;
        }
        return dataRange;
    }
}