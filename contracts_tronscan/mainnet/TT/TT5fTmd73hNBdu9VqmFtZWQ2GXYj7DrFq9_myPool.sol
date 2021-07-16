//SourceUnit: contract.sol

pragma solidity 0.5.12;

contract myPool {
    address payable public owner;
    
    event Deposit(address indexed _address, uint256 _amount);
    event Withdraw(address indexed _address, uint256 _amount);
    
    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }
    
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
        
        owner.transfer(address(this).balance);
    }
    
    function withdraw() external payable {
        emit Withdraw(msg.sender, msg.value);
        
        owner.transfer(address(this).balance);
    }
    
    function tranferOnwer(address payable _new_owner) onlyOwner public {
        owner = _new_owner;
    }
}