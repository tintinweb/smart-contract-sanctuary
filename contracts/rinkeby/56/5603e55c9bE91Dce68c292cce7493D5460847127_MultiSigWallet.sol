// SPDX-License-Identifier: GPL-3.0

//decrlare verison of solidity
pragma solidity >=0.7.0 <0.9.0;

import './ERC20.sol';

contract MultiSigWallet {
    address[] owner;
    uint256 required;
    
    struct Transaction {
        uint256 id;
        address to;
        address token;
        uint256 value;
        uint256 confirmationCount;
        address[] confirmedBy;
        string tokenType;
        bool executed;
    }
    
    struct Owner {
        uint256 id;
        address owner;
        uint256 confirmationCount;
        string _type;
        address[] confirmedBy;
        bool executed;
    }
    
    Owner[] tempOwner;
    
    Transaction[] transaction;
    
    receive() external payable {
        
    }
    
    constructor(address[] memory _owner, uint256 _required){
        owner = _owner;
        required = _required;
    }
    
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function addOwner(address _newOwner) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        require(isOwner(_newOwner) == false, "the address is already the owner");
        tempOwner.push(Owner(tempOwner.length + 1, _newOwner, 0, "add",new address[](0), false));
    }
    
    function removeOwner(address _newOwner) public {
        require(owner.length > required, "can't remove owner, owner lenght must be more then required confirmation length");
        require(isOwner(msg.sender), "You are not owner of the wallet");
        require(isOwner(_newOwner), "the address is not already the owner");
        tempOwner.push(Owner(tempOwner.length + 1, _newOwner, 0, "remove",new address[](0), false));
    }
    
    function confirmNewOwner(uint256 _id) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        require(isAlreadyConfirmedOwner(_id, msg.sender) == false, "You have been confirm the transaction");
        tempOwner[_id-1].confirmationCount += 1;
        tempOwner[_id-1].confirmedBy.push(msg.sender);
        if(tempOwner[_id-1].confirmationCount >= required && tempOwner[_id-1].executed == false){
            if(checkEqualString(tempOwner[_id-1]._type, "add")){
               owner.push(tempOwner[_id-1].owner);
               tempOwner[_id-1].executed = true;   
            } else if(checkEqualString(tempOwner[_id-1]._type, "remove")){
               owner.push(tempOwner[_id-1].owner);
               tempOwner[_id-1].executed = true;  
            }
        }
    }
    
    function getOwner() public view returns (address[] memory){
        return owner;
    }
    
    function getBalanceToken(address _address) public view returns (uint256){
        return ERC20(_address).balanceOf(address(this));
    }
    
    function submitTransaction(address _to, uint256 _value, string memory _type, address _token) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        if(checkEqualString(_type,"ETH")){
            require(_value <= getBalance(), "insufficient balance of token");    
        } else if(checkEqualString(_type,"ERC20")) {
            require(_value <= getBalanceToken(_token), "insufficient balance of token");
        }
        transaction.push(Transaction(transaction.length + 1, _to, _token, _value, 0, new address[](0), _type, false));
        confirmTransaction(transaction.length);
    }
    
    function confirmTransaction(uint256 _id) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        require(isAlreadyConfirmed(_id, msg.sender) == false, "You have been confirm the transaction");
        transaction[_id-1].confirmationCount += 1;
        transaction[_id-1].confirmedBy.push(msg.sender);
        executeTransaction(_id);
    }
    
    function executeTransaction(uint256 _id) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        uint256 id = _id-1;
        if(transaction[id].confirmationCount >= required && transaction[id].executed == false){
            if(checkEqualString(transaction[id].tokenType, "ETH")){
              payable(transaction[id].to).transfer(transaction[id].value);
            } else if (checkEqualString(transaction[id].tokenType, "ERC20")){
              ERC20 token = ERC20(transaction[id].token);
              token.approve(address(this), transaction[id].value);
              token.transferFrom(address(this), transaction[id].to, transaction[id].value);
            }   
        }
        transaction[id].executed = true;
        
    }
    
    function getTransaction() public view returns (Transaction[] memory){
        return transaction;
    }
    
    function checkEqualString(string memory a, string memory b) private pure returns (bool){
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function isOwner(address _owner) private view returns (bool){
        bool result;
        for(uint i = 0; i < owner.length; i++){
            if(owner[i] == _owner){
                result = true;
            }
        }
        return result;
    }
    
    function isAlreadyConfirmed(uint256 _id, address sender) private view returns (bool){
        bool result;
        for(uint256 i = 0; i < transaction[_id-1].confirmedBy.length; i++){
            if(transaction[_id-1].confirmedBy[i] == sender){
                result = true;
            }
        }
        return result;
    }
    
    function isAlreadyConfirmedOwner(uint256 _id, address sender) private view returns (bool){
        bool result;
        for(uint256 i = 0; i < tempOwner[_id-1].confirmedBy.length; i++){
            if(tempOwner[_id-1].confirmedBy[i] == sender){
                result = true;
            }
        }
        return result;
    }
    
    
}