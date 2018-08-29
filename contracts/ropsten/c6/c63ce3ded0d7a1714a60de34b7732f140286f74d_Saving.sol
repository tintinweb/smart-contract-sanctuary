pragma solidity ^0.4.24;

contract Saving {
    
    struct Record {
        uint amount;
        uint time;
        address addr;
    }
    
    mapping(address => int) canWidthdraw;
    address public owner;
    Record[] records;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function register(address _addr) {
        if (msg.sender == owner) {
            canWidthdraw[_addr] = 1;
        }
    }
    
    // cun
    function deposit() payable {}
    
    // qu
    function widthdraw(uint amount) {
        if (canWidthdraw[msg.sender] == 0) {
            return;
        }
        
        if (howMuchWithdrawed() >= 5 * 1 ether) {
            return;
        }
        
        msg.sender.transfer(amount * 1 ether);
        
        Record memory record = Record({
            amount: amount * 1 ether,
            time: now,
            addr: msg.sender
        });
        
        records.push(record);
    }
    
    function howMuchWithdrawed() public returns(uint) {
        uint sum;
        for (uint i = 0; i < records.length; i++) {
            Record record = records[i];
            if (now - record.time < 1 days) {
                sum = sum + record.amount;
            }
        }
        return sum;
    }
    
    // yu e
    function getBalance() returns(uint) {
        return this.balance / 1 ether;
    }
    
    
    function getBalance2() view returns(uint) {
        return address(this).balance / 1 ether;
    }
}