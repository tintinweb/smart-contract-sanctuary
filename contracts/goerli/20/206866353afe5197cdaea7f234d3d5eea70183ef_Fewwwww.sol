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
                                                                           
contract Fewwwww {
    string public name = "Fewwwwww";
    string public createdBy = "0xBosz";
    address public supportMe = 0x0570F55D608D4657E754d0A8b078E2e0C0D49A4e;

    function sendEther(address [] memory receiver, uint256 amount) payable external {
        uint256 balance = address(msg.sender).balance;
        require(msg.value == receiver.length * amount , "ETH value or amount is incorrect");
        require(balance > amount * receiver.length , "Insufficent balance");

        for (uint256 i = 0; i < receiver.length; i++) {
            require(receiver[i] != address(0), "Cannot transfer to null address");
            _transferEth(receiver[i], amount);
        }

    }

    function _transferEth(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to transfer Ether");
    }
}