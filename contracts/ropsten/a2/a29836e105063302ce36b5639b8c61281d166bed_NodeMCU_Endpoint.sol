pragma solidity ^0.4.19;


contract NodeMCU_Endpoint {
    
    // Contains sender address and sensor value.
    struct dataBlock {
        uint16 value;  
        address sender;
    }
    
    // Address of the contract creator. Only the creator is allowed to send dataBlocks.
    address private creator;
    
    // Dynamic array of dataBlocks
    dataBlock[] public valueArray;
    
    // Defines the contract creator
    function costructor() public {
        creator = msg.sender;
    }

    // Allows the contract creator to send dataBlocks consisting of the sender&#39;s address and a sensor value in the range 0-1024.
    function Send_Data(address sender, uint16 amount) public {
        if (amount > 1024 || sender != creator) return;
        valueArray.push(dataBlock({
                value: amount,
                sender: sender
            }));
    }

    // Returns the latest sensor value that was stored.
    function Get_Last_Value() public
    returns (uint16 latestValue){
        latestValue = valueArray[valueArray.length].value;
    }
}