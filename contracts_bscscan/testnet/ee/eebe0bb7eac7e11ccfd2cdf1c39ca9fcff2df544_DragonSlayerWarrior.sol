// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Tradable.sol";
import "./WarriorInterface.sol";

contract DragonSlayerWarrior is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Tradable, WarriorInterface {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    
    mapping(uint256 => DRS.Warrior) internal tokens;
    mapping(uint256 => uint256[]) internal warriorItems;

    /** LIST OF EVENTS **/
    event WarriorCreated(uint256 indexed tokenId, address buyer);
    event WarriorDestroyed(uint256 indexed tokenId);
    
    /** LIST OF MODIFIER **/
    modifier onlySpawner () {
        require(manager.onlySpawer(_msgSender()), "Caller is not the spawner");
        _;
    }

    constructor() ERC721("DragonSlayerWarrior", "DRW") {}

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    /** WARRIOR **/
    function createWarrior (
        address to,
        string memory kind,
        string memory name,
        uint hp,
        uint attack,
        uint defense,
        uint level
    ) override public onlySpawner returns (DRS.Warrior memory) {
        return _createWarrior(
            to,
            DRS.Warrior({
                kind: kind,
                name: name,
                hp: hp,
                attack: attack,
                defense: defense,
                level: level
            })
        );
    }

    function _createWarrior (address _receiver, DRS.Warrior memory _warrior) internal returns (DRS.Warrior memory) {
        safeMint(_receiver);
        uint256 newWarriorId = _tokenIdCounter.current();

        tokens[newWarriorId] = _warrior;
        emit WarriorCreated(newWarriorId, _receiver);

        return tokens[newWarriorId];
    }
    
    function getWarrior (uint256 _tokenId) override external view returns (DRS.Warrior memory) {
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