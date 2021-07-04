pragma solidity ^0.7.0;

import "./IERC165.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ISPT.sol";
import "./ISpirits.sol";
import "./IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

/**
 * @title CryptoSpirits contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Spirits is Context, Ownable, ERC165, ISpirits, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    uint256 public constant SALE_START_TIMESTAMP = 1625245200; // Friday, July 2, 2021 6:00:00 PM BST

    // time after which CryptoSpirits artworks are randomized and assigned to NFTs
    uint256 public constant DISTRIBUTION_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 5); // 5 is number of days
    
    uint256 public constant REVEAL_STAGE_INTERVAL = (86400 * 1); // 1 day between reveal unlocks

    uint256 public constant MAX_NFT_SUPPLY = 7777;

    uint256 public usernameChangePrice = 10 * (10 ** 18);
    
    uint256 public nodenameChangePrice = 10 * (10 ** 18);

    uint256 public startingIndexBlock;

    uint256 public startingIndex;
    
    bool private _salePaused = false;
    
    uint256 public price_bracket_1 = 0.08 * (10 ** 18);
    uint256 public price_bracket_2 = 0.15 * (10 ** 18);
    uint256 public price_bracket_3 = 0.22 * (10 ** 18);
    
    // Mapping from token ID to reward multiplier numerator and denominator
    mapping (uint256 => uint256) private _tokenRewardMultiplierNum;
    mapping (uint256 => uint256) private _tokenRewardMultiplierDen;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from address to username
    mapping (address => string) private _usernames;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _usernameReserved;
    
     // Mapping from token ID to the timestamp the NFT was minted
    mapping (uint256 => uint256) private _mintedTimestamp;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    // node name changes
    bool public nodeNameChangesEnabled = false;

    // token name
    string private _name;

    // token symbol
    string private _symbol;
    
    // base URI
    string private _baseURI;
    
    // contract URI
    string private _contractURI;

    // name change token address
    address private _sptAddress;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Events
    event NodeNameChange (uint256 indexed nodeId, string newName);
    event UsernameChange (address user, string newName);
    event NodeRegistered (uint256 indexed nodeId, string name, address owner);
    event NodeUnregistered (uint256 indexed nodeId, string name, address owner);
    
    /**
     * @dev Initializes the contract which sets a name and a symbol to the token collection.
     */
    constructor () {
        _name = "CryptoSpirits";
        _symbol = "SPIRITS";
        _sptAddress = 0x3e4E8ECB65cB5bA5E791BB955F8Bbc5c9Ad421c7;
        
        // for third-party metadata fetching
        _baseURI = "https://spirit.app:7777/api/opensea/";
        _contractURI = "https://spirit.app:7777/api/contractmeta";

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    
    /*
        Node Code
    */
    // Mapping from holder address to their (enumerable) set of owned nodes
    mapping (address => EnumerableSet.UintSet) private _ownerNodes;
    
    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _nodeOwners;
    
    // Mapping from node ID to name
    mapping (uint256 => string) private _nodeNames;
    
     // Mapping from node ID to the timestamp the node was registered
    mapping (uint256 => uint256) private _nodeRegTimes;
    
    // Mapping from node ID to the timestamp the node was unregistered
    mapping (uint256 => uint256) private _nodeUnregTimes;
    
    // Mapping from node ID to the type of node
    mapping (uint256 => uint256) private _nodeTypes;
    
    // Mapping from node ID to the bool of whether it is valid
    mapping (uint256 => bool) private _nodeValid;
    
    // Mapping from token ID to the node Id
    mapping (uint256 => uint256) private _tokenNodeIds;
    
    // Mapping from node ID to the containing token Ids
    mapping (uint256 => uint256[]) private _nodeTokenIds;
    
    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nodeNameReserved;
    
    // number of active (registered) nodes
    uint256 private _activeNodes = 0;
    
    function registerNode(uint256[] memory tokenIds, string memory _nodeName, uint256 _nodeType) public returns (uint256) {
        require((tokenIds.length == 5 && (_nodeType == 1 || _nodeType == 3)) || (tokenIds.length == 15 && _nodeType == 2) || (tokenIds.length == 6 && _nodeType == 4), "Invalid number of tokenIds for type of node");
        require(validateName(_nodeName), "Not a valid node name");
        require(!isNodeNameReserved(_nodeName), "Name already reserved");
        address sender = _msgSender();
        for (uint i = 0; i < tokenIds.length; i++) {
            // for each token, check it only appears once in the array
            for (uint j = i + 1; j < tokenIds.length; j++) {
               require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }
            require(sender == ownerOf(tokenIds[i]), "Caller does not own tokenId");
            require(nodeIdFromTokenId(tokenIds[i]) == 0, "Token already registered to node");
            require(revealStageByIndex(tokenIds[i]) >= 4, "All Spirits must be fully awakened to be registered to a node");
        }
        
        // register node
        uint256 nodeId = totalNodes().add(1);
        _nodeOwners.set(nodeId, sender);
        _ownerNodes[sender].add(nodeId);
        _nodeTypes[nodeId] = _nodeType;
        _nodeRegTimes[nodeId] = block.timestamp;
        _nodeUnregTimes[nodeId] = 0;
        _nodeTokenIds[nodeId] = tokenIds;
        
        // air and earth nodes auto approved
        if(_nodeType == 1 || _nodeType == 2) {
            _nodeValid[nodeId] = true;
        }
        // water and fire nodes require manual approval
        else {
            _nodeValid[nodeId] = false;
        }
        
        for (uint i = 0; i < tokenIds.length; i++) {
            _tokenNodeIds[tokenIds[i]] = nodeId;
        }

        toggleReserveNodeName(_nodeName, true);
        _nodeNames[nodeId] = _nodeName;
        _activeNodes = _activeNodes.add(1);
        emit NodeRegistered(nodeId, _nodeName, sender);
        return nodeId;
    }
    
    function unregisterNode(uint256 nodeId) public {
        address sender = _msgSender();
        require(sender == ownerOfNode(nodeId), "Caller does not own node");
        require(nodeActive(nodeId), "Node is already unregistered");
        _unregisterNode(nodeId, sender);
    }
    
    function _unregisterNode(uint256 nodeId, address owner) internal returns (uint256) {
        require(nodeActive(nodeId), "Node is already unregistered");
        // _ownerNodes[owner].remove(nodeId);
        // _nodeOwners.remove(nodeId);
        _nodeUnregTimes[nodeId] = block.timestamp;
        uint256[] memory tokenIds = _nodeTokenIds[nodeId];
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 token = tokenIds[i];
            _tokenNodeIds[token] = 0;
        }
        // dereserve old name
        toggleReserveNodeName(_nodeNames[nodeId], false);
        if(_activeNodes >= 1) {
            _activeNodes = _activeNodes.sub(1);
        }
        emit NodeUnregistered(nodeId, _nodeNames[nodeId], owner);
        return _nodeUnregTimes[nodeId];
    }
    
    /* returns a plethora of node info */
    function nodeInfo(uint256 nodeId) public view override returns (address, string memory, uint256, uint256, uint256, bool, uint256[] memory) {
        require(nodeExists(nodeId), "Node with specified id does not exist");
        return (ownerOfNode(nodeId), _nodeNames[nodeId], _nodeRegTimes[nodeId], _nodeUnregTimes[nodeId], _nodeTypes[nodeId], _nodeValid[nodeId], _nodeTokenIds[nodeId]);
    }
    
    /* returns count of active (registered and not unregistered) nodes */
    function totalActiveNodes() public view override returns (uint256) {
        return _activeNodes;
    }

    /* returns count of nodes owned by owner */
    function nodeBalanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownerNodes[owner].length();
    }
    
    /* returns node owner */
    function ownerOfNode(uint256 nodeId) public view override returns (address) {
        return _nodeOwners.get(nodeId, "ERC721: owner query for nonexistent node");
    }
    
    /* returns node owned by owner at a given index */
    function nodeOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _ownerNodes[owner].at(index);
    }
    
    /* returns total number of nodes registered (active and inactive) */
    function totalNodes() public view override returns (uint256) {
        // _tokenOwners are indexed by nodeIds, so .length() returns the number of nodeIds
        return _nodeOwners.length();
    }
    
    /* returns the type of node (1 / 2 / 3 / 4) */
    function nodeType(uint256 nodeId) public view override returns (uint256) {
        return _nodeTypes[nodeId];
    }
    
     /* returns the size of the node (no. of tokens it contains) */
    function nodeSize(uint256 nodeId) public view override returns (uint256) {
        return _nodeTokenIds[nodeId].length;
    }
    
    /* returns whether the node has been validated */
    function nodeValid(uint256 nodeId) public view override returns (bool) {
        return _nodeValid[nodeId];
    }
    
    /* returns the timestamp the node was registered */
    function nodeRegTime(uint256 nodeId) public view override returns (uint256) {
        return _nodeRegTimes[nodeId];
    }
    
    /* returns the timestamp the node was unregistered (returns 0 if still active) */
    function nodeUnregTime(uint256 nodeId) public view override returns (uint256) {
        return _nodeUnregTimes[nodeId];
    }
    
    /* returns the name of the node with ID */
    function nodeName(uint256 nodeId) public view override returns (string memory) {
        return _nodeNames[nodeId];
    }
    
    /* returns whether the node is still registered */
    function nodeActive(uint256 nodeId) public view override returns (bool) {
        return _nodeRegTimes[nodeId] != 0 && _nodeUnregTimes[nodeId] == 0;
    }
    
    /* returns the timestamp the node was unregistered (returns 0 if still active) */
    function nodeTokenIds(uint256 nodeId) public view override returns (uint256[] memory) {
        return _nodeTokenIds[nodeId];
    }
    
    /* returns is the node name has been reserved */
    function isNodeNameReserved(string memory nameString) public view override returns (bool) {
        return _nodeNameReserved[toLower(nameString)];
    }
    
    /* returns the nodeId of the registered node of the tokenId */
    function nodeIdFromTokenId(uint256 tokenId) public view override returns (uint256) {
        return _tokenNodeIds[tokenId];
    }
    
    function nodeExists(uint256 nodeId) public view override returns (bool) {
        return _nodeOwners.contains(nodeId);
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function username(address owner) public view override returns (string memory) {
        return _usernames[owner];
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }
    
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isUserNameReserved(string memory nameString) public view override returns (bool) {
        return _usernameReserved[toLower(nameString)];
    }
    
    /**
     * @dev Returns the timestamp of the block in which the NFT was minted
     */
    function mintedTimestampByIndex(uint256 index) public view override returns (uint256) {
        return _mintedTimestamp[index];
    }
    
    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token with specified ID does not exist");
        return Strings.Concatenate(
            baseTokenURI(),
            Strings.UintToString(tokenId)
        );
    }
        
    /**
     * @dev Gets the base token URI
     * @return string representing the base token URI
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseURI;
    }
    
    /**
     * @dev Gets the contract URI for contract level metadata
     * @return string representing the contract URI
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner external {
       _baseURI = baseURI;
    }
    
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeContractURI(string memory newContractURI) onlyOwner external {
       _contractURI = newContractURI;
    }
    
    /**
    * @dev Pauses / Unpauses the sale to Disable/Enable minting of new NFTs (Callable by owner only)
    */
    function toggleSalePause(bool salePaused) onlyOwner external {
       _salePaused = salePaused;
    }
    
    /**
    * @dev Changes the price for a sale bracket - prices can never be less than current price (Callable by owner only)
    */
    function changeBracketPrice(uint bracket, uint256 price) onlyOwner external {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(bracket > 0 && bracket < 4, "Bracket must be in the range 1-3");
        require(price > 0, "Price must be set and greater than 0");
        
        if(bracket == 1) {
            price_bracket_1 = price;
        }
        else if(bracket == 2) {
            price_bracket_2 = price;
        }
        else if(bracket == 3) {
            price_bracket_3 = price;
        }
    }
    
    /**
    * @dev Changes the price for a name change (if in future the price needs adjusting due to token speculation) (Callable by owner only)
    */
    function changeUsernameChangePrice(uint256 price) onlyOwner external {
        usernameChangePrice = price;
    }
    
     /**
    * @dev Changes the price for a name change (if in future the price needs adjusting due to token speculation) (Callable by owner only)
    */
    function changeNodeNameChangePrice(uint256 price) onlyOwner external {
        nodenameChangePrice = price;
    }
    
     /**
    * @dev Changes the price for a name change (if in future the price needs adjusting due to token speculation) (Callable by owner only)
    */
    function toggleNodeNameChangesEnabled(bool enabled) onlyOwner external {
        nodeNameChangesEnabled = enabled;
    }
    
    /**
    * @dev validates a node to enable/disable claiming of rewards (Callable by owner only)
    */
    function validateNode(uint256 nodeId, bool isValid) onlyOwner external {
        _nodeValid[nodeId] = isValid;
    }
    
    /**
    * @dev sets the reward multiplier for a token (Callable by owner only)
    */
    function setTokenRewardMultiplier(uint256 tokenId, uint256 newNum, uint256 newDen) onlyOwner external {
        _tokenRewardMultiplierNum[tokenId] = newNum;
        _tokenRewardMultiplierDen[tokenId] = newDen;
    }
    
     /**
     * @dev Returns the reward multiplier (numerator and denominator) for a given tokenId
     */
    function tokenRewardMultiplier(uint256 tokenId) external view override returns (uint256, uint256) {
        uint256 num = _tokenRewardMultiplierNum[tokenId];
        uint256 den = _tokenRewardMultiplierDen[tokenId];
        return (num, den);
    }
    
    /**
    * @dev validates a node to enable claiming of rewards (Callable by owner only)
    */
    function testTokenRewardMultiplier(uint256 newNum, uint256 newDen) public pure override returns (uint256) {
        uint256 ONE = 1 * (10 ** 18);
        uint256 TEN = ONE * 10;
        uint256 newRate = (ONE.mul(newNum)).div(newDen);
        require(newRate != ONE, "emission will not change");
        require(newRate > ONE, "emission will decrease");
        require(newRate < TEN, "emission will increase over 10x");
        return newRate;
    }
    
    /**
     * @dev Returns stage of reveal for a Spirit
     * 0 - token is not yet minted
     */
    function revealStageByIndex(uint256 index) public view override returns (uint256) {
        uint256 mintTime = _mintedTimestamp[index];
        require(mintTime > 0, "Mint time must be set and greater than 0");
        require(mintTime <= block.timestamp, "Mint time cannot be greater than current time");
        
        if(mintTime < DISTRIBUTION_TIMESTAMP) {
            mintTime = DISTRIBUTION_TIMESTAMP;
        }
        
        if(block.timestamp <= mintTime) {
            // not passed distribution period - no reveal stages
            return 1;
        }
        
        uint256 elapsed = block.timestamp.sub(mintTime);
        
        uint unlocked = 1;
        for(uint i = 1; i < 4; i++) {
            if(elapsed >= i.mul(REVEAL_STAGE_INTERVAL)) {
                unlocked++;
            }
            else {
                break;
            }
        }
        return unlocked;
    }

    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        
        uint currentSupply = totalSupply();

        if (currentSupply >= 6000) {
            return price_bracket_3;      // 6000 - 7777
        } 
        else if (currentSupply >= 2000) {
            return price_bracket_2;      // 2000 - 5999
        } 
        else {
            return price_bracket_1;      // 0 - 1999
        }
    }

    /**
    * @dev Mints Spirits
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(!_salePaused, "Sale has been paused");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 25, "You may not buy more than 25 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            /* final supply check */
            require(mintIndex < MAX_NFT_SUPPLY, "Sale has already ended");
            _mintedTimestamp[mintIndex] = block.timestamp;
            _tokenRewardMultiplierNum[mintIndex] = 1;
            _tokenRewardMultiplierDen[mintIndex] = 1;
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of randomness
        */
        if (startingIndexBlock == 0 && (totalSupply() >= MAX_NFT_SUPPLY || block.timestamp >= DISTRIBUTION_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        
        if(startingIndexBlock == 0) {
            require(block.timestamp >= DISTRIBUTION_TIMESTAMP, "Distribution period must be over to set the startingIndexBlock");
            startingIndexBlock = block.number;
        }
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        
        startingIndex = randomHash % MAX_NFT_SUPPLY;
        // Prevent default sequence / overflow
        if (startingIndex == 0 || startingIndex >= MAX_NFT_SUPPLY) {
            startingIndex = 1;
        } 
    }

    /**
     * @dev Changes the username for a user
     */
    function changeUsername(string memory newName) public {
        address sender = _msgSender();
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_usernames[sender])), "New username is same as the current one");
        require(isUserNameReserved(newName) == false, "Username already reserved");

        ISPT(_sptAddress).transferFrom(msg.sender, _sptAddress, usernameChangePrice);
        // If already named, dereserve old name
        if (bytes(_usernames[sender]).length > 0) {
            toggleReserveUsername(_usernames[sender], false);
        }
        toggleReserveUsername(newName, true);
        _usernames[sender] = newName;
        emit UsernameChange(sender, newName);
    }
    
    /**
     * @dev Changes the name for CryptoSpirits tokenId
     */
    function changeNodeName(uint256 nodeId, string memory newName) public {
        require(nodeNameChangesEnabled == true, "Node name changes are currently disabled");
        address owner = ownerOfNode(nodeId);
        require(_msgSender() == owner, "ERC721: caller is not the node owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_nodeNames[nodeId])), "New name is same as the current one");
        require(isNodeNameReserved(newName) == false, "Name already reserved");

        ISPT(_sptAddress).transferFrom(msg.sender, _sptAddress, nodenameChangePrice);
        // If already named, dereserve old name
        if (bytes(_nodeNames[nodeId]).length > 0) {
            toggleReserveNodeName(_nodeNames[nodeId], false);
        }
        toggleReserveNodeName(newName, true);
        _nodeNames[nodeId] = newName;
        emit NodeNameChange(nodeId, newName);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    /**
     * @dev Withdraw from the SPT contract (Callable by owner)
     * Note: Only spent SPTs (i.e. from name changes) are withdrawable here
    */
    function withdrawSPT() onlyOwner public {
        uint balance = ISPT(_sptAddress).balanceOf(_sptAddress);
        ISPT(_sptAddress).transferFrom(_sptAddress, msg.sender, balance);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        uint256 nodeId = nodeIdFromTokenId(tokenId);
        if(nodeId > 0 && nodeActive(nodeId) && to != ownerOfNode(nodeId)) {
            // unregister any active nodes this token is linked to
            _unregisterNode(nodeId, from);
        }
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveUsername(string memory str, bool isReserve) internal {
        _usernameReserved[toLower(str)] = isReserve;
    }
    
    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveNodeName(string memory str, bool isReserve) internal {
        _nodeNameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 16) return false; // Cannot be longer than 16 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 || lastChar == 0x20) return false; // Cannot contain spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}