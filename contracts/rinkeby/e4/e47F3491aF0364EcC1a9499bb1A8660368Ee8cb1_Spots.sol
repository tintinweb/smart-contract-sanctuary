// SPDX-License-Identifier: MIT

// File: Spots.sol

// Deployed Address: 0x0198826f27Dcba02fDE8978475A96A82214D26BA

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";
import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";

contract Spots is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    using ERC165Checker for address;

    string public prefix = "ipfs://QmdQWrQSLyCjqnWLovBSFUGKFHcCqwwfM3NnqnUXap5rpq/"; //for unbonded tokens

    mapping(uint => bool) private _bondedSpots;
    mapping(uint => address) private _bondedNFTContractAddresses;
    mapping(uint => uint) private _bondedNFTTokenIds;
    
    mapping(uint => string) private _ownerLink;
    mapping(uint => string) private _bondedNFTCreatorLink;
    
    event TokenBonded(uint spotIndex, address nftContract, uint nftIndex);
    event TokenUnbonded(uint spotIndex);
    event BondedNFTModelURISet(uint spotIndex, string newModelURI);
    event OwnerLinkSet(uint spotIndex, string newOwnerLink);
    event BondedNFTCreatorLinkSet(uint spotIndex, string newCreatorLink);

    constructor() ERC721("Spots", "SPOTS") {}


    // Inheritance handling    
    function _beforeTokenTransfer(address from, address to, uint256 spotIndex)
    internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, spotIndex);
    }

    function _burn(uint256 spotIndex)
    internal override(ERC721, ERC721URIStorage) {
        super._burn(spotIndex);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // When the token is tranferred, unbond the bonded NFT (if one is bonded)
    function _transfer(address from, address to, uint256 spotIndex)
    internal virtual override {
        super._transfer(from, to, spotIndex);
        unbondNFT(spotIndex);
    }

    function defaultURI(uint spotIndex)
    public view
    returns(string memory) {
        return concat(prefix, uint2str(spotIndex), ".json", "", "");  
    }

    function tokenURI(uint256 spotIndex)
    public view override(ERC721, ERC721URIStorage)
    returns (string memory) {
        if (!isBonded(spotIndex)) {
            return defaultURI(spotIndex);
        }
        return super.tokenURI(spotIndex);
    }


    // Contract-specific
    function bondNFT(address nftContract, uint nftIndex, uint spotIndex)
    public
    requireSpotOwner(spotIndex) {
        require(isNFTOwner(msg.sender, nftContract, nftIndex), "Caller does not own NFT");
        require(nftContract != address(this), "Cannot bond a spot to another spot");
        
        _bondedSpots[spotIndex] = true;
        _bondedNFTContractAddresses[spotIndex] = nftContract; 
        _bondedNFTTokenIds[spotIndex] = nftIndex;
        
        emit TokenBonded(spotIndex, nftContract, nftIndex);
    }

    function _unbondNFT(uint spotIndex)
    private
    requireSpotBonded(spotIndex) {
        setTokenURI(spotIndex, defaultURI(spotIndex));
        
        _bondedSpots[spotIndex] = false;
        _bondedNFTContractAddresses[spotIndex] = address(0x0); 
        _bondedNFTTokenIds[spotIndex] = 0;
        
        emit TokenUnbonded(spotIndex);
    }

    function unbondNFT(uint spotIndex)
    public
    requireSpotOwner(spotIndex) {
        _unbondNFT(spotIndex);
    }

    function setOwnerLink(uint spotIndex, string memory link)
    public
    requireSpotOwner(spotIndex) {
        _ownerLink[spotIndex] = link;

        emit OwnerLinkSet(spotIndex, link);
    }
    
    // Todo: how to find address of contract deployer?
    function setBondedNFTCreatorLink(uint spotIndex, string memory link)
    public {
        require(isBondedTokenOwner(msg.sender, spotIndex), "Caller is not owner of bonded asset");
        _bondedNFTCreatorLink[spotIndex] = link;

        emit BondedNFTCreatorLinkSet(spotIndex, link);
    }

    // Only owner (todo: reimplement onlyOwner in the following functions - removed for ease of testing)
    function mint(uint amount)
    public { //onlyOwner
        uint totalSupply = totalSupply() + 1; 
        uint totalToMint = totalSupply + amount;
        
        for (uint i = totalSupply; i < totalToMint; i++) {
            _safeMint(msg.sender, i);   // Todo: should probably mint to address(this) and let people claim
        }
    }

    function setTokenURI(uint spotIndex, string memory uri)
    public { //onlyOwner
        _setTokenURI(spotIndex, uri);
    }

    function setDefaultPrefixURI(string memory uri)
    public { //onlyOwner
        prefix = uri;
    }

    // When bonded NFT's are transferred, they must be unbonded by force
    function forceUnbondNFT(uint spotIndex)
    public { //onlyOwner
        _unbondNFT(spotIndex);
    }

    function forceUnbondNFTs(uint[] memory spotIndexes)
    public { //onlyOwner
        for (uint i = 0; i < spotIndexes.length; i++) {
            _unbondNFT(spotIndexes[i]);
        }
    }

    // For overriding
    function setBondedNFTModelURI(uint spotIndex, string memory uri)
    public
    requireSpotBonded(spotIndex) { //onlyOwner
        emit BondedNFTModelURISet(spotIndex, uri);
    }


    // Helpers / Read-Only
    function isBonded(uint spotIndex) public view returns(bool) {
        return _bondedSpots[spotIndex];
    }
    
    function bondedNFTContractAddress(uint spotIndex)
    public view
    requireSpotBonded(spotIndex)
    returns(address) {
        return _bondedNFTContractAddresses[spotIndex];
    }
    
    function bondedNFTTokenId(uint spotIndex)
    public view
    requireSpotBonded(spotIndex)
    returns(uint) {
        return _bondedNFTTokenIds[spotIndex];
    }
    
    function numberOfBondedTokens()
    public view
    returns(uint) {
        uint totalSupply = totalSupply();
        
        uint num = 0;    
        for (uint i = 1; i <= totalSupply; i++)
        {
            if (isBonded(i)) {
                num += 1;
            }
        }

        return num;
    }
    
    function bondedTokenIndices()
    public view
    returns(uint[] memory) {
        // Solidity doesn't support dynamic arrays unless you use storage, so we
        // have to iterate twice - once to determine size, and a second time to determine index positions.
        // This might be a bad solution, perhaps it's better to redo this using Web3 (or another library)

        uint totalSupply = totalSupply();

        uint[] memory indices = new uint[](numberOfBondedTokens());
        uint counter = 0;

        for (uint i = 1; i <= totalSupply; i++)
        {
            if (isBonded(i)) {
                indices[counter] = i;
                counter += 1;
            }
        }

        return indices;
    }

    function bondedTokenAddresses()
    public view
    returns(address[] memory)
    {
        uint[] memory indices = bondedTokenIndices();
        address[] memory addresses = new address[](indices.length);
        uint counter = 0;

        for (uint i = 0; i < indices.length; i++) {
            uint spotIndex = indices[i];
            addresses[counter] = ownerOf(spotIndex);
            counter += 1;
        }

        return addresses;
    }

    function anyOwnersChanged()
    public view
    returns(bool) {
        uint[] memory indices = bondedTokenIndices();

        for (uint i = 0; i < indices.length; i++) {
            uint spotIndex = indices[i];

            address nftContract = _bondedNFTContractAddresses[spotIndex];
            uint nftIndex = _bondedNFTTokenIds[spotIndex];

            if (!doesBondedTokenOwnerMatch(spotIndex, nftContract, nftIndex))
            {
                return true;
            }
        }
        return false;
    }

    // Returns the number of bonded tokens that have been transferred to another wallet
    function numberBondedTokensChanged()
    public view
    returns(uint) {
        uint[] memory indices = bondedTokenIndices();
        uint changed = 0;

        for (uint i = 0; i < indices.length; i++) {
            uint spotIndex = indices[i];
            address nftContract = _bondedNFTContractAddresses[spotIndex];
            uint nftIndex = _bondedNFTTokenIds[spotIndex];

            if (!doesBondedTokenOwnerMatch(spotIndex, nftContract, nftIndex))
            {
                changed += 1;
            }
        }

        return changed;
    }

    // Returns the indices of bonded tokens that have been transferred to other wallets
    function changedBondedTokensIndices()
    public view
    returns(uint[] memory) {
        uint[] memory indices = bondedTokenIndices();
        uint changed = numberBondedTokensChanged(); 
        
        uint[] memory changedTokens = new uint[](changed); 
        uint counter = 0;

        for (uint i = 0; i < indices.length; i++) {
            uint spotIndex = indices[i];
            address nftContract = _bondedNFTContractAddresses[spotIndex];
            uint nftIndex = _bondedNFTTokenIds[spotIndex];

            if (!doesBondedTokenOwnerMatch(spotIndex, nftContract, nftIndex))
            {
                changedTokens[counter] = spotIndex;
                counter += 1;
            }
        }

        return changedTokens;
    }

    function doesBondedTokenOwnerMatch(uint spotIndex, address nftContract, uint nftIndex)
    public view
    returns(bool) {
        return isNFTOwner(ownerOf(spotIndex), nftContract, nftIndex);
    }

    function bondedNFTMetadataURI(uint spotIndex)
    public view
    requireSpotBonded(spotIndex)
    returns (string memory) {
        address nftContract = _bondedNFTContractAddresses[spotIndex];
        uint nftIndex = _bondedNFTTokenIds[spotIndex];

        return genericTokenURI(nftContract, nftIndex);
    }

    function isBondedTokenOwner(address possibleOwner, uint spotIndex)
    public view
    requireSpotBonded(spotIndex)
    returns(bool) {
        address nftContract = _bondedNFTContractAddresses[spotIndex];
        uint nftIndex = _bondedNFTTokenIds[spotIndex];

        return isNFTOwner(possibleOwner, nftContract, nftIndex);
    }

    function ownerLink(uint spotIndex) public view returns(string memory) {
        return _ownerLink[spotIndex];
    }

    function bondedNFTCreatorLink(uint spotIndex) public view returns(string memory) {
        return _bondedNFTCreatorLink[spotIndex];
    }

    // Lookup token owner for any NFT
    function isNFTOwner(address possibleOwner, address nftContract, uint tokenIndex)
    public view
    requireInterfaceChecking(nftContract)
    returns(bool) {
        if (supportsERC721(nftContract)) {
            return possibleOwner == IERC721(nftContract).ownerOf(tokenIndex);
        }
        bool hasERC1155Support = supportsERC1155(nftContract);
        require(hasERC1155Support, "Contract does not support ERC721 or ERC1155");
        if (hasERC1155Support) {
            return IERC1155(nftContract).balanceOf(possibleOwner, tokenIndex) > 0;
        }
        return false;
    }

    // Lookup token URI for any NFT
    function genericTokenURI(address nftContract, uint tokenIndex)
    public view
    requireInterfaceChecking(nftContract)
    returns(string memory) {
        if (supportsIERC721Metadata(nftContract)) {
            return IERC721Metadata(nftContract).tokenURI(tokenIndex);
        }
        // 0x0e89341c is the ERC-165 interface identifier for IERC1155MetadataURI
        bool hasIERC1155MetadataURISupport = supportsIERC1155MetadataURI(nftContract);
        require(
            hasIERC1155MetadataURISupport,
            "Contract does not support IERC721Metadata or ERC1155MetadataURI");
        if (hasIERC1155MetadataURISupport) {
            return IERC1155MetadataURI(nftContract).uri(tokenIndex);
        }
        return "";
    }

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e)
    internal pure
    returns(string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

    function uint2str(uint _i)
    internal pure
    returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Interface support checkers
    function supportsInterface(address contractAddress, bytes4 interfaceId)
    private view
    requireInterfaceChecking(contractAddress)
    returns(bool) {
        return contractAddress.supportsInterface(interfaceId);
    }

    function supportsERC721(address contractAddress)
    internal view
    returns(bool) {
        // 0x80ac58cd is the ERC-165 interface identifier for IERC721Metadata
        return supportsInterface(contractAddress, 0x80ac58cd);
    }

    function supportsIERC721Metadata(address contractAddress)
    internal view
    returns(bool) {
        // 0x5b5e139f is the ERC-165 interface identifier for IERC721Metadata
        return supportsInterface(contractAddress, 0x5b5e139f);
    }

    function supportsERC1155(address contractAddress)
    internal view
    returns(bool) {
        // 0xd9b67a26 is the ERC-165 interface identifier for ERC1155
        return supportsInterface(contractAddress, 0xd9b67a26);
    }

    function supportsIERC1155MetadataURI(address contractAddress)
    internal view
    returns(bool) {
        // 0x0e89341c is the ERC-165 interface identifier for IERC1155MetadataURI
        return supportsInterface(contractAddress, 0x0e89341c);
    }

    // Modifier declarations
    modifier requireSpotOwner(uint256 spotIndex) {
        _requireSpotOwner(spotIndex);
        _;
    }

    modifier requireSpotBonded(uint256 spotIndex) {
        _requireSpotBonded(spotIndex);
        _;
    }

    modifier requireInterfaceChecking(address contractAddress) {
        _requireInterfaceChecking(contractAddress);
        _;
    }

    // Modifier implementations (reduces code size)
    function _requireSpotOwner(uint256 spotIndex)
    private view {
        require(ownerOf(spotIndex) == msg.sender, "Caller does not own the Spot");
    }

    function _requireSpotBonded(uint256 spotIndex)
    private view {
        require(isBonded(spotIndex), "Spot is not bonded");
    }

    function _requireInterfaceChecking(address contractAddress)
    private view {
        require(contractAddress.supportsERC165(), "Contract does not support type/ interface checking");
    }
}