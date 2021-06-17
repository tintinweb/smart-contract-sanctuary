/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.4.19;

contract TransferEtherTo {
    function() public payable {
        
    }
    
    function getBalance() public constant returns(uint _balance) {
        return address(this).balance;
    }
}

contract TransferEtherFrom {
    
    TransferEtherTo private _instance;
    
    function transferEtherFrom(address _instance) public payable {
        _instance = new TransferEtherTo();
    }
    
    function getBalance() public constant returns(uint) {
        return address(this).balance;
    }
    
    //to get the balance of EthertransferTo from EthertransferFrom
    
    function getInstanceBalance() public constant returns(uint) {
        return address(_instance).balance;
    }
    
    function() public payable {
        address(_instance).send(msg.value);
    }
}