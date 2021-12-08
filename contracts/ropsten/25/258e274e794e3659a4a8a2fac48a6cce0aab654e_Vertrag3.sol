/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.5.7; 

contract Vertrag3 {

    string public vertragstext = "Allgemeine Geschaeftsbedingungen zum jeweiligen Vertrag etc."; 
    uint public zustand = 0; 
    
    function Vertragstext() public view returns(string memory){
        return vertragstext;
    }

    function Annehmen() public view returns(string memory){
        if(zustand == 1)
        {
            return "Vertrag angenommen"; 
        }
        else
        {
            return "Falscher Vertragspartner"; 
        }
    }

    function Ablehnen() public view returns(string memory){
        if(zustand == 0)
    
        
        {
            return "Vertrag abgelehnt"; 
        }
        else
        {
            return "Falscher Vertragspartner"; 
        }
    }

    function setzeZustand(uint wert) public {
        zustand = wert; 
    }


}