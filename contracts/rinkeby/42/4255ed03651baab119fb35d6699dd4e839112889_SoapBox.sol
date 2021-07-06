/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.4.26;

contract SoapBox {
// Our 'dict' of addresses that are approved to share opinions   
//我们批准分享意见的地址的“字典” 
    mapping (address => bool) approvedSoapboxer;
    string opinion;
    string name;
     
    // Our event to announce an opinion on the blockchain  
    //我们的事件发布对区块链的意见 
 
    event OpinionBroadcast(address _soapboxer, string _opinion);
// This is a constructor function, so its name has to match the contract   
//这是一个构造函数，所以它的名字必须与合约相匹配 
 
    //function constructor() public {}
    constructor(string _name) public { name = _name;}
    
    // Because this function is 'payable' it will be called when ether is sent to the contract address.
    //因为这个函数是“支付”，所以当以太网被发送到合约地址时将被调用。 
    function() public payable{
        // msg is a special variable that contains information about the transaction
        // msg是一个特殊变量，包含有关交易的信息 
        if (msg.value > 20000000000000000) {  
            //if the value sent greater than 0.02 ether (in Wei)
            //如果发送的值大于0.02 ether（在Wei中） 
            // then add the sender's address to approvedSoapboxer 
            //然后将发件人的地址添加到approvedSoapboxer 
            approvedSoapboxer[msg.sender] =  true;
        }
    }
    
    
    // Our read-only function that checks whether the specified address is approved to post opinions.
    //我们的只读函数，用于检查指定地址是否被批准发布意见。 
    function isApproved(address _soapboxer) public view returns (bool approved) {
        return approvedSoapboxer[_soapboxer];
    } 
    
    // Read-only function that returns the current opinion
    //返回当前意见的只读函数 
    function getCurrentOpinion() public view returns(string) {
        return opinion;
    }
//Our function that modifies the state on the blockchain
  //我们的函数修改了区块链上的状态 
    function broadcastOpinion(string _opinion) public returns (bool success) {
        // Looking up the address of the sender will return false if the sender isn't approved
        //如果发件人未获批准，查找发件人的地址将返回false 
        if (approvedSoapboxer[msg.sender]) {
            opinion = _opinion;
            emit OpinionBroadcast(msg.sender, opinion);
            return true;
        } else {
            return false;
        }
        
    }
}