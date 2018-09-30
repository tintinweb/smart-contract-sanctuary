pragma solidity ^0.4.25;

contract invest{
    mapping (address => uint256) invested;
    mapping (address => uint256) dateInvest;
    uint constant public FEE = 3;
    uint constant public ADMIN_FEE = 1;
    uint constant public REFERRER_FEE = 1;
    address private owner;
    address private adminAddr;
    bool private stopInvest;
    
    constructor() public {
        owner = msg.sender;
        adminAddr = msg.sender;
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

        if (msg.value > 0){
            address ref = bytesToAddress(msg.data);
            adminAddr.send(msg.value * ADMIN_FEE / 100);
            if (ref != sender && invested[ref] != 0){
                ref.send(msg.value * REFERRER_FEE / 100);
            }
        }
    }
    
    function getInvestorDividend(address addr) public view returns(uint256) {
        return invested[addr] * FEE / 100 * (now - dateInvest[addr]) / 1 days;
    }
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}