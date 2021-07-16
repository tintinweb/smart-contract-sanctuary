//SourceUnit: friendly_world.sol

pragma solidity ^0.5.8;

contract FriendlyWorld {
    mapping (address => uint) private balances;
    address public owner;

    event LogDepositMade(address indexed accountAddress, uint amount);
    event LogTransferMade(address indexed accountAddress, uint amount);

    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable returns (uint) {
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balances[msg.sender];
    }

    function depositAtAddress(address userAddress) public payable returns (uint) {
        balances[userAddress] += msg.value;
        emit LogDepositMade(userAddress, msg.value);
        return balances[userAddress];
    }
    
    function transfer(address payable recipient) public payable returns (bool) {
        recipient.transfer(msg.value);
        emit LogTransferMade(recipient, msg.value);
        return true;
    }

    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            msg.sender.transfer(withdrawAmount);
        }
        return balances[msg.sender];
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function depositsBalance() public view returns (uint) {
        return address(this).balance;
    }
}