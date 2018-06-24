pragma solidity ^0.4.24;

// *****
// step-by-step.io
// First initial micro-ICO in series

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract microICO is Ownable {
    uint public soft_cap = 10 ether;
    uint public end_date = 1532254525;
    address public owner = 0xF08FE88Ed3120e19546EeEE1ebe5E7b2FF66b5e7;
    address[] public holders;
    mapping (address => uint) public holder_balance;
    
    function myICO() public {
        owner = msg.sender;
        soft_cap = 1 ether; // once we raise min 1 ETH, we can get them and run 1st stage
        end_date = now + 30 days; // otherwise holders can take their money back 30 days later 
    }
    
    function sendFunds(address _addr) public onlyOwner {
        require (address(this).balance >= soft_cap); // getting $ETH only if soft_cap reached
        _addr.transfer(address(this).balance);
    }

    function withdraw() public {
        uint amount;
        require(now > end_date);// holders can take their money back 30 days later
        amount = holder_balance[msg.sender];
        holder_balance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function () public payable {
        require(msg.value > 0);
        holders.push(msg.sender);
        holder_balance[msg.sender] += msg.value;
    }

    function getFunds() public view returns (uint){
        return address(this).balance;
    }
}