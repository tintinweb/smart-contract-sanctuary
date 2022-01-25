/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    using SubjectGeneGenerator for SubjectGeneGenerator.Gene;
    SubjectGeneGenerator.Gene internal geneGenerator;

    mapping(uint256 => uint256) internal _genes;
    uint256[] public _bossCharactersGenes;
    uint256 private immutable uniquesCount = 510;
    uint256 private immutable maxSupply = 10000;
    mapping(uint256 => uint256) internal _uniqueGenes;
    mapping(uint256 => uint256) internal _bossGenes;
    mapping(uint256 => uint256) internal _dummyGenes;
    mapping(uint256 => uint256) internal _gangstaGenes;

    event UniqueGenerated(uint256 uniqueNumber, uint256 tokenId);
    event UniqueOverwriteCheck(uint256 uniqueNumber, uint256 tokenId);

    constructor() {
        geneGenerator.random();
    }

    function generateUniques() public {
        for (uint256 i = 1; i <= uniquesCount; i++) {
            uint256 selectedToken = (geneGenerator.random() % (maxSupply - 1)) + 1;

            // TODO: test it in remix
            // [Comment for audit]: ensuring that we're not rewriting _uniqueGenes mapping,
            // so we get 510 uniques
            // problem: unknown amount of max gas required
            if (_uniqueGenes[selectedToken] != 0) {
                emit UniqueOverwriteCheck(i, selectedToken);
                i--;
                continue;
            }
            _uniqueGenes[selectedToken] = i;

            // [Comment for audit]: maybe figure out something smarter than what's below
            // or it's okay to leave it like this?
            if (i <= 250) {
                _dummyGenes[selectedToken] = i;
            } else if (i > 250 && i <= 500) {
                _gangstaGenes[selectedToken] = i;
            } else if (i > 500 && i <= 510) {
                _bossGenes[selectedToken] = i;
            }
            
            emit UniqueGenerated(i, selectedToken);
        }
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