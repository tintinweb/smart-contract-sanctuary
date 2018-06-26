pragma solidity ^0.4.19;

// This contract receives values from 0-1024 from the contract creator and stores them
// in a dynamic array together with the senders address.
contract NodeMCU_Endpoint {
    
    // Struct containing sender address and sensor value.
    struct dataBlock {
        address sender;
        uint16 value;  
    }
    
    // Address of the contract creator. Only the creator is allowed to send values.
    address private creator;
    
    // Dynamic array of dataBlocks
    dataBlock[] public valueArray;
    
    // Modifier allowing only the contract creator to call a function.
    modifier onlyOwner() {
    require(msg.sender == creator);
    _;
    }
    
    // Create event log for each sent value.
    event OnSendData(address sender, uint16 sentValue);
    
    // Constructor defining the contract creator.
    function NodeMCU_Endpoint() public {
        creator = msg.sender;
    }

    // Allows the contract creator to send a sensor value in the range 0-1024.
    // The value gets stored in a data block together with contract creator&#39;s address.
    function Send_Data(uint16 amount) public onlyOwner {
        if (amount > 1024) return;
        valueArray.push(dataBlock({
            sender: msg.sender,
            value: amount
            }));
        OnSendData(msg.sender, amount);
    }

    // Returns the latest sensor value that was stored.
    function Get_Last_Value() public view returns (uint16) {
        if (valueArray.length == 0) return;
        return valueArray[valueArray.length - 1].value;
    }
}