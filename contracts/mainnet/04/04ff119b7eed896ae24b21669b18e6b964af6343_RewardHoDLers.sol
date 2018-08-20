pragma solidity ^0.4.21;
/***
* ________  _______   ___       __   ________  ________  ________           
*|\   __  \|\  ___ \ |\  \     |\  \|\   __  \|\   __  \|\   ___ \          
*\ \  \|\  \ \   __/|\ \  \    \ \  \ \  \|\  \ \  \|\  \ \  \_|\ \         
* \ \   _  _\ \  \_|/_\ \  \  __\ \  \ \   __  \ \   _  _\ \  \ \\ \        
*  \ \  \\  \\ \  \_|\ \ \  \|\__\_\  \ \  \ \  \ \  \\  \\ \  \_\\ \       
*   \ \__\\ _\\ \_______\ \____________\ \__\ \__\ \__\\ _\\ \_______\      
*    \|__|\|__|\|_______|\|____________|\|__|\|__|\|__|\|__|\|_______|      
*                                                                           
*                                                                           
*                                                                           
* ___  ___  ________  ________  ___       _______   ________  ________      
*|\  \|\  \|\   __  \|\   ___ \|\  \     |\  ___ \ |\   __  \|\   ____\     
*\ \  \\\  \ \  \|\  \ \  \_|\ \ \  \    \ \   __/|\ \  \|\  \ \  \___|_    
* \ \   __  \ \  \\\  \ \  \ \\ \ \  \    \ \  \_|/_\ \   _  _\ \_____  \   
*  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \____\ \  \_|\ \ \  \\  \\|____|\  \  
*   \ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \__\\ _\ ____\_\  \ 
*    \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|__|\|__|\_________\
*                                                               \|_________| 
 *              
 *  "Rewards Token HoDLers on https://eth.h4d.io"                                                                                         
 *  What?
 *  -> Holds onto H4D tokens, and can ONLY reinvest in the HoDL4D contract and accumulate more tokens.
 *  -> This contract CANNOT sell, give, or transfer any tokens it owns.
 */
 
contract Hourglass {
    function buyPrice() public {}
    function sellPrice() public {}
    function reinvest() public {}
    function myTokens() public view returns(uint256) {}
    function myDividends(bool) public view returns(uint256) {}
}

contract RewardHoDLers {
    Hourglass H4D;
    address public H4DAddress = 0xeB0b5FA53843aAa2e636ccB599bA4a8CE8029aA1;

    function RewardHoDLers() public {
        H4D = Hourglass(H4DAddress);
    }

    function makeItRain() public {
        H4D.reinvest();
    }

    function myTokens() public view returns(uint256) {
        return H4D.myTokens();
    }
    
    function myDividends() public view returns(uint256) {
        return H4D.myDividends(true);
    }
    
    
}