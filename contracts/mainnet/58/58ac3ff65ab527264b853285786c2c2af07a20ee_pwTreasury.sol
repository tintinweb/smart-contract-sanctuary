/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// "SPDX-License-Identifier: MIT"
pragma solidity >=0.7.0 <0.9.0;

contract pwTreasury {
    address _host;
    address public thisAddress;

    bool blocked;

    uint nonce;
    
    struct transactionHistory{
        address sender;
        uint amount;
        uint date;
    }
    
    struct transactionHistoryUsers{
        uint[] amount;
        uint[] date;
    }

    mapping(uint => transactionHistory) transactions;
    mapping(address => transactionHistoryUsers) userTransactions;
    
    constructor(){
         nonce = 0;
        _host = msg.sender;
        thisAddress = address(this);
        blocked = false;
    }

    function transferOwnership(address newOwner) public isHost{
        _host = newOwner;
    }
    
   modifier isHost() {
        require(msg.sender == _host, "Only host can invoke this function");
        _;
    }

    modifier isBlocked() {
        require(blocked == false, "Smart contract has been temporary blocked");
        _;
    }
    
    function withdraw(address to, uint256 amount, address contractAddress) public isHost isBlocked {
        USDC coin = USDC(contractAddress);
        coin.transfer(to, amount);
        transactions[nonce].sender = msg.sender;
        transactions[nonce].amount = amount;
        transactions[nonce].date = block.timestamp;
        userTransactions[msg.sender].amount.push(amount);
        userTransactions[msg.sender].date.push(block.timestamp);
        nonce++;
    }

    function lockContract() public isHost {
        blocked = true;
    }

    function unlockContract() public isHost {
        blocked = false;
    }

    function getUserAmounts(address user) public view returns(uint[] memory){
        return userTransactions[user].amount;
    }
    
    function getUserDates(address user) public view returns(uint[] memory){
        return userTransactions[user].date;
    }
    
    function getSender(uint nounce) public view returns(address){
        return transactions[nounce].sender;
    }
    
    function getAmount(uint nounce) public view returns(uint){
        return transactions[nounce].amount;
    }
    
    function getDate(uint nounce) public view returns(uint){
        return transactions[nounce].date;
    }
}

abstract contract USDC {
    function transfer(address recipient, uint256 amount) virtual public returns (bool);
}