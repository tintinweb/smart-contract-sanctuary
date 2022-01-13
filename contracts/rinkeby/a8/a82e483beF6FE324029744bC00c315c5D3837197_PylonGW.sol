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

    event DataLog (address from, Data _data);

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
            emit DataLog(msg.sender, _data);
        }

        
    }

    function getData() public view returns (Data[] memory) {
        return data;
    }

    
    function getDataRange(uint32 start, uint32 end) public view returns (Data[] memory) {
        int16 startIndex = -1; 
        int16 endIndex = -1;
        uint16 i = 0;
        while (startIndex == -1 && i < data.length) {
            if (start <= data[i].timestamp) {
                if (i == 0) {
                    startIndex = 0;
                } else {
                    startIndex = int16(i);
                }
            } else {
                i++;
            }
        }
        while (endIndex == -1 && i < data.length) {
            if (end < data[i].timestamp) {
                if (i == 0) {
                    endIndex = 0;
                } else {
                    endIndex = int16(--i);
                }
            } else if (end == data[i].timestamp) {
                endIndex = int16(i);
            } else {
                i++;
            }
        }         
        if (startIndex < 0) {
            startIndex = 0;
        }
        if (endIndex < 0) {
            endIndex = int16(data.length - 1);
        }
        uint16 size = uint16(endIndex) - uint16(startIndex) + 1;
        Data[] memory dataRange = new Data[](size); 
        uint16 j = 0;
        for(uint16 n = uint16(startIndex); n <= uint16(endIndex); n++) {
            dataRange[j] = data[n];
            j++;
        }
        return dataRange;
    }
}