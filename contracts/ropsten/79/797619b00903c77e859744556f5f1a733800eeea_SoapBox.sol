pragma solidity ^0.4.0;
contract SoapBox {
// Our &#39;dict&#39; of addresses that are approved to share opinions
    mapping (address => bool) approvedSoapboxer;
    string opinion;
     
    // Our event to announce an opinion on the blockchain
    event OpinionBroadcast(address _soapboxer, string _opinion);
// This is a constructor function, so its name has to match the contract
    function SoapBox() public {
    }
    
    // Because this function is &#39;payable&#39; it will be called when ether is sent to the contract address.
    function() public payable{
        // msg is a special variable that contains information about the transaction
        if (msg.value > 20000000000000000) {  
            //if the value sent greater than 0.02 ether (in Wei)
            // then add the sender&#39;s address to approvedSoapboxer 
            approvedSoapboxer[msg.sender] =  true;
        }
    }
    
    
    // Our read-only function that checks whether the specified address is approved to post opinions.
    function isApproved(address _soapboxer) public view returns (bool approved) {
        return approvedSoapboxer[_soapboxer];
    } 
    
    // Read-only function that returns the current opinion
    function getCurrentOpinion() public view returns(string) {
        return opinion;
    }
//Our function that modifies the state on the blockchain
    function broadcastOpinion(string _opinion) public returns (bool success) {
        // Looking up the address of the sender will return false if the sender isn&#39;t approved
        if (approvedSoapboxer[msg.sender]) {
            
            opinion = _opinion;
            emit OpinionBroadcast(msg.sender, opinion);
            return true;
            
        } else {
            return false;
        }
        
    }
}