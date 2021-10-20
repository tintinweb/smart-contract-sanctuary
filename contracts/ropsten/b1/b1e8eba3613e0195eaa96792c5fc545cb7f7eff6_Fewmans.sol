//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./SimpleURIBuilder.sol";

contract Fewmans is ERC721Enumerable, AccessControl {
    string constant seed = "We Like Fewmans";
    uint256 private nextID = 10000;
    bytes32 public constant CREATOR_ROLE = bytes32(uint256(0xfe34a96));
    IURIBuilder uriBuilder = new SimpleURIBuilder(this);

    mapping(uint256 => uint8[8]) private _personality;

    constructor() ERC721("Fewmans", "FEW") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CREATOR_ROLE, msg.sender);
        _setRoleAdmin(CREATOR_ROLE, CREATOR_ROLE);
        for (uint8 i = 0; i < 16; i++) _safeMint(msg.sender, i);
    }

    function personalityKey(uint256 id) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint16(id), seed));
    }

    uint8[] probs = [3, 10, 40, 70];

    function personality(uint256 id) public view returns (uint8[8] memory res) {
        if (id >= 10000) return _personality[id];
        uint256 pk = uint256(personalityKey(id));
        for (uint256 p = 0; p < 8; p++) {
            uint8 pr = uint8(pk % 100);

            // prettier-ignore
            res[p] = pr < probs[0] ? 1
                   : pr < probs[1] ? 2
                   : pr < probs[2] ? 3
                   : pr < probs[3] ? 4
                   : 5;
            pk /= 100;
        }
        if (id < 16) {
            res[id & 7] = 0;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return uriBuilder.tokenURI(tokenId);
    }

    function mint(uint256 tokenId) external {
        // require(balanceOf(msg.sender) == 0, "Only one fewman per address!");
        require(tokenId < 10000, "ID is too large, max: 9999");
        _safeMint(msg.sender, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function createFor(address holder, uint8[8] calldata person)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 tokenID)
    {
        tokenID = nextID++;
        _safeMint(holder, tokenID);
        _personality[tokenID] = person;
    }

    function updatePersonality(uint256 tokenID, uint8[8] calldata person)
        external
        onlyRole(CREATOR_ROLE)
    {
        _personality[tokenID] = person;
    }

    function setURIBuilder(IURIBuilder builder)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uriBuilder = builder;
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}