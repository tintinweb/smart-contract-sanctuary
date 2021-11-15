// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface IPool {
    function getCardInfo(uint256 seed, uint256 chestType, uint256 minRarity) external view returns (uint256, string memory, string memory, uint256, uint256, string memory);
}

contract Greeting {
    string public greeting = "hello";
    event SetPool(address _setter, string indexed pool, address oldPoolAddress, address newPoolAddress);
    
    
    
    function sayHello() external view returns (string memory) {
        return greeting;
    }
    
    function updateGreeting(string calldata _greeting) external {

        greeting = _greeting;
    }
    
    
    IPool public EQUIPMENT_POOL;
    function setEquipmentPool(IPool _equipmentPool) public {
        emit SetPool(msg.sender, "equipment", address(EQUIPMENT_POOL), address(_equipmentPool));
        EQUIPMENT_POOL = _equipmentPool;
    }
    
}

