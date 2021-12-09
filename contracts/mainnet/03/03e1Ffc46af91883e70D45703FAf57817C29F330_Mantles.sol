// SPDX-License-Identifier: MIT

// File: Mantles.sol

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";
import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";

contract Mantles is ERC721Enumerable, Ownable {
    using ERC165Checker for address;

    string public metadataURIPrefix = "";

    uint public mintFeeWei;
    uint public mintLimitPerTx;
    uint public tempMaxMantleCount;

    uint public constant MAX_MANTLE_COUNT = 999;
    
    string public constant THUMBNAIL_IPFS_ID = "QmdXbN8AnKiug8h1SVD9mUmHBeu6vAgLgks6CVBpyV7Qem";

    // Contract/ Mantle lifecycle functions
    constructor(string memory initialMetadataURIPrefix, uint initialMintFeeInWei,
        uint initialMintLimitPerTx, uint initialMaxMantleCount)
    ERC721("Mantles", "MANTLE") {
        metadataURIPrefix = initialMetadataURIPrefix;
        mintFeeWei = initialMintFeeInWei;
        mintLimitPerTx = initialMintLimitPerTx;
        tempMaxMantleCount = initialMaxMantleCount;
    }

    function mint(uint mintQuantity)
    public payable
    returns(uint) {
        require(mintQuantity > 0, "Mantles: cannot mint 0 Mantles");
        require(mintQuantity <= mintLimitPerTx, "Mantles: mint limit exceeded");
        require(msg.value >= mintFeeWei * mintQuantity, "Mantles: mint fee required");
        uint totalSupply = totalSupply();
        uint lastIndex = totalSupply + mintQuantity;
        require(
            (lastIndex <= tempMaxMantleCount || _msgSender() == owner())
                && lastIndex <= MAX_MANTLE_COUNT,
            "Mantles: not enough Mantles left"
        );
        // Determine first and last indices to mint
        uint firstIndex = totalSupply + 1;
        // Mint the first Mantle safely to ensure an appropriate address is receiving it
        _safeMint(_msgSender(), firstIndex);
        if (mintQuantity > 1) {
            // Loop through all remaining indices and mint a Mantle for each
            for (uint mantleIndex = firstIndex + 1; mantleIndex <= lastIndex; mantleIndex++) {
                // Since _safeMint of the first Mantle index would reject unsafe receivers, we can
                // now use unsafe minting for the remaining indices (as the receiver must be safe)
                _mint(_msgSender(), mantleIndex);
            }
        }
        // Return the index of the first minted Mantle
        return firstIndex;
    }

    function withdrawFunds()
    public
    onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Mantles: no balance to withdraw");
        payable(owner()).transfer(balance);
    }

    function setMintFee(uint newMintFeeWei)
    external
    onlyOwner {
        mintFeeWei = newMintFeeWei;
    }

    function setMintLimitPerTx(uint newMintLimitPerTx)
    external
    onlyOwner {
        mintLimitPerTx = newMintLimitPerTx;
    }

    function setTempMaxMantleCount(uint newTempMaxMantleCount)
    external
    onlyOwner {
        tempMaxMantleCount = newTempMaxMantleCount;
    }

    // Fallback function for receiving ETH
    receive() external payable { }

    // Metadata management functions
    function _baseURI()
    internal view override(ERC721)
    returns(string memory) {
        return metadataURIPrefix;
    }

    function setMetadataURIPrefix(string memory uriPrefix)
    external
    onlyOwner {
        metadataURIPrefix = uriPrefix;
    }

    // Helper functions
    function mantleExists(uint mantleIndex)
    public view
    returns(bool) {
        return _exists(mantleIndex);
    }

    function doesMantleOwnerMatchNFTOwner(uint mantleIndex, address nftContract, uint nftIndex)
    public view
    returns(bool) {
        return isNFTOwner(ownerOf(mantleIndex), nftContract, nftIndex);
    }

    function isNFTOwner(address possibleOwner, address nftContract, uint tokenIndex)
    public view
    requireInterfaceChecking(nftContract)
    returns(bool) {
        if (_supportsIERC721(nftContract)) {
            return possibleOwner == IERC721(nftContract).ownerOf(tokenIndex);
        }
        bool hasIERC1155Support = _supportsIERC1155(nftContract);
        require(hasIERC1155Support, "Mantles: invalid contract type"
        );
        if (hasIERC1155Support) {
            return IERC1155(nftContract).balanceOf(possibleOwner, tokenIndex) > 0;
        }
        return false;
    }

    function genericTokenURI(address nftContract, uint tokenIndex)
    public view
    requireInterfaceChecking(nftContract)
    returns(string memory) {
        if (_supportsIERC721Metadata(nftContract)) {
            return IERC721Metadata(nftContract).tokenURI(tokenIndex);
        }
        bool hasIERC1155MetadataURISupport = _supportsIERC1155MetadataURI(nftContract);
        require(hasIERC1155MetadataURISupport, "Mantles: no metadata on contract");
        if (hasIERC1155MetadataURISupport) {
            return IERC1155MetadataURI(nftContract).uri(tokenIndex);
        }
        return "";
    }

    // Interface support checkers
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721Enumerable)
    returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    function _supportsInterface(address contractAddress, bytes4 interfaceId)
    private view
    requireInterfaceChecking(contractAddress)
    returns(bool) {
        return contractAddress.supportsInterface(interfaceId);
    }

    function _supportsIERC721(address contractAddress)
    internal view
    returns(bool) {
        return _supportsInterface(contractAddress, type(IERC721).interfaceId);
    }

    function _supportsIERC721Metadata(address contractAddress)
    internal view
    returns(bool) {
        return _supportsInterface(contractAddress, type(IERC721Metadata).interfaceId);
    }

    function _supportsIERC1155(address contractAddress)
    internal view
    returns(bool) {
        return _supportsInterface(contractAddress, type(IERC1155).interfaceId);
    }

    function _supportsIERC1155MetadataURI(address contractAddress)
    internal view
    returns(bool) {
        return _supportsInterface(contractAddress, type(IERC1155MetadataURI).interfaceId);
    }

    // Modifier declarations
    modifier requireMantleExists(uint mantleIndex) {
        _requireMantleExists(mantleIndex);
        _;
    }

    modifier requireMantleOwnerOrContractOwner(uint mantleIndex) {
        _requireMantleOwnerOrContractOwner(mantleIndex);
        _;
    }

    modifier requireInterfaceChecking(address contractAddress) {
        _requireInterfaceChecking(contractAddress);
        _;
    }

    // Modifier implementations (reduces code size)
    function _requireMantleExists(uint mantleIndex)
    private view {
        require(mantleExists(mantleIndex), "Mantles: Mantle does not exist");
    }

    function _requireMantleOwnerOrContractOwner(uint mantleIndex)
    private view {
        require(
            owner() == _msgSender() || ownerOf(mantleIndex) == _msgSender(),
            "Mantles: must own or manage"
        );
    }

    function _requireInterfaceChecking(address contractAddress)
    private view {
        require(contractAddress.supportsERC165(), "Mantles: no type check support");
    }
}