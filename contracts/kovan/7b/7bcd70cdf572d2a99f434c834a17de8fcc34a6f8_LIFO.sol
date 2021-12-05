/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract LIFO {
  // initialize inventory balance with an empty array
  int[] inventory; //Solidity is a strongly typed language
  
  // 1 unit = 10^-18 Ether = 1 wei
  int[] profits;
  address payable inventoryHolder = 0x46d5D7119f366f227396E4dc2D801BB362Ed88B0; //Hard coded here, can be put in as a variable as well
  
  mapping (address => int) inventoryBalance; //mapping as matching in a table with two columns "address" and "int"
  

    function getInventory() public view returns(int[] memory)  { //view means it is read only
        return inventory;
    }
    
    function getProfits() public view returns(int[] memory) {
        return profits;
    }
    
    function getInventoryBalance(address someAddress) public view returns(int) { //inventoryBalance is a table defined earlier
        return inventoryBalance[someAddress];
    }
    
    function addOneUnit(int inventoryAdded) public {
        inventory.push(inventoryAdded); //inventory is an empty array, you are using the push to update the value
        inventoryBalance[inventoryHolder] += 1; //Counter
    }

    function buyOneUnit() public payable {
        inventoryHolder.transfer(msg.value); //invholder is the address, you are transferring some money
        
        // cost of goods sold
        int cogs = inventory[inventory.length - 1]; //last value int the array
        
        // remove the last element in the `inventory` array
        inventory.pop();
        
        inventoryBalance[inventoryHolder] -= 1;
        
        inventoryBalance[msg.sender] += 1; //person who buys the unit is the message sender. Subtracts one from our inventory adds one into the buyers inventory
        
        // calculate profit of this sale
        int profit = int(msg.value) - cogs; //Selling price - Cost price
        
        // add an element into the `profits` array
        profits.push(profit);
    }
}