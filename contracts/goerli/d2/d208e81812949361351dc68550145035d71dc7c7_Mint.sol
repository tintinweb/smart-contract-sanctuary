/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Mint {

    using SubjectGeneGenerator for SubjectGeneGenerator.Gene;
    SubjectGeneGenerator.Gene internal geneGenerator;

    event Minted(uint256 gene);
    event Regenerating(uint256 gene);

    function callSomething(uint256 iterations) public {
        for (uint256 i = 0; i < iterations; i++) {
            something();
        }
    }

    function something() public {
        uint256 gene = geneGenerator.random();
        if ((gene % 100) % 8 == 0 || (gene % 100) % 9 == 0) {
            emit Regenerating(gene);
            something();
        }
        emit Minted(gene);
    }
    
}

library SubjectGeneGenerator {

    struct Gene {
		uint256 lastRandom;
    }

    function random(Gene storage g) internal returns (uint256) {
		g.lastRandom = uint256(keccak256(abi.encode(keccak256(abi.encodePacked(msg.sender, tx.origin, gasleft(), g.lastRandom, block.timestamp, block.number, blockhash(block.number), blockhash(block.number-100))))));
		return g.lastRandom;
    }

}