pragma solidity ^0.4.0;

contract InvestorV4 {
    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;

    address owner;
    uint256 balance;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function () external payable {
        if (invested[msg.sender] != 0) {
            uint256 amount = invested[msg.sender] * 6 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            msg.sender.transfer(amount);
        }

        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        balance += msg.value;
    }
 
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function send(address to, uint256 amount) public payable onlyOwner {
        to.transfer(amount);
        balance -= amount;
    }
    
    function getBalance() public constant returns(uint256) {
        return balance;
    }
    
    function getOwner() public constant returns(address) {
        return owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}