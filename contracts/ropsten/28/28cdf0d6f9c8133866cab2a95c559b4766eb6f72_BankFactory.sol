pragma solidity ^0.4.24;

contract BankFactory {
    function createNormalBank() public returns (address){
        Checkable bank = new NormalBank();
        return bank;
    }
    
    function createDonationsBank() public returns (address){
        IBank bank = new DonationsBank();
        return bank;
    }
}

contract IBank {
    function deposit() public payable;
    function withdrawl(uint256 _amount) public payable;
    function getBalance() view public returns (uint256);
}

contract Checkable is IBank {
    function balanceOf(address _of) public view returns (uint256);
}

contract AbstractBank is IBank {
    
    address internal owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function getOwner() view public returns (address) {
        return owner;
    }
}

contract DonationsBank is AbstractBank {
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    event Donation(address donator, uint256 amount);
    
    //Makes a donation
    function deposit() public payable {
        require(address(this).balance + msg.value >= msg.value);
        emit Donation(msg.sender, msg.value);
    }
    
    function withdrawl(uint256 _amount) public payable onlyOwner {
        require(address(this).balance >= _amount);
        owner.transfer(_amount);
    }
    
    function getBalance() view public returns (uint256){
        return address(this).balance;
    }
}

contract NormalBank is AbstractBank, Checkable {
    
    mapping(address => uint256) private balances;
    
    event Deposit(address depositor, uint256 amount);
    
    function deposit() public payable {
        require(balances[msg.sender] + msg.value >= msg.value);
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdrawl(uint256 _amount) public payable {
        require(balances[msg.sender] >= _amount);
        msg.sender.transfer(_amount);
    }
    
    function getBalance() view public returns (uint256) {
        return balances[msg.sender];
    }
    
    function balanceOf(address _of) public view returns (uint256){
        return balances[_of];
    }
}