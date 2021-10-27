/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BecomeHippiesInvestment {
    
    struct Dividend {
        uint amount;
        DividendBeneficiary[] beneficiaries;
        mapping (address => bytes32) transactions;
    }
    
    struct DividendBeneficiary {
        address to;
        uint amount;
    }
    
    mapping (bytes32 => Dividend) private dividends;
    mapping (address => uint) private balances;
    mapping (address => bool) private addresses;
    mapping (bytes32 => bool) private presales;
    mapping (address => mapping (address => uint)) private allowance;
    
    address[] private users;
    
    uint public totalSupply = 60000 * 10 ** 18;
    uint public decimals = 18;
    
    string public name = "Become Hippies Test Token";
    string public symbol = "BHTT";
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address user) public view returns (uint) {
        return balances[user];
    }
    
    function addToBalance(address user, uint value) private {
        balances[user] += value;
        if (user != msg.sender && !addresses[user]) {
            users.push(user);
        }
    }
    
    function addDividend(bytes32 hash, uint amount) public returns (DividendBeneficiary[] memory) {
        Dividend storage dividend = dividends[hash];
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            dividend.beneficiaries.push(DividendBeneficiary(user, amount * balances[user] / totalSupply));
        }
        return dividend.beneficiaries;
    }
    
    function getBeneficiaries(bytes32 hash) public view returns (DividendBeneficiary[] memory) {
        return dividends[hash].beneficiaries;
    }
    
    function addTransaction(bytes32 hash, address user, bytes32 transaction) public {
        dividends[hash].transactions[user] = transaction;
    }
    
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        addToBalance(to, value);
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function preSale(address to, uint value, bytes32 hash) public returns (bool) {
        require(presales[hash] == false, "Presale exist");
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        presales[hash] = true;
        addToBalance(to, value);
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function getTotalTransferFrom(uint value) private pure returns (uint) {
        return value + value * 20 / 100;
    }
    
    function TransferFrom(address from, address to, uint value) public returns (bool) {
        
        uint total = getTotalTransferFrom(value);
        
        require(balanceOf(from) >= total, "Insufficient balance");
        require(allowance[msg.sender][from] >= value, "Insufficient allowance");
        
        balances[from] -= total;
        
        uint amount = total - value;
        uint supply = 0;
        
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            if (user != from) {
                supply += balances[users[i]];
            }
        }
        
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            if (user != from) {
                balances[user] += amount * balances[user] / supply;
            }
        }
        
        
        addToBalance(to, value);
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        uint total = getTotalTransferFrom(value);
        require(balanceOf(spender) >= total, "Insufficient balance");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}