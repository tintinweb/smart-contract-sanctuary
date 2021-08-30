/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity 0.5.16;

contract SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
}

contract solidityBasic is SafeMath {
    // Simple banking smart contract where it can deposit and withdraw ETH.
    event Deposit(address from, uint aount); // Declares an event
    
    address payable owner;
    address payable withdrawAddr;
    address[] public depositors; // an array that stores all the depositor addresses
    uint public totalDeposits = 0; // total amount of deposit
    
    constructor(address payable _withdrawAddr) payable public {
        owner = msg.sender;
        withdrawAddr = _withdrawAddr;
    }
    
    modifier onlyOwner() {
        require (msg.sender == owner); // error handling
        _;
    }

    function deposit() public payable { // payable enables smart contract to receive ETH from a user.
        require(msg.value > 0, "Your deposit amount must be greater than zero."); // error handling
        depositors.push(msg.sender);
        totalDeposits = add(totalDeposits, msg.value);
        
        emit Deposit(msg.sender, msg.value); // Emits an event
    }

    function withdraw(uint amount) public payable onlyOwner {
        // check if the withdrawl amount doesn't exceed the balance(=totalDeposits)
        if (msg.value <= totalDeposits) {
            msg.sender.transfer(amount);
            totalDeposits = totalDeposits - msg.value;
        }
        else {
            // there is not enough balance to withdraw the requested amount from the user wallet.
            // I'm assuming there is no return type for this case, thus empty statement.
        }
    }
}