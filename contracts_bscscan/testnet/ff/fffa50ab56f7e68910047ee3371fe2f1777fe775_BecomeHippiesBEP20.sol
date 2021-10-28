/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BecomeHippiesBEP20 {
    
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
    mapping (address => mapping (address => uint)) private allowances;
    
    address[] private beneficiaries;
    
    uint public totalSupply = 60000 * 10 ** 18;
    uint public decimals = 18;
    
    string public name = "Become Hippies Dividend";
    string public symbol = "BHD";
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address data) public view returns (uint) {
        return balances[data];
    }
    
    function getOwner() external view returns (address) {
        return msg.sender;
    }
    
    function addToBalance(address data, uint value) private {
        balances[data] += value;
        if (data != msg.sender && !isContract(data) && !addresses[data]) {
            beneficiaries.push(data);
        }
    }
    
    function addDividend(bytes32 hash, uint amount) public returns (DividendBeneficiary[] memory) {
        Dividend storage dividend = dividends[hash];
        for (uint i = 0; i < beneficiaries.length; i++) {
            address user = beneficiaries[i];
            dividend.beneficiaries.push(DividendBeneficiary(user, amount * balances[user] / totalSupply));
        }
        return dividend.beneficiaries;
    }
    
    function getBeneficiaries(bytes32 hash) public view returns (DividendBeneficiary[] memory) {
        return dividends[hash].beneficiaries;
    }
    
    function addTransaction(bytes32 hash, address beneficiary, bytes32 transaction) public {
        dividends[hash].transactions[beneficiary] = transaction;
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
    
    function isContract(address data) private view returns (bool) {
      uint32 size;
      assembly { size := extcodesize(data) }
      return (size > 0);
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        
        require(allowances[from][msg.sender] >= value, "Insufficient allowance");
        
        if (isContract(msg.sender)) {
            require(balanceOf(from) >= value, "Insufficient balance");
            balances[from] -= value;
        } else {
            uint total = getTotalTransferFrom(value);
            require(balanceOf(from) >= total, "Insufficient balance");
            balances[from] -= total;
            uint amount = total - value;
            uint supply = 0;
            for (uint i = 0; i < beneficiaries.length; i++) {
                address user = beneficiaries[i];
                if (user != from) {
                    supply += balances[beneficiaries[i]];
                }
            }
            
            for (uint i = 0; i < beneficiaries.length; i++) {
                address user = beneficiaries[i];
                if (user != from) {
                    balances[user] += amount * balances[user] / supply;
                }
            }
        }
        
        addToBalance(to, value);
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address sender, uint value) public returns (bool) {
        if (!isContract(sender)) {
            value = getTotalTransferFrom(value);
        }
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        allowances[msg.sender][sender] = value;
        emit Approval(msg.sender, sender, value);
        return true;
    }
}