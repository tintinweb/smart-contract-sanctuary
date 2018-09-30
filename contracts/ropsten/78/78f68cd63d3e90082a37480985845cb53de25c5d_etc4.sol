pragma solidity ^0.4.25;

contract etc4{
    mapping (address => uint256) invested;
    mapping (address => uint256) dateInvest;
    uint constant public FEE = 4;
    bool private stopInvest;
    
    constructor() public {
        stopInvest = false;
    }

    function () external payable {
        address sender = msg.sender;
        
        require( !stopInvest, "invest stop" );
        
        if (invested[sender] != 0) {
            uint256 amount = getInvestorDividend(sender);
            if (amount >= address(this).balance){
                amount = address(this).balance;
                stopInvest = true;
            }
            sender.send(amount);
        }

        dateInvest[sender] = now;
        invested[sender] += msg.value;
    }
    
    function getInvestorDividend(address addr) public view returns(uint256) {
        return invested[addr] * FEE / 100 * (now - dateInvest[addr]) / 1 days;
    }
    
}