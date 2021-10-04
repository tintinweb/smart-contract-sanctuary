/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

contract Keccakz {
    // Greetings Explorer! CCTF{Ins1pr4t10n_Ind3p3nd3nc3}

    
    function checkkeccak256()public pure returns(bytes32){
        bytes memory tt = 'test'; 
        return keccak256(tt);
    }
    
    function checkkeccak256(string memory fillit)public pure returns(bytes32){
        return keccak256(abi.encode(fillit));
    }
}