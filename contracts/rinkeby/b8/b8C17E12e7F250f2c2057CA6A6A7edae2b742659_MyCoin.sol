/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;

contract MyCoin {
    
    address private owner;
    
    uint total_value;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() payable{
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        
        total_value = msg.value;  // msg.value is the ethers of the transaction
    }
    mapping (address => uint) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    function sendCoin(address receiver, uint amount) public returns(bool success) {
        if (balances[msg.sender] < amount) return false;

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;    
        
    }

    function getBalance(address addr) public view returns(uint) {
        return balances[addr];
    }
    
    function sendOne(address payable receiverAddr) private {
        receiverAddr.transfer(1);
    }
    
    function sendMulti(address payable[] memory addrs)  payable public isOwner {
        for (uint i=0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= 1;
            
            // send the specified amount to the recipient
            sendOne(addrs[i]);
        }
    }
}