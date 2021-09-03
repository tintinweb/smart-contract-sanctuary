/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

//SPDX-License-Identifier: none
pragma solidity ^0.8.6;

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract DoracakeTransfer {
    
    address private owner;
    address private withdrawSetter;
    address contractAddress = address(this);
    BEP20 token;
    
    struct Deposit {
        uint amount;
        uint withdrawable;
    }
    
    mapping(address => Deposit) user;
    
    event Deposited(address, uint);
    event Received(address, uint);
    event OwnershipTransferred(address from, address to);
    
    constructor(address _token) {
        token = BEP20(_token);
        owner = msg.sender;
    }
    
    // Deposit token on the contract
    // User has to approve the contract from token contract 
    function deposit(uint amount) public {
        address sender = msg.sender;
        token.approve(contractAddress, amount);
        token.transferFrom(sender, contractAddress, amount);
        user[sender].amount = amount;
        emit Deposited(sender, amount);
    }
    
    // Set withdrawable amount for user
    // Only owner and withdrawSetter can call this function
    function updateWithdrawable(address addr, uint amount) public {
        address sender = msg.sender;
        require(sender == owner || sender == withdrawSetter, "Permission denied");
        user[addr].withdrawable = amount;
    }
    
    // View withdrawable amount 
    function viewWithdrawable(address addr) public view returns(uint) {
        return user[addr].withdrawable;
    }
    
    // Get owner 
    function getOwner() public view returns(address) {
        return owner;
    }
    
    // Withdraw amount for user 
    // Zero amount cannot be withdrawn
    function withdraw() public returns(bool) {
        address to = msg.sender;
        uint amount = user[to].withdrawable;
        require(amount != 0, "Zero amount error");
        token.transfer(to, amount);
        return true;
    }
    
    // Modifier for owner 
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Set address for withdrawSetter
    function setWithdrawSetter(address addr) public onlyOwner {
        withdrawSetter = addr;
    }
    
    // Get withdrawSetter
    function getWithdrawSetter() public view returns(address) {
        return withdrawSetter;
    }
    
    // Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    // Transfer Ownership to another address 
    // Cannot set Ownership to Zero address
    function transferOwnership(address to) public onlyOwner {
        require(to != address(0), "Cannot set to zero address");
        owner = to;
        emit OwnershipTransferred(msg.sender, to);
    }
    
    // Withdraw BNB from contract 
    // Only owner can call this function 
    function withdrawBnb(uint amount) public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(amount); 
    }
    
    // Withdraw any token from contract 
    // Only owner can call this function 
    function withdrawToken(address tokenAddress, uint amount) public onlyOwner {
        address to = msg.sender;
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
    }
}