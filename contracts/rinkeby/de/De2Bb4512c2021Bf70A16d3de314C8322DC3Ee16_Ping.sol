/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Ping {
    
    address payable depositante;
    uint256 orario_deposito;
    
    fallback () external payable {
        depositante = payable(msg.sender);
        orario_deposito = block.timestamp;
    }
    
    function preleva () public {
        require(block.timestamp > orario_deposito + 1 minutes);
        depositante.transfer(address(this).balance);
    }
    
}