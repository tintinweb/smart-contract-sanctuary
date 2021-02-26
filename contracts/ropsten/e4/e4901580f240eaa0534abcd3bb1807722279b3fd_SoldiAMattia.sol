/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract SoldiAMattia {
    
    address payable sprovveduto;
    uint stato = 0;
    uint256 tempo;
    
    event Grazie1000(address);
    
    function finanziaLEsempio () payable public {
        emit Grazie1000(msg.sender);
    }
    
    function metticiISoldi () payable public {
        require(msg.value > 1 ether);
        require(stato == 0);
        sprovveduto = payable(msg.sender);
        stato = 1;
        tempo = block.timestamp;
    }
    
    function riprendiIlMalloppo () public {
        require(stato == 1);
        require(block.timestamp > tempo + 5 minutes);
        sprovveduto.transfer(address(this).balance);
        stato = 0;
    }
    
}