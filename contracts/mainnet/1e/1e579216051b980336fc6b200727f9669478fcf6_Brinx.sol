// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Brinx is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter internal tokenCounter;
    
    event tokenMinted(
        address indexed _owner,
        uint256 indexed _tokenID
    );
    
    modifier validateToken(uint256 _tokenID){
        require(_tokenID != 0 && _tokenID <= tokenCounter.current(), "Invalid tokenID");
        _;
    }
    
    
    mapping(uint => address) private OwnerOfToken;
    
    constructor(
        string memory metadataBaseURI
        ) ERC1155(metadataBaseURI) {}
    
    function setMetadataBaseURI(string memory _newMetadataBaseURI) 
        public 
        onlyOwner
    {
        _setURI(_newMetadataBaseURI);
    }
    
    function uri(uint256 _tokenID) 
        public 
        view 
        override 
        validateToken(_tokenID)
        returns (string memory) 
    {
        return string(abi.encodePacked(ERC1155.uri(_tokenID), (_tokenID.toString())));
    }
    
    function getOwner(uint256 _tokenID) 
        public 
        view 
        validateToken(_tokenID)
        returns (address)
    {
        return OwnerOfToken[_tokenID];
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override
    {
        ERC1155.safeTransferFrom(from, to, id, amount, data);
        OwnerOfToken[id]=to;
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override 
    {
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenID = ids[i];
            OwnerOfToken[tokenID] = to;
        }
    }
    
    function mint()
        external
        nonReentrant()
    {
        tokenCounter.increment();
        _mint(msg.sender, tokenCounter.current(), 1, "");
        OwnerOfToken[tokenCounter.current()]=msg.sender;
        emit tokenMinted(msg.sender,tokenCounter.current());
    }
}