/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Salvadanaio {
    
    address payable nipote = payable(0x0835f29F4E39DEE36B63a991F460d056eF67B896);
    
    function deposita () payable public {
        
    }
    
    function preleva () public {
        
        // se il contratto ha più di 0.2 ether, allora manda il balance al nipote
        if(address(this).balance > 0.2 ether)
            nipote.transfer(address(this).balance);
        
    }
    
}