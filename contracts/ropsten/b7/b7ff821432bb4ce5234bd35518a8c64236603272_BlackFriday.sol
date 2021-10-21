/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract BlackFriday {
    
    uint256 depositTime;
    address payable user;
    bool active = false;
    
    function deposit () payable public {
        // posso depositare se il contratto non è ancora attivo
        require(active == false, "Deposito gia' effettuato");
        active = true;
        depositTime = block.timestamp;
        user = payable(msg.sender);
    }
    
    function withdraw () public {
        // facciamo un po' di controlli
        // 1 - chi preleva deve aver depositato
        require(msg.sender == user, "Non sei abilitato al prelievo");
        // 2 - deve essere passato abbastanza tempo (2 settimane)
        require(block.timestamp >= depositTime + 2 minutes, "Non e' passato abbastanza tempo");
        
        // trasferisci i fondi (consenti il prelievo)
        user.transfer(address(this).balance);
        active = false;
    }
    
}