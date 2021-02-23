/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract RootBounty {
    
    // x**3 - 678975380*x**2 + 16283637685579563*x - 99427765102975464279264
    
    constructor () payable {}
    
    function submit (int x) public {
        
        // verifica soluzione
        require(((x**3) - 678975380*(x**2) + 16283637685579563*x - 99427765102975464279264) == 0, "Soluzione sbagliata!");
        // se la soluzione è corretta => eroga premio
        payable(msg.sender).transfer(address(this).balance);
        
    }
    
}