/**
 *Submitted for verification at polygonscan.com on 2021-12-12
*/

pragma solidity ^0.7.6;

contract Payable {

    address payable owner;
    uint public price;
    string public allUserID;


    constructor(uint verificationCost) payable 
    {
        owner = payable(msg.sender);
      
        price = verificationCost;
    }


  function strConcat(string memory  stA, string memory stB) private view returns (string memory)
  {
        bytes memory _ba = bytes(stA);
        bytes memory _bb = bytes(stB);
        
        uint alldata=_ba.length +  _bb.length ;
        
        string memory ret = new string(alldata) ;
        
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  

function VerifyProfile(string memory UserID) public payable
{

  require (msg.value >= price,"insufficient funds");
  require (bytes(UserID).length == 36,"invalid id");
  
  
   allUserID=strConcat(allUserID,strConcat(strConcat("[""\"",UserID),"\"""]\n\r"));

}



function withdraw() public 
{
        
    if(msg.sender == owner)
    {
        uint amount = address(this).balance;

        (bool success,) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
            
    }
    else
    {
        require(false, "Not owner");
    }
}

 
    
}