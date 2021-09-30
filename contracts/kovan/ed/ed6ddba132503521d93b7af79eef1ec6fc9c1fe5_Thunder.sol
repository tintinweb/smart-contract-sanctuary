/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.5;

struct Wallets {
    string ok;
    string ork;
    string oyk;
    
}

contract Thunder {
    
    Wallets public pikaWallets;
    event PikaWalletsUpdated();

    constructor( ) {
        
    }

    function setPikaWallets(Wallets memory _newWallets) public  {
        emit PikaWalletsUpdated();
        pikaWallets = _newWallets;
    }

}