// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "IRenderer.sol";
import "IAttributes.sol";
import "RandomV1.sol";

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Pausable.sol";
import "ERC721Burnable.sol";
import "IERC721Metadata.sol";
import "AccessControlEnumerable.sol";

contract Kohi is Context, AccessControlEnumerable, ERC721, ERC721Enumerable, ERC721Pausable, ERC721Burnable {

    using Address for address;

    struct Collection {
        string name;
        string baseTokenUri;        
        string description;
        string license;
        uint priceInWei;
        int32 seed;
        uint minted;
        uint mintedMax;        
        uint mintedMaxPerOwner;
        uint pauseAt;
        bool paused;
        bool active;        
        string[] creatorNames;
        address payable[] creatorAddresses; 
        uint8[] creatorSplits;
        bool useAllowList;
        address[] allowList;        
        address _renderer;
    }
    
    mapping(bytes32 => Collection) internal collections;   
    
    event CollectionMinted (
        bytes32 indexed collectionId,
        uint256 indexed tokenId,        
        address indexed recipient,        
        uint256 mintId,
        uint256 priceInWei,
        int32 seed
    );

    event CollectionAdded (
        bytes32 indexed collectionId
    );

    uint private lastTokenId;
    mapping(bytes32 => uint[]) private collectionTokens;        
    mapping(bytes32 => int32[]) private collectionSeeds;
    mapping(bytes32 => mapping(address => uint)) private ownerMints;

    mapping(uint => bytes32) internal tokenCollection;
    mapping(uint => int32) internal tokenSeed;

    uint8 private ownerRoyalty;
    address payable[] private ownerAddresses; 
    uint8[] private ownerSplits;
    address[] private bloomList;
    mapping(address => bool) private inBloomList;
    
    address internal _admin;

    constructor() ERC721("Kohi", "KOHI") {        
        lastTokenId = 0;
        _admin = _msgSender();
        _contractUri = "https://kohi.art/metadata";
        _pause();
    }

    string private _contractUri;

    /*
    * @dev See: https://docs.opensea.io/docs/contract-level-metadata
    */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function updateContractUri(string memory contractUri) public {
        require(_msgSender() == _admin, "admin only");
        _contractUri = contractUri;
    }

    function updateAdmin(address newAdmin) public {
        require(_msgSender() == _admin, "admin only");
        require(newAdmin != address(0x0), "address must be set");
        _admin = newAdmin;       
    }

    function updateOwnerData(uint8 royalty, address payable[] memory addresses, uint8[] memory splits) public {
        require(_msgSender() == _admin, "admin only");
        require(royalty > 0 && royalty <= 100, "invalid owner royalty");
        require(splits.length == addresses.length, "invalid owner splits");
        ownerRoyalty = royalty;
        ownerAddresses = addresses;
        ownerSplits = splits;
    }

    function togglePaused() public {
        require(_msgSender() == _admin, "admin only");
        if(paused()) {
            _unpause();
        }
        else {
            _pause();
        }
    }  

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);    
        require(inBloomList[_msgSender()] || !collections[tokenCollection[tokenId]].paused, "collection paused");                    
    }

    function isInBloomList(address _address) external view returns (bool) {
        require(_msgSender() == _admin, "admin only");
        return inBloomList[_address];        
    }

    function getBloomList() external view returns (address[] memory) {
        require(_msgSender() == _admin, "admin only");
        return bloomList;
    }

    function addToBloomList(address _address) external {
        require(_msgSender() == _admin, "admin only");
        require(_address != address(0x0) && !_address.isContract(), "invalid address");
        bloomList.push(_address);
        inBloomList[_address] = true;
    }

    function setBloomList(address[] memory _addresses) external {
        require(_msgSender() == _admin, "admin only");
        require(bloomList.length == 0, "bloom list exists");
        bloomList = _addresses;
        for(uint i = 0; i < bloomList.length; i++) {
            inBloomList[bloomList[i]] = true;
        }
    }

    function removeFromBloomList(address _address) external {
        require(_msgSender() == _admin, "admin only");
        int index = getBloomAddressIndex(_address);
        require(index > -1, "address not found");        
        if (uint(index) >= bloomList.length) return;
        for (uint i = uint(index); i < bloomList.length - 1; i++) {
            bloomList[i] = bloomList[i + 1];
        }
        bloomList.pop();  
        inBloomList[_address] = false;
    }

    function getBloomAddressIndex(address _address) private view returns(int) {
        for(int i = 0; i < int(bloomList.length); i++) {
            if(bloomList[uint(i)] == _address)
                return i;
        }
        return -1;
    }

    function getCollection(bytes32 collectionId) public view returns (Collection memory collection) {
        require(collectionId.length > 0, "ID must be set");
        collection = collections[collectionId];
        require(bytes(collections[collectionId].name).length > 0, "collection not found");        
    }

    function addCollection(Collection memory collection) external {
        require(_msgSender() == _admin, "admin only");
        require(bytes(collection.name).length > 0, "name must be set");
        
        bytes32 id = keccak256(abi.encodePacked(collection.name));
        require(bytes(collections[id].name).length == 0, "collection already added");
        require(collection._renderer != address(0x0) && collection._renderer.isContract(), "invalid renderer");

        collections[id] = collection;
        emit CollectionAdded(id);
    }

    function updateCollection(bytes32 collectionId, Collection memory collection) public {
        require(_msgSender() == _admin, "admin only");
        require(bytes(collection.name).length > 0, "name must be set");
        
        collectionId = keccak256(abi.encodePacked(collection.name));
        require(bytes(collections[collectionId].name).length > 0, "collection not found");
        require(collection._renderer != address(0x0) && collection._renderer.isContract(), "invalid renderer");

        collections[collectionId] = collection;
    }
        
    /**
     * @notice Sets the collection's unique seed. It cannot be modified once set.
     * @dev This is a source of external entropy, by the contract owner, to avoid determinism on PRNG that could exploit the mint's parameters.
     */
    function setSeed(bytes32 collectionId, int32 seed) external {  
        require(_msgSender() == _admin, "admin only");
        require(seed != 0, "invalid seed");
        require(collections[collectionId].seed == 0, "seed already set");
        collections[collectionId].seed = seed;
    }

    function getSeed(bytes32 collectionId) external view returns (int32) {  
        require(_msgSender() == _admin, "admin only");
        require(collections[collectionId].seed != 0, "seed not set");
        return collections[collectionId].seed;
    }

    function purchase(bytes32 collectionId) external payable {
        purchaseFor(collectionId, _msgSender());
    }

    function purchaseFor(bytes32 collectionId, address recipient) public payable {
        require(!_msgSender().isContract(), "cannot purchase from contract");                
        require(msg.value >= collections[collectionId].priceInWei, "insufficient funds sent to purchase");
        
        Collection memory collection = getCollection(collectionId);

        bool allowedToMint = false;
        if(collection.useAllowList && collection.allowList.length > 0) {
            for(uint i = 0; i < collection.allowList.length; i++) {
                if(_msgSender() == collection.allowList[i]) {
                    allowedToMint = true;
                    break;
                }
            }
        } else {
            allowedToMint = true;
        }
        require(allowedToMint, "mint not approved");

        mint(collectionId, _msgSender(), recipient);

        require(ownerAddresses.length > 0, "no owner addresses");
        require(ownerSplits.length == ownerAddresses.length, "invalid owner splits");
        require(collection.creatorAddresses.length > 0, "no creator addresses");
        require(collection.creatorSplits.length == collection.creatorAddresses.length, "invalid creator splits");

        distributeFunds(collection);
    }

    function mint(bytes32 collectionId, address minter, address recipient) internal {

        Collection memory collection = getCollection(collectionId);
        require(collections[collectionId].seed != 0, "seed not set");
        require(collection.active, "collection inactive");        
        require(collection.minted + 1 <= collection.mintedMax, "minted max tokens");
        require(collection.mintedMaxPerOwner == 0 || ownerMints[collectionId][minter] < collection.mintedMaxPerOwner, "minter exceeds max mints");
        
        uint256 nextTokenId = lastTokenId + 1;
        int32 seed = int32(int(uint(keccak256(abi.encodePacked(collection.seed, block.number, _msgSender(), recipient, nextTokenId)))));
        
        lastTokenId = nextTokenId;
        collectionTokens[collectionId].push(lastTokenId);
        tokenCollection[lastTokenId] = collectionId;

        collectionSeeds[collectionId].push(seed);
        tokenSeed[lastTokenId] = seed;        
        collections[collectionId].minted = collection.minted + 1;
        ownerMints[collectionId][recipient] = ownerMints[collectionId][recipient] + 1;

        _safeMint(recipient, nextTokenId);
        emit CollectionMinted(collectionId, nextTokenId, recipient, collection.minted, collection.priceInWei, seed);

        if(collection.pauseAt > 0) {
            if(lastTokenId >= collection.pauseAt)
                _pause();
        }
    }

    function distributeFunds(Collection memory collection) private {
        if (msg.value > 0) {

            uint priceInWei = collection.priceInWei;
            uint overpaid = msg.value - priceInWei;
            if (overpaid > 0) {
                payable(_msgSender()).transfer(overpaid);
            }

            uint dueToOwners = ownerRoyalty * collection.priceInWei / 100;        
            uint paidToOwners = distributeSplits(dueToOwners, ownerAddresses, ownerSplits);            
            uint dueToCreators = priceInWei - paidToOwners;
            uint paidToCreators = distributeSplits(dueToCreators, collection.creatorAddresses, collection.creatorSplits);

            require(priceInWei - paidToOwners - paidToCreators == 0, "funds had remainder");            
        }
    }

    function distributeSplits(uint fundsToDistribute, address payable[] memory addresses, uint8[] memory splits) 
        private returns(uint paidToAddresses)
    {
        paidToAddresses = 0;
        if (fundsToDistribute > 0) {                
            uint8 sum = 0;
            for(uint8 i = 0; i < splits.length; i++) {
                sum += splits[i];
            }
            require(sum == 100, "splits must sum to 100%");

            for(uint8 i = 0; i < addresses.length; i++) {
                uint dueToAddress = splits[i] * fundsToDistribute / 100;
                addresses[i].transfer(dueToAddress);
                paidToAddresses += dueToAddress;
            }
        }
        require(fundsToDistribute - paidToAddresses == 0, "incorrect distribution of funds");
    }   
    
    function ownsToken(address owner, uint tokenId) public view returns (bool) {
        for(uint i = 0; i < balanceOf(owner); i++) {
            if(tokenId == tokenOfOwnerByIndex(owner, i)) {
                return true;
            }            
        }
        return false;
    }  

    /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Collection memory collection = collections[tokenCollection[tokenId]];
        string memory baseURI = collection.baseTokenUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }  

    /**
     * @notice Retrieve's an artwork's attributes, given a token ID.
     */
    function getAttributes(uint tokenId) external view returns (string memory attributes) {
        require(_msgSender() == _admin || ownsToken(_msgSender(), tokenId), "unowned token");
        return IAttributes(collections[tokenCollection[tokenId]]._renderer).getAttributes(tokenSeed[tokenId]);
    }

    /**
     * @notice Begins rendering an artwork given a token ID, and continuation arguments, which must be owned by the caller.
     */
    function _render(uint tokenId, IRenderer.RenderArgs memory args) private view returns (IRenderer.RenderArgs memory results) {
        require(_msgSender() == _admin || ownsToken(_msgSender(), tokenId), "unowned token");
        require(args.seed == tokenSeed[tokenId], "invalid seed");
        return IRenderer(collections[tokenCollection[tokenId]]._renderer).render(args);
    }

    /**
     * @notice Continues rendering an artwork given a token ID and previous arguments. Token must be owned by the caller.
     */
    function render(uint tokenId, IRenderer.RenderArgs memory args) external view returns (IRenderer.RenderArgs memory results) {        
        return _render(tokenId, args);
    }

    /**
     * @notice Begins rendering an artwork given a token ID. Token must be owned by the caller.
     */
    function beginRender(uint tokenId) external view returns (IRenderer.RenderArgs memory results) {        
        uint32[16384] memory buffer;
        RandomV1.PRNG memory prng;
        return _render(tokenId, IRenderer.RenderArgs(0, 0, tokenSeed[tokenId], buffer, prng));
    }
}