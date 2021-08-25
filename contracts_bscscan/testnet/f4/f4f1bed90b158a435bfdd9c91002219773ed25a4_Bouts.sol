/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;


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

contract Bouts {
    
    address private owner;
    address private contractAddr = address(this);
    address private claimTokenAddress;
    bool private claimStatus;
    BEP20 token;
    struct User {
        uint maxAmount;
        uint alloc;
    }
    
    mapping(address => User) private user;
    
    event Received(address, uint);
    
    constructor() {
        token = BEP20(0x1C3E03875839009dd6dE9eA0aAc4bD516e61cA71);
        claimStatus = false;
    }
    
    // Deposit Boutspro token for Bouts9 allocation
    function deposit(uint nineAmt, uint price) public {
        address sender = msg.sender;
        User storage dep = user[sender];
        uint amount = nineAmt / price;
        dep.alloc += nineAmt;
        dep.maxAmount = 9000 * 10**18;
        dep.maxAmount -= nineAmt;
        require(dep.maxAmount >= nineAmt, "Maximum allocation reached");
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        token.transferFrom(sender, contractAddr, amount);
    }
    
    // View Allocation
    function getAllocation(address addr) public view returns (uint) {
        return user[addr].alloc;
    }
    
    // View claim token address 
    function getClaimToken() public view returns (address) {
        return claimTokenAddress;
    }
    
    // Claim Allocation
    function claim() public {
        address rec = msg.sender;
        User storage dep = user[rec];
        require(dep.alloc > 0, "Zero Allocation error");
        require(claimStatus == true, "Claim not activated");
        require(claimTokenAddress != address(0), "Claim Token Address not set");
        BEP20 _token = BEP20(claimTokenAddress);
        uint amount = dep.alloc;
        _token.transfer(rec, amount);
        dep.alloc = 0;
    }
    
    // Set claim status 
    // Only owner can call this function
    function setClaimStatus(bool val) public {
        require(msg.sender == owner, "Only owner can call this function");
        claimStatus = val;
    }
    
    // View owner 
    function getOwner() public view returns (address) {
        return owner;
    }
    
    // View claimStatus
    function getClaimStatus() public view returns (bool) {
        return claimStatus;
    }
    
    // Transfer ownership 
    // Only owner can call 
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
    }
    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }
    
    // Owner BNB withdrawal
    function ownerBnbWithdraw(uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}