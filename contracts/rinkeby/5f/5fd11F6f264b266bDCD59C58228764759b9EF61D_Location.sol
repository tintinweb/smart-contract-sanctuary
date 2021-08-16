/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Location {

    string  public Callback;
    

    function register( string memory callback ) public {
        
    Callback = callback;    
        
    }

    function add( string memory URL, string memory Title, address payable Location, address payable Type, address payable Name ) public {

        Location.transfer(0);
        Type.transfer(0);
        Name.transfer(0);
    }
    
    fallback() payable external {}
}