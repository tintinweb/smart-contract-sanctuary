pragma solidity ^0.4.24;

contract CharacterTraits 
{
    function getCharacterTraits(uint256 genes) public pure returns (
        uint8 characterType,
        uint8 hitPoints,
        uint8 attack,
        uint8 defence
    )
    {
        characterType = _determineCharacterType(genes);
        hitPoints = _determineHitPoints(genes);
        attack = _determineAttack(genes);
        defence = _determineDefence(genes);
    }

    function _generateRandomGenes() internal pure returns(uint256) {
        return 109806710;
    }

    function _determineCharacterType(uint256 genes) private pure returns(uint8) {
        return uint8(genes / 100000000);
    }

    function _determineHitPoints(uint256 genes) private pure returns(uint8) {
        return uint8((genes % 100000000) / 100000);
    }

    function _determineAttack(uint256 genes) private pure returns(uint8) {
        return uint8((genes % 100000) / 100);
    }

    function _determineDefence(uint256 genes) private pure returns(uint8) {
        return uint8(genes % 100);
    }
}
contract CharacterBase is CharacterTraits
{
    struct Character
    {
        uint256 Genes;
    }

    Character[] public characters;

    mapping (uint => address) public characterToOwner;

    function createRandomCharacter() public returns(uint) {
        uint256 genes = _generateRandomGenes();

        uint id = characters.push(Character(genes)) - 1;
        characterToOwner[id] = msg.sender;

        return id;
    }

    function getCharacter(uint id) public view returns(
        uint8 characterType,
        uint8 hitPoints,
        uint8 attack,
        uint8 defence)
    {
        return getCharacterTraits(characters[id].Genes);
    }
}