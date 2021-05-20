/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity ^0.8.4;

contract MultiSigWallet {
    address[] walletAddresses;
    mapping (address => bool) isOwner;
    mapping (address => uint) transaction;
    mapping (address => pendingTransaction) votes;
    mapping (address => uint) ownerIndex;
    struct pendingTransaction {
        address payable destination;
        uint256 amount;
        bool[] signed;
        uint nVotes;
    }
    
    constructor () {
        walletAddresses.push(msg.sender);
        isOwner[msg.sender] = true;
        ownerIndex[msg.sender] = walletAddresses.length;
    }
    
    function AddOwner(address _address) public{
        require(isOwner[msg.sender]);
        walletAddresses.push(_address);
        isOwner[_address] = true;
        ownerIndex[_address] = walletAddresses.length;
    }
    function AddFunds () payable public{}
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    
    function RequestTransaction(address payable _destaddress, uint256 _amount) public {
        require(isOwner[msg.sender]);
        if (transaction[_destaddress] == _amount) {
            pendingTransaction memory pendingTransaction_Temp;
            pendingTransaction_Temp.destination = _destaddress;
            pendingTransaction_Temp.amount = _amount;
            pendingTransaction_Temp.signed[ownerIndex[msg.sender]] = true;
            votes[_destaddress] = pendingTransaction_Temp;
            votes[_destaddress].nVotes += 1;
            if (votes[_destaddress].nVotes == walletAddresses.length) {
                _destaddress.transfer(_amount);
                pendingTransaction memory newPending;
                votes[_destaddress] = newPending;
            }
        }
        else {    
            transaction[_destaddress] = _amount;
            votes[_destaddress].nVotes = 1;
        }    
    }
}