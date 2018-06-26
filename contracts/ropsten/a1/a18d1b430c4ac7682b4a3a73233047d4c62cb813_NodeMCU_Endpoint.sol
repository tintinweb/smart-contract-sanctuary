pragma solidity ^0.4.19;

// This contact receives values from 0-1024 from the contract creator and stores them in a dynamic array.
contract NodeMCU_Endpoint {
    
    // Contains sender address and sensor value.
    struct dataBlock {
        address sender;
        uint16 value;  
    }
    
    // Latest received value as public integer for easy block explorer access.
    uint16 public latestReceivedValue;
    
    // Address of the contract creator. Only the creator is allowed to send dataBlocks.
    address private creator;
    
    // Dynamic array of dataBlocks
    dataBlock[] public valueArray;
    
    // Create event log for each sent value.
    event OnSendData(address sender, uint16 sentValue);
    
    // Defines the contract creator
    function costructor() private {
        creator = msg.sender;
    }

    // Allows the contract creator to send a sensor value in the range 0-1024. Gets stored in data block together with contract creator&#39;s address.
    function Send_Data(uint16 amount) public {
        //if (amount > 1024 || msg.sender != creator) return;
        dataBlock memory newEntry = dataBlock({
            sender: msg.sender,
            value: amount
        }); 
        valueArray.push(newEntry);
        latestReceivedValue = valueArray[valueArray.length - 1].value;
        OnSendData(msg.sender, amount);
    }

    // Returns the latest sensor value that was stored.
    function Get_Last_Value() public view returns (uint16) {
        if (valueArray.length == 0) return 0;
        return valueArray[valueArray.length - 1].value;
    }
}