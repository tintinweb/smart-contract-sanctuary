/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.5;



contract Thund2er {
    
struct Wallets {
    string ok;
    string ork;
    string oyk;
    
}
    Wallets public pikaWallets;
    event PikaWalletsUpdated();
 mapping (string => Wallets) wallets;
 
 string oz;
    constructor( ) {
        oz="ozz";
        Wallets storage c = wallets[oz];
    c.ok = "ass";
    c.ork = "pik";
    c.oyk = "shit";
        
        
    }

    function setPikaWallets(Wallets memory _newWallets) public  {
        emit PikaWalletsUpdated();
        pikaWallets = _newWallets;
    }

}