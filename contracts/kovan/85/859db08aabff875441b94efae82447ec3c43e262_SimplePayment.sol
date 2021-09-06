/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity ^0.8.0;

contract SimplePayment { 

    address public owner;
    
    struct Order {
        string no;
        uint256 total;
        uint256 dateTime;
    }
    mapping (address => Order[]) private orders;
    
    // Events - publicize actions to external listeners
    
    event PurchaseMade(address accountAddress, string no);
     
    constructor() { 
        owner = msg.sender; 
    } 
    
    function purchase(string memory no, uint256 total)
    public payable {
        Order memory order = Order(no, total, block.timestamp);
        orders[msg.sender].push(order);
        
        emit PurchaseMade(msg.sender, no);
    }
    
    function getAllOrder(address userAddress)
    public view returns (Order[] memory) {
        return orders[userAddress];
    }
    
    
}