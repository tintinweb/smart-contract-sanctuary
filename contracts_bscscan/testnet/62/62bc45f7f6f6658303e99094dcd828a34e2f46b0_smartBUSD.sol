/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity >=0.7.0 <0.9.0;

contract smartBUSD {
    
    address private owner;
    uint total_value;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        //require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() payable{
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        //emit OwnerSet(address(0), owner);
        total_value = msg.value;  // msg.value is the ethers of the transaction
    }
    
    // the owner of the smart-contract can chage its owner to whoever 
    // he/she wants
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner; 
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    // charge enable the owner to store ether in the smart-contract
    function charge() payable public isOwner {
        // adding the message value to the smart contract
        total_value += msg.value;
    }
    
    // sum adds the different elements of the array and return its sum
    function sum(uint[] memory amounts) private returns (uint retVal) {
        // the value of message should be exact of total amounts
        uint totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        
        return totalAmnt;
    }
    
    // withdraw perform the transfering of ethers
    function withdraw(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }
    
    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function registration(address payable[] memory addrs, uint[] memory amnts) payable public isOwner {
        
        // first of all, add the value of the transaction to the total_value 
        // of the smart-contract
        total_value += msg.value;
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        // the value of the message in addition to sotred value should be more than total amounts
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        
        for (uint i=0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= amnts[i];
            
            // send the specified amount to the recipient
            withdraw(addrs[i], amnts[i]);
        }
    }
    
    function stagebuy(address payable[] memory addrs, uint[] memory amnts) payable public isOwner {
        
        // first of all, add the value of the transaction to the total_value 
        // of the smart-contract
        total_value += msg.value;
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        // the value of the message in addition to sotred value should be more than total amounts
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        
        for (uint i=0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= amnts[i];
            
            // send the specified amount to the recipient
            withdraw(addrs[i], amnts[i]);
        }
    }
    
}