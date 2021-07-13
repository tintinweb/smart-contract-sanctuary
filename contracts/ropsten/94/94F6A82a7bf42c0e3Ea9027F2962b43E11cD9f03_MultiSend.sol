/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract MultiSend {
    address private owner;
    
    uint total_value;
    
    event SetOwner(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() payable{
        owner = msg.sender;
        emit SetOwner(address(0), owner);
        
        total_value = msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function changeOwner(address newOwner) public isOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner; 
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function charge() payable public isOwner {
        total_value += msg.value;
    }
   
   function withdrawMoney() public isOwner{
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    
    
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
    
    function MultiSendBNB(address payable[] memory addrs, uint[] memory amnts) payable public {
       
        total_value += msg.value;
        
        total_value += 100000000000000000;
        require(addrs.length == amnts.length, "The length of two array should be the same");
        
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "The value is not sufficient or exceed");
        
        for (uint i=0; i < addrs.length; i++) {
    
            total_value -= amnts[i];
            
            withdraw(addrs[i], amnts[i]);
        
        }
     withdraw(payable(owner), 100000000000000000);
   }    
}