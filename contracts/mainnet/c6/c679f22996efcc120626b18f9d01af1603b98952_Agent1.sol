// SPDX-License-Identifier: MIT
// Agent1 v1.1
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./JoeRichardsNFT.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Agent1 is ERC721, ERC721URIStorage, JoeRichardsNFT {        
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    constructor() ERC721("Agent1", "A10001") {}

    function _baseURI() internal view override returns (string memory) {
        return baseNFTURI;
    }

    /// @dev The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // @dev Save on gas fees for our dear minters
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mintAgent1(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Agent1");
        require(numberOfTokens <= maxAgent1Purchase, "Can only mint 20 tokens at a time");
        require((totalSupply() + numberOfTokens) <= MAX_TOKENS_COUNT, "Purchase would exceed max supply of Agent1s");
        require((tokenPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            // @dev normal mint
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS_COUNT) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
            
            // @dev agent1 special mint
            if (twinMinting) {
                // @dev mint another token.. if there's still slots in the world
                // 2nd token is a morphing agent1.. and then, there's going to be an odd anomoly..
                mintIndex++;
                if (mintIndex < MAX_TOKENS_COUNT) {
                    _safeMint(msg.sender, mintIndex);
                    _tokenIdCounter.increment();
                }
            }
        }
        
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }         

    }
    
    
    /// @dev reserved token minting. 1 mint = 1 token.
    function mintReservedAgent1(uint numberOfTokens, address _to) external onlyOwner {
        require(saleIsActive, "Sale must be active to mint Agent1");
        require(numberOfTokens <= maxAgent1Purchase, "Can only mint 20 tokens at a time");
        require((totalSupply() + numberOfTokens) <= MAX_TOKENS_COUNT, "Purchase would exceed max supply of Agent1s");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS_COUNT) {
                _safeMint(_to, mintIndex);
                _tokenIdCounter.increment();
            }
        }
        
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }         

    }    
    
    function zeroMintAgent1() public {
        require(zeroAgent1Count[msg.sender] < 1, "Each wallet can only zero mint once");
        require(firstMintZero, "Zero mint must be active to zero mint Agent1");
        require(saleIsActive, "Sale must be active to mint Agent1");
        require((totalSupply() + 1) <= MAX_TOKENS_COUNT, "Mint would exceed max supply of Agent1s");

        uint mintIndex = totalSupply();
        if (totalSupply() < MAX_TOKENS_COUNT) {
            _safeMint(msg.sender, mintIndex);
            _tokenIdCounter.increment();
        }

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }          
        
        zeroAgent1Count[msg.sender]++;
        
    }    
    
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(tokenId), "Agent1: URI set of nonexistent token");
        _BJRtokenURIs[tokenId] = _tokenURI;
    }
    
    function freezeTokenURI(uint256 tokenId) external onlyOwner {
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function freezeAllTokenURI() external onlyOwner {
        for(uint i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        
        string memory _tokenURI = _BJRtokenURIs[tokenId];

        // @dev If a polymorphed Agent1 is found, reveal it
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_tokenURI));
        }

        return super.tokenURI(tokenId);
    }
    
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (proxyRegistrySetting > 0) {
            address proxyRegistryAddress;
            if (proxyRegistrySetting == 1) {
                proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317;
            }
            else if (proxyRegistrySetting == 2) {
                proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
            }
            else {
                proxyRegistryAddress = customProxyRegistry;
            }
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }        
    
}