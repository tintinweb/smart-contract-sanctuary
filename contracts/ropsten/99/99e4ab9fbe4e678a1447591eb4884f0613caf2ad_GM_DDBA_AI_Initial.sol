/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract GM_DDBA_AI_Initial {
    address private owner;
    string intentContent;

    receive() external payable {
    }

    fallback() external {
    }

    function getContent() public returns (string memory) {
        intentContent = 
        "Smart Contract between GM Holding, DDBA and Arista Ingenieros.\n" 
        "In this certificate it is expressed that the companies join together to study the possible application of "
        "blockchain technology and Tokenization to the engineering processes developed by Arista Ingenieros.\n" 
        "The companies meet on Friday, December 17, 2021, with the intention of formulating the Tokenization "
        "process of the Caldas Transversal Bio-Route project, a mega project valued at $500 Million dollars and that "
        "will help to evolve the entire department of Caldas, its municipalities and main cities.\n" 
        "Meeting led by: Carlos Holmes Flores Ceo of DDBA; Bruno Loaiza Sille Ceo of GM Holding.\n" 
        "And Mr. Jorge Arbelaez, president of Arista Ingenieros and representative of the Caldas Transversal Bio-Route Project.\n\n" 
        
        "For GM Holding";
        return intentContent;
    }
}