// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";

contract Racers is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CTO = keccak256("CTO");
    bytes32 public constant CFO = keccak256("CFO");
    bytes32 public constant CONTRACTS = keccak256("CONTRACTS");

    address internal constant _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    mapping(uint256 => address) public operatorOf; 
    mapping(uint256 => address) public Property1; 
    mapping(uint256 => address) public Property2; 
    mapping(uint256 => address) public Property3; 
    mapping(uint256 => uint256) public PropertyN; 


    constructor() ERC721("racers", "RACE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CEO, address(0x47c06B50C2a6D28Ce3B130384b19a8929f414030));
        _setupRole(CFO, _safe);
        _setupRole(CTO, msg.sender);
    }

    modifier validate() {
        require(
            hasRole(CEO, msg.sender) ||
                hasRole(CFO, msg.sender) ||
                hasRole(CONTRACTS, msg.sender) ||
                hasRole(CTO, msg.sender),
            "AccessControl: Address does not have valid Rights"
        );
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "kartracingleague.com/items/";
    }

    function pause() public validate {
        _pause();
    }

    function unpause() public validate {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public validate {
        _safeMint(to, tokenId);
    }

    function safeBurn(uint256 tokenId) public validate {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }

    function setOperator(uint256 tokenId, address value) public {
        require(exists(tokenId), 'TokenID does not exists');
        require(msg.sender == ownerOf(tokenId), 'Only Token Owner can change this value');
        operatorOf[tokenId] = value;
    }
    function setProperty1(uint256 tokenId, address value) public {
        require(exists(tokenId), 'TokenID does not exists');
        require(msg.sender == ownerOf(tokenId), 'Only Token Owner can change this value');
        Property1[tokenId] = value;
    }
    function setProperty2(uint256 tokenId, address value) public {
        require(exists(tokenId), 'TokenID does not exists');
        require(msg.sender == ownerOf(tokenId), 'Only Token Owner can change this value');
        Property2[tokenId] = value;
    }
    function setProperty3(uint256 tokenId, address value) public {
        require(exists(tokenId), 'TokenID does not exists');
        require(msg.sender == ownerOf(tokenId), 'Only Token Owner can change this value');
        Property3[tokenId] = value;
    }

    function setPropertyN(uint256 tokenId, uint256 value) public {
        require(exists(tokenId), 'TokenID does not exists');
        require(msg.sender == ownerOf(tokenId), 'Only Token Owner can change this value');
        PropertyN[tokenId] = value;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}