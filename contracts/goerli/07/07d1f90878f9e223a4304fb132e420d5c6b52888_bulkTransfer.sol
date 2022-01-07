/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*        _____                    _____                    _____          
         /\    \                  /\    \                  /\    \         
        /::\    \                /::\    \                /::\____\        
       /::::\    \              /::::\    \              /:::/    /        
      /::::::\    \            /::::::\    \            /:::/   _/___      
     /:::/\:::\    \          /:::/\:::\    \          /:::/   /\    \     
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/   /::\____\    
   /::::\   \:::\    \      /::::\   \:::\    \      /:::/   /:::/    /    
  /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/   /:::/   _/___  
 /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \ 
/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\
\::/    \:::\   \::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /
 \/____/ \:::\   \/____/  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    / 
          \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /  
           \:::\____\       \:::\   \:::\____\       \::::/___/:::/    /   
            \::/    /        \:::\   \::/    /        \:::\__/:::/    /    
             \/____/          \:::\   \/____/          \::::::::/    /     
                               \:::\    \               \::::::/    /      
                                \:::\____\               \::::/    /       
                                 \::/    /                \::/____/        
                                  \/____/                  ~~              */
                                                                           
contract bulkTransfer {
    string public name = "bulkTransfer";
    string public createdBy = "0xBosz";
    address public supportMe = 0x0570F55D608D4657E754d0A8b078E2e0C0D49A4e;

    function sendEther(address payable [] memory receiver, uint256 _amount) public payable {
        uint256 balance = address(msg.sender).balance;
        require(msg.value == _amount * receiver.length , "ETH value or amount is incorrect");
        require(balance > _amount * receiver.length , "Insufficent balance");

        for (uint256 i = 0; i < receiver.length; i++) {
            require(receiver[i] != address(0), "Cannot transfer to null address");
            uint256 amount = msg.value / receiver.length;
            receiver[i].transfer(amount);
        }

    }
}