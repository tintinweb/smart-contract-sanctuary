// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Tradable.sol";

contract DragonSlayerWarrior is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Tradable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    struct Warrior {
        string kind;
        uint hp;
        uint attack;
        uint defense;
        uint level;
        uint rate;
        uint timestamp;
        bytes32 tokenHash;
    }
    
    mapping(uint256 => Warrior) internal tokens;
    mapping(uint256 => uint256[]) internal warriorItems;

    /** LIST OF EVENTS **/
    event WarriorCreated(uint256 indexed tokenId, address buyer);
    event WarriorDestroyed(uint256 indexed tokenId);
    
    /** LIST OF MODIFIER **/
    modifier onlySpawner () {
        require(manager.onlySpawer(_msgSender()), "Caller is not the spawner");
        _;
    }

    modifier onlyValidHash (bytes32 _hash, Warrior memory _warrior) {
        require(manager.verifyHash(_hash, abi.encodePacked(_warrior.level, _warrior.hp, _warrior.attack, _warrior.defense)), "Invalid token hash");
        _;
    }

    constructor() ERC721("DragonSlayerWarrior", "DRW") {}

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    /** WARRIOR **/
    function createWarrior (
        Warrior memory _warrior,
        bytes32 _hash
    ) public onlyValidHash(_hash, _warrior) returns (Warrior memory) {
        return _createWarrior(_msgSender(), _warrior);
    }

    function _createWarrior (address _receiver, Warrior memory _warrior) internal returns (Warrior memory) {
        safeMint(_receiver);
        uint256 newWarriorId = _tokenIdCounter.current();

        tokens[newWarriorId] = _warrior;
        emit WarriorCreated(newWarriorId, _receiver);

        return tokens[newWarriorId];
    }
    
    function getWarrior (uint256 _tokenId) external view returns (Warrior memory) {
        return tokens[_tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}