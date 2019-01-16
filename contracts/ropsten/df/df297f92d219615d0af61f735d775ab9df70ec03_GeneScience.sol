pragma solidity ^0.4.11;

contract GeneScience {
    function isGeneScience() public pure returns(bool) {
        return true;
    }
 
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public pure returns (uint256) {
        uint256 _targetGene = genes1 + genes2 + targetBlock;
        return _targetGene;
    }
}