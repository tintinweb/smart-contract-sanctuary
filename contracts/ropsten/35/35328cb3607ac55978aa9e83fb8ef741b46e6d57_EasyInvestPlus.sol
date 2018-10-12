pragma solidity ^0.4.25;


contract EasyInvestPlus {
    address fund;
    mapping (address => uint) b; // investors balances
    mapping (address => uint) ib; // block number at last investment
    mapping (address => uint) refs; // referral commissions
    
    constructor () public {
        fund = msg.sender;
        b[fund] = 0;
        ib[fund] = block.number;
    }
    
    function () external payable {
        payment();
    }
    
    function payWithRef (address ref) public payable {
        payment();
        refs[ref] += msg.value / 10;
    }
    
    function payment () private {
        address sender = msg.sender;
        uint amount = msg.value;
        if (b[sender] > 0) { sender.transfer(countPayment(sender)); }
        ib[sender] = block.number;
        b[sender] += amount;
        refs[fund] += amount / 20;
    }
    
    function withdrawRC () public {
        if (refs[msg.sender] > 0) {
            address refAddress = msg.sender;
            uint amount = refs[refAddress];
            refs[refAddress] = 0;
            refAddress.transfer(amount);
        }
    }
    
    function countPayment (address sender) public view returns (uint) {
        return b[sender] * 3 / 100 * (block.number - ib[sender]) / 6000;
    }
    
    function countRC (address refAddress) public view returns (uint) {
        return refs[refAddress];
    }
}