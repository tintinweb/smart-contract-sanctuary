/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.5.7; 

contract Vertrag {

    function Vertragstext() public view returns(string memory){
        return "Allgemeine Geschaeftsbedingungen zum jeweiligen Vertrag etc.";
    }

    function Annehmen() public view returns(string memory){
        if(msg.sender == 0x7cdd3ADa4f4fE93C8d282d4E2fb66C799976e12A)
        {
            return "Vertrag angenommen"; 
        }
        else
        {
            return "Falscher Vertragspartner"; 
        }
    }

    function Ablehnen() public view returns(string memory){
        if(msg.sender == 0x7cdd3ADa4f4fE93C8d282d4E2fb66C799976e12A)
    
        
        {
            return "Vertrag abgelehnt"; 
        }
        else
        {
            return "Falscher Vertragspartner"; 
        }
    }


}