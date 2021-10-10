/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract LIFO {
  // initialize inventory balance with an empty array
  int[] inventory;
  
  // 1 unit = 10^-18 Ether = 1 wei
  int[] profits;
  address payable inventoryHolder = 0x46d5D7119f366f227396E4dc2D801BB362Ed88B0;
  
  mapping (address => int) inventoryBalance;
  

    function getInventory() public view returns(int[] memory) {
        return inventory;
    }
    
    function getProfits() public view returns(int[] memory) {
        return profits;
    }
    
    function getInventoryBalance(address someAddress) public view returns(int) {
        return inventoryBalance[someAddress];
    }
    
    function addOneUnit(int inventoryAdded) public {
        inventory.push(inventoryAdded);
        inventoryBalance[inventoryHolder] += 1;
    }

    function buyOneUnit() public payable {
        inventoryHolder.transfer(msg.value);
        
        // cost of goods sold
        int cogs = inventory[inventory.length - 1];
        
        // remove the last element in the `inventory` array
        inventory.pop();
        
        inventoryBalance[inventoryHolder] -= 1;
        
        inventoryBalance[msg.sender] += 1;
        
        // calculate profit of this sale
        int profit = int(msg.value) - cogs;
        
        // add an element into the `profits` array
        profits.push(profit);
    }
}