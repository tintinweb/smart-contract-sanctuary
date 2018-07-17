pragma solidity ^0.4.22;

contract Auction {
    struct Account {
        uint askPrice;
        uint balance;
        uint ethBalance;
        
        uint bufindex; // Index into an array of accounts for enumeration
    }
    
    mapping (address => Account) accounts;
    
    function askPrice(address a) public view returns(uint) {
        return accounts[a].askPrice;
    }
    
    function balanceOf(address a) public view returns(uint) {
        return accounts[a].balance;
    }
    function ethBalanceOf(address a) public view returns(uint) {
        return accounts[a].ethBalance;
    }
    
    // Hack to modify amount
    
    function _setBalance(address a, uint amount, uint _askPrice) public {
        accounts[a].balance = amount;
        accounts[a].askPrice = _askPrice;
            
            
        if (accounts[a].bufindex == 0) {
            // New account, append it 
            accounts[a].bufindex = accountList.length + 1;
            accountList.push(a);
        }
    }
    
    // Handling lists of accounts to support enumeration
    address[] public accountList; // Accounts that have nonzero quantity
    
    function numAccounts() public view returns(uint) {
        return accountList.length;
    }
    
    function () public payable {
    }
}