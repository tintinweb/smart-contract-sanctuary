/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface LegacyCollection is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenDetails(uint256 tokenId) external view returns (BinamonToken memory token, BinamonType memory type_);
    function totalTypes() external view returns (uint256);
    function typeByIndex(uint256 index) external view returns (BinamonType memory);
}

interface BanList {
    function isBanned(uint256 tokenId) external view returns (bool);
}

interface AddressBanList {
    function isBanned(address user) external view returns (bool);
}

contract Trustable {
    address private _owner;
    mapping (address => bool) private _isTrusted;
    address[] private delegates;

    constructor () {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyTrusted {
        require(_isTrusted[msg.sender] == true || _owner == msg.sender, "Caller is not trusted");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
    }
    
    function addTrusted(address user) public onlyOwner {
        _isTrusted[user] = true;
        delegates.push(user);
    }

    function removeTrusted(address user) public onlyOwner {
        _isTrusted[user] = false;
    }
    
    function isTrusted(address user) public view returns (bool) {
        return _isTrusted[user];
    }
    
    function getDelegates() public view returns (address[] memory) {
        return delegates;
    }
}

contract Pausable is Trustable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused || msg.sender == owner());
        _;
    }

    modifier whenPaused() {
        require(paused || msg.sender == owner());
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
    }
}


// Type definitions
struct BinamonTypeV2 {
    string _hash;
    string _name;
    string _extra;
    string _info;
}

struct BinamonTokenV2 {
    uint256 _type;
    uint256[] paramValues;
}

struct BinamonType {
    uint256 _class;
    string _hash;
    string _name;
    string _extra;
    string _info;
}

struct BinamonToken {
    uint256 _type;
    uint256 _attack;
    uint256 _hornpower;
    string _element;
}

// Binamon main smart contract

contract BinamonCollectionV2 is IERC721Metadata, Pausable {
    
    using SafeMath for uint256;
    
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // ERC721 data
    uint256 _totalSupply;
    mapping(address => uint256[]) internal ownedTokens;
    mapping(uint256 => uint256) internal ownedTokensIndex;
    mapping (uint256 => address) internal tokenOwner;
    mapping (uint256 => address) internal tokenApprovals;
    mapping (address => uint256) internal ownedTokensCount;
    mapping (address => mapping (address => bool)) internal operatorApprovals;
    LegacyCollection internal _legacyCollection;
    mapping (uint256 => uint256) internal _legacyTypes;

    // Token types and tokens
    address arrestAddress;
    mapping (uint256 => uint256) private bans;
    mapping (uint256 => bool) private explicitBans;
    BanList internal legacyBanList;
    AddressBanList internal addressBanList;
    string internal baseURI;
    uint256 internal typeCount;
    mapping (uint256 => BinamonTypeV2) internal types;
    mapping (uint256 => BinamonTokenV2) internal tokens;
    
    // Param names and limits
    string[] internal _paramNames;
    
    // Initializes the contract by setting a `name` and a `symbol` to the token collection.
    constructor () {
        typeCount = 0;
        arrestAddress = msg.sender;
        
        baseURI = "https://ipfs.io/ipfs/";
        
        emit Transfer(address(0), msg.sender, 0); // Dummy event for BSCScan to recognize token
    }

    // Returns token name
    function name() public override view returns (string memory) {
        return _name;
    }

    // Returns token symbol
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    
    function addTokenTo(address to, uint256 tokenId) internal {
        require(tokenOwner[tokenId] == address(0));
        tokenOwner[tokenId] = to;
        ownedTokensCount[to] = ownedTokensCount[to].add(1);
        uint256 length = ownedTokens[to].length;
        ownedTokens[to].push(tokenId);
        ownedTokensIndex[tokenId] = length;
    }

    function removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        ownedTokensCount[from] = ownedTokensCount[from].sub(1);
        tokenOwner[tokenId] = address(0);
        uint256 tokenIndex = ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = ownedTokens[from].length.sub(1);
        uint256 lastToken = ownedTokens[from][lastTokenIndex];

        ownedTokens[from][tokenIndex] = lastToken;
        ownedTokens[from].pop();

        ownedTokensIndex[tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }
    
    function setBaseTokenURI(string memory uri) public onlyTrusted whenNotPaused {
        baseURI = uri;
    }
    
    function setLegacyBanList(address banList) public onlyTrusted whenNotPaused {
        legacyBanList = BanList(banList);
    }
    
    function setAddressBanList(address banList) public onlyTrusted whenNotPaused {
        addressBanList = AddressBanList(banList);
    }
    
    function setBanFlags(uint256[] memory tokenIds, uint256[] memory set, uint256[] memory unset) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bans[tokenIds[i]] = bans[tokenIds[i]] | set[i];
            bans[tokenIds[i]] = bans[tokenIds[i]] & ~unset[i];
            explicitBans[tokenIds[i]] = true;
        }
    }
    
    function getBanFlags(uint256 tokenId) public view returns (uint256) {
        return bans[tokenId];
    }
    
    function isBanned(address user1, address user2, uint256 tokenId) public view returns (bool) {
        if (address(addressBanList) != address(0)) {
            if (addressBanList.isBanned(user1)) return true;
            if (addressBanList.isBanned(user2)) return true;
        }
        if (explicitBans[tokenId] == false && address(legacyBanList) != address(0)) {
            if (legacyBanList.isBanned(tokenId)) return true;
        }
        return bans[tokenId] & 1 > 0 ? true : false;
    }
    
    // ERC721 methods
    
    // Gets file URI for a token
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // Verifies token existance
    function exists(uint256 tokenId) private view returns (bool) {
        return tokenOwner[tokenId] != address(0);
    }
    
    // Returns total supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns token by its index
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _totalSupply, "Index is out of range");
        return index + 1;
    }

    // Returns owner's token by its index
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return ownedTokens[owner][index];
    }

    // Returns owner's token by its index
    function tokenDetails(uint256 tokenId) public view returns (BinamonTokenV2 memory token, BinamonTypeV2 memory type_) {
        require(exists(tokenId), "Nonexistent token");
        return (tokens[tokenId], types[tokens[tokenId]._type]);
    }
    
    // Returns balance - ERC721
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return ownedTokensCount[owner];
    }

    // Returns owner of a token - ERC721
    function ownerOf(uint256 tokenId) public override view returns (address) {
        return tokenOwner[tokenId];
    }

    // Approves token - ERC721
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is neither owner nor approved for all");

        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Approval query - ERC721
    function getApproved(uint256 tokenId) public override view returns (address) {
        require(exists(tokenId), "Nonexistent token");

        return tokenApprovals[tokenId];
    }

    // Sets approval for all - ERC721
    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        require(operator != msg.sender, "Trying to approve the caller");

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Checks approval for all - ERC721
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    // Checks approval - ERC721
    function isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        require(exists(tokenId), "Nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Transfers token from another address - ERC721
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");
        transfer(from, to, tokenId);
    }

    // Safe transfer - ERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");
        transfer(from, to, tokenId);
    }

    // Safe transfer with data - ERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");
        transfer(from, to, tokenId);
    }

    // Transfers - ERC721
    function transfer(address from, address to, uint256 tokenId) private whenNotPaused {
        require(ownerOf(tokenId) == from, "Transfer of token that is not owned");
        require(to != address(0), "Transfer to the zero address");
        require(isBanned(from, to, tokenId) == false, "Card is banned");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        removeTokenFrom(from, tokenId);
        addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }
    
    
    // Binamon specific methods
    
    // Returns param names
    function paramNames() public view returns (string[] memory) {
        return _paramNames;
    }

    // Returns total types
    function totalTypes() public view returns (uint256) {
        return typeCount;
    }

    // Returns type by its index
    function typeByIndex(uint256 index) public view returns (BinamonTypeV2 memory) {
        require(index < typeCount, "Index is out of range");
        return types[index + 1];
    }
    
    // Adds a Binamon type (admin method)
    function addType(string memory hash, string memory name_, string memory extra, string memory info) public onlyTrusted whenNotPaused {
        typeCount += 1; // We want type IDs to start from 1
        
        types[typeCount]._hash = hash;
        types[typeCount]._name = name_;
        types[typeCount]._extra = extra;
        types[typeCount]._info = info;
    }
    
    // Edits a Binamon type (admin method)
    function editType(uint256 type_, string memory hash, string memory name_, string memory extra, string memory info) public onlyTrusted whenNotPaused {
        types[type_]._hash = hash;
        types[type_]._name = name_;
        types[type_]._extra = extra;
        types[type_]._info = info;
        
        if (typeCount < type_) typeCount = type_;
    }
    
    // Mints an NFT of custom characteristics
    function mint(uint256 type_, uint256[] memory values) public onlyTrusted whenNotPaused {
        require(type_ > 0 && type_ <= typeCount, "Trying to mint nonexistent type of token");
        require(values.length == _paramNames.length, "Incorrect number of params");
        
        _totalSupply += 1;
        uint256 tokenId = _totalSupply;
        addTokenTo(msg.sender, tokenId);
            
        tokens[tokenId]._type = type_;
        tokens[tokenId].paramValues = values;
        
        emit Transfer(address(0), msg.sender, tokenId);
    }
    
    // Edits an NFT
    function edit(uint256 tokenId, uint256 type_, uint256[] memory values) public onlyTrusted whenNotPaused {
        require(type_ > 0 && type_ <= typeCount, "Trying to change to nonexistent type of token");
        
        tokens[tokenId]._type = type_;
        tokens[tokenId].paramValues = values;
    }
    
    // Admin method for card ownership change
    function arrestToken(uint256 tokenId) public {
        require(msg.sender == arrestAddress);
        emit Transfer(ownerOf(tokenId), arrestAddress, tokenId);
        removeTokenFrom(ownerOf(tokenId), tokenId);
        addTokenTo(arrestAddress, tokenId);
    }
    
    function setArrestAddress(address newAddress) public onlyOwner {
        require(arrestAddress != address(0));
        arrestAddress = newAddress;
    }
    
    function setLegacyTypes(uint256[] memory types_, uint256[] memory legacyTypes) public onlyTrusted whenNotPaused {
        require(types_.length == legacyTypes.length);
        for (uint256 i = 0; i < types_.length; i++) {
            _legacyTypes[legacyTypes[i]] = types_[i];
        } 
    }
    
    function regenToken(uint256 tokenId) public virtual { }
    
    function regenTokens(uint256[] memory tokenIds) public whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            regenToken(tokenIds[i]);
        }
    }
    
    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}

contract CollectionTypeMover is Trustable {
    
    function copyLegacyTypes(address legacyAddress, address newAddress, uint256 start, uint256 end) public onlyTrusted {
        LegacyCollection legacyCollection = LegacyCollection(legacyAddress);
        BinamonCollectionV2 newCollection = BinamonCollectionV2(newAddress);
        uint256 nTypes = legacyCollection.totalTypes();
        uint256[] memory numbers = new uint256[](end - start + 1);
        for (uint256 i = start; i <= end && i <= nTypes; i++) {
            BinamonType memory type_ = legacyCollection.typeByIndex(i - 1);
            newCollection.editType(i, type_._hash, type_._name, type_._extra, type_._info);
            numbers[i - start] = i;
        }
        newCollection.setLegacyTypes(numbers, numbers);
    }
}

contract BinamonGenesis is BinamonCollectionV2 {
    
    mapping (string => uint256) private elements;
    
    constructor () {
        _name = 'Binamon NFT Collection';
        _symbol = 'BMONC';
        _paramNames = ["Class", "Attack", "Defence", "Element"];
        
        elements["Forest"] = 1;
        elements["Water"] = 2;
        elements["Fire"] = 3;
        elements["Light"] = 4;
        elements["Psiquic"] = 5;
        elements["Quantum"] = 6;
        elements["1"] = 1;
        elements["2"] = 2;
        elements["3"] = 3;
        elements["4"] = 4;
        elements["5"] = 5;
        elements["6"] = 6;
        
        //_legacyCollection = LegacyCollection(0x39F742ba717F6203e081fBC0418FA60F1e245Ea1);
        //_totalSupply = _legacyCollection.totalSupply();
    }
    
    function regenToken(uint256 tokenId) public override whenNotPaused {
        require(_legacyCollection.ownerOf(tokenId) == msg.sender, "Not your token");
        
        (BinamonToken memory token, BinamonType memory type_) = _legacyCollection.tokenDetails(tokenId);
        
        addTokenTo(msg.sender, tokenId);
            
        tokens[tokenId]._type = _legacyTypes[token._type];
        tokens[tokenId].paramValues = [type_._class, token._attack, token._hornpower, elements[token._element]];
        
        emit Transfer(address(0), msg.sender, tokenId);
    }
}

contract BinamonEnergy is BinamonCollectionV2 {
    
    mapping (string => uint256) private elements;
    
    constructor () {
        _name = 'Binamon Energy NFT Collection';
        _symbol = 'BMONEC';
        _paramNames = ["Class", "Element"];
        
        elements["Forest"] = 1;
        elements["Water"] = 2;
        elements["Fire"] = 3;
        elements["Light"] = 4;
        elements["Psiquic"] = 5;
        elements["Quantum"] = 6;
        elements["1"] = 1;
        elements["2"] = 2;
        elements["3"] = 3;
        elements["4"] = 4;
        elements["5"] = 5;
        elements["6"] = 6;
        
        _legacyCollection = LegacyCollection(0x425D23145F19bd5Ef64992bcd1e72c8eA8921C9C);
        _totalSupply = _legacyCollection.totalSupply();
    }
    
    function regenToken(uint256 tokenId) public override whenNotPaused {
        require(_legacyCollection.ownerOf(tokenId) == msg.sender, "Not your token");
        
        (BinamonToken memory token, BinamonType memory type_) = _legacyCollection.tokenDetails(tokenId);
        
        addTokenTo(msg.sender, tokenId);
            
        tokens[tokenId]._type = _legacyTypes[token._type];
        tokens[tokenId].paramValues = [type_._class, elements[token._element]];
        
        emit Transfer(address(0), msg.sender, tokenId);
    }
}

contract BinamonZ1 is BinamonCollectionV2 {
    
    mapping (string => uint256) private elements;
    
    constructor () {
        _name = 'Binamon Z1 Planet NFT Collection';
        _symbol = 'BMONC-Z1';
        _paramNames = ["Class", "Attack", "Defence", "Element"];
        
        elements["Forest"] = 1;
        elements["Water"] = 2;
        elements["Fire"] = 3;
        elements["Light"] = 4;
        elements["Psiquic"] = 5;
        elements["Quantum"] = 6;
        elements["1"] = 1;
        elements["2"] = 2;
        elements["3"] = 3;
        elements["4"] = 4;
        elements["5"] = 5;
        elements["6"] = 6;
        
        //_legacyCollection = LegacyCollection(0x9678A9b37738cc5c6cF1Df39CA9Fe4590EBe015c);
        //_totalSupply = _legacyCollection.totalSupply();
    }
    
    function regenToken(uint256 tokenId) public override whenNotPaused {
        require(_legacyCollection.ownerOf(tokenId) == msg.sender, "Not your token");
        
        (BinamonToken memory token, BinamonType memory type_) = _legacyCollection.tokenDetails(tokenId);
        
        addTokenTo(msg.sender, tokenId);
            
        tokens[tokenId]._type = _legacyTypes[token._type];
        tokens[tokenId].paramValues = [type_._class, token._attack, token._hornpower, elements[token._element]];
        
        emit Transfer(address(0), msg.sender, tokenId);
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}