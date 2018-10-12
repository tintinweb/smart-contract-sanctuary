pragma solidity ^0.4.25;

contract trusteth{
    mapping (address => uint256) invested;
    mapping (address => uint256) dateInvest;
    uint constant public FEE = 4;
    uint constant public ADMIN_FEE = 4;
    address private adminAddr;
    
    constructor() public{
        adminAddr = msg.sender;
    }

    function () external payable {
        address sender = msg.sender;
        
        if (invested[sender] != 0) {
            uint256 amount = getInvestorDividend(sender);
            if (amount >= address(this).balance){
                amount = address(this).balance;
            }
            sender.send(amount);
        }

        dateInvest[sender] = now;
        invested[sender] += msg.value;

        if (msg.value > 0){
            adminAddr.send(msg.value * ADMIN_FEE / 100);
        }
    }
    
    function getInvestorDividend(address addr) public view returns(uint256) {
        return invested[addr] * FEE / 100 * (now - dateInvest[addr]) / 1 days;
    }

}