/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.6.6;
   
    contract FlashMint {
      mapping (address =>uint) balances;
  
     function deposit() public payable{
           balances[msg.sender] = balances[msg.sender]+msg.value;       
     }
      
   function withdraw(uint amount) public payable {
        msg.sender.transfer(amount);
   }
    
    function kill() public {
       selfdestruct(msg.sender);
       
    
}
    
function flashMint(
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external {
        

      
}

}