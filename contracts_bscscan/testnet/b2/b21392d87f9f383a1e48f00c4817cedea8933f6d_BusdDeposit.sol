/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.7;

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BusdDeposit {
    
    address public owner;
    uint private minLimit;
    uint private maxLimit;
    struct Deposit {
        uint[] amounts;
        uint[] times;
    }
    
    // BEP20 busd = BEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD address mainnet
    BEP20 busd = BEP20(0x14e83f967C52764F7F1402bc5d867836C092F7f9); // BUSD address testnet
    mapping(address => Deposit) private dep;
    
    event OwnershipTransferred(address to);
    event Received(address, uint);
    
    constructor() {
        owner = msg.sender;
        minLimit = 100 * 10**18;
        maxLimit = 1000 * 10**18;
    }
    
    function deposit(uint amount) public {
        require(amount >= minLimit && amount <= maxLimit, "Can only deposit more than 100 or less than 1000");
        require(busd.balanceOf(msg.sender) >= amount, "Sender does not have enough balance");
        busd.transferFrom(msg.sender, address(this), amount);
        dep[msg.sender].amounts.push(amount);
        dep[msg.sender].times.push(block.timestamp);
    }
    
    function viewDeposits(address addr) public view returns(uint[] memory amt, uint[] memory at) {
        uint len = dep[addr].amounts.length;
        amt = new uint[](len);
        at = new uint[](len);
        for(uint i = 0; i < len; i++){
            amt[i] = dep[addr].amounts[i];
            at[i] = dep[addr].times[i];
        }
        return (amt,at);
    }
    
    // Transfer ownership 
    // Only owner can do that
    function ownershipTransfer(address to) public {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Zero address error");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) public {
        require(msg.sender == owner, "Only owner");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }
    
    // Owner BNB withdrawal
    function ownerBnbWithdraw(uint amount) public {
        require(msg.sender == owner, "Only owner");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}