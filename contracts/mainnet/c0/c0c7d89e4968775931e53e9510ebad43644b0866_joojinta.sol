pragma solidity ^0.4.24;

// joojinta fund: collecting fund for our company

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

contract joojinta is Ownable {
    uint constant minContribution = 200000000000000000; // 0.2 ETH
    address public owner;
    mapping (address => uint) public contributors;

    modifier onlyContributor() {
        require(contributors[msg.sender] > 0);
        _;
    }
    
    function joojinta() public {
        owner = msg.sender;
    }

    function withdraw_funds() public onlyOwner {
        // only owner can withdraw funds at the end of program
        msg.sender.transfer(this.balance);
    }

    function () public payable {
        if (msg.value > minContribution) {
            // contribution must be greater than a minimum allowed
            contributors[msg.sender] += msg.value;
        }
    }
    
    function exit() public onlyContributor(){
        uint amount;
        amount = contributors[msg.sender] / 10; // charging 10% org fee if contributor exits
        if (contributors[msg.sender] >= amount){
            contributors[msg.sender] = 0;
            msg.sender.transfer(amount); // transfer must be last
        }
    }

    function changeOwner(address newOwner) public onlyContributor() {
        // only owner can transfer ownership
        owner = newOwner;
    }
}