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
        // require(transactionConfirmations[_id][msg.sender], "You have been confirm the transaction");
        transaction[_id-1].confirmationCount += 1;
        transaction[_id-1].confirmedBy.push(msg.sender);
        executeTransaction(_id);
    }
    
    function executeTransaction(uint256 _id) public {
        require(isOwner(msg.sender), "You are not owner of the wallet");
        uint256 id = _id-1;
        if(transaction[id].confirmationCount >= required){
            if(checkEqualString(transaction[id].tokenType, "ETH")){
              payable(transaction[id].to).transfer(transaction[id].value);
            } else if (checkEqualString(transaction[id].tokenType, "ERC20")){
              ERC20 token = ERC20(transaction[id].token);
              token.approve(address(this), transaction[id].value);
              token.transferFrom(address(this), transaction[id].to, transaction[id].value);
            }   
        }
        
    }
    
    function getTransaction() public view returns (Transaction[] memory){
        return transaction;
    }
    
    function checkEqualString(string memory a, string memory b) private pure returns (bool){
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function isOwner(address _owner) public view returns(bool){
        bool result;
        for(uint i = 0; i < owner.length; i++){
            if(owner[i] == _owner){
                result = true;
            }
        }
        return result;
    }
    
   
    
    
}