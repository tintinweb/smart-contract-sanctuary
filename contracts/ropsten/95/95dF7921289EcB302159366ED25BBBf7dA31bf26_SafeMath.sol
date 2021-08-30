/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity 0.5.16;

contract SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
}

contract SolidityBank is SafeMath {
    // Simple banking smart contract where it can deposit and withdraw ETH.
    event LogDeposit(address senderAddress, uint amount); // Declares an event
    
    address public owner;
    uint private numClient;
    mapping (address => uint) private deposits;
    
    constructor() public payable {
        owner = msg.sender;
        numClient = 0;
    }
    
    modifier onlyOwner() {
        require (msg.sender == owner); // error handling
        _;
    }

    function enrollClient() public returns (uint) {
        numClient++;
        deposits[msg.sender] = 1 ether;

        return deposits[msg.sender];
    }

    function deposit() public payable returns (uint) { // payable enables smart contract to receive ETH from a user.
        require(msg.value > 0, "Your deposit amount must be greater than zero."); // error handling
        deposits[msg.sender] = add(deposits[msg.sender], msg.value);
        emit LogDeposit(msg.sender, msg.value); // Emits an event

        return deposits[msg.sender];
    }

    function withdraw(uint amount) public onlyOwner returns (uint) {
        // check if the withdrawl amount doesn't exceed the balance(=totalDeposits)
        if (amount <= deposits[msg.sender]) {
            deposits[msg.sender] -= amount;
            msg.sender.transfer(amount);
        }
        return deposits[msg.sender];
    }

    // check the balance of the sender account
    function checkBalance() public view returns (uint) {
        return deposits[msg.sender];
    }

    // check the balance of the contract
    function checkBankBalance() public view returns (uint) {
        return address(this).balance;
    }
}