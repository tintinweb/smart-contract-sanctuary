pragma solidity >=0.7.0 <0.9.0;

import "./BMON.sol";

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



// Type definitions
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

contract Binamon/* is IERC721*/ {
    
    // Contract owner
    address private _owner;
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    
    // ERC721 data

    // Mapping from token ID to owner address
    mapping (uint256 => address) private owners;
    
    // Trusted users list
    mapping (address => bool) private _isTrusted;
    
    // Mapping owner address to token count
    mapping (address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private operatorApprovals;
    
    
    // Binamon specific data
    
    // Frequency values
    uint256[11] private classFreqs;
    uint256[11] private attackFreqs;
    uint256[9] private hornpowerFreqs;
    uint256[5] private elementFreqs;
    
    // Elements
    string[6] private elements;
        
    // BMON Contract
    address payable private bmonAddress;
    BMON private bmonContract;
    
    // Current booster price
    uint256 private boosterPrice;
    
    // Token types and tokens
    uint256 private typeCount;
    uint256 private tokenCount;
    mapping (uint256 => BinamonType) private types;
    mapping (uint256 => uint256[]) private typesByClass;
    mapping (uint256 => BinamonToken) private tokens;
    
    
    // Events
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // Ownership check
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }
    
    // Trusted users check
    modifier isTrusted {
        require(_isTrusted[msg.sender] || msg.sender == _owner, "Caller is not trusted");
        _;
    }
    

    // Initializes the contract by setting a `name` and a `symbol` to the token collection.
    constructor () {
        _name = 'Binamon NFT Collection';
        _symbol = 'BMONC';
        _owner = msg.sender;
        bmonAddress = payable(address(0));
        boosterPrice = 1000000000000000000; // 1 BMON by default
        typeCount = 0;
        tokenCount = 0;
        
        classFreqs = [uint(10), uint(25), uint(50), uint(1000), uint(2000), uint(4000), uint(6000), uint(8000), uint(10000), uint(15000), uint(20000)]; // the rest remains for class 1
        attackFreqs = [uint(10), uint(25), uint(50), uint(100), uint(200), uint(400), uint(600), uint(800), uint(1000), uint(1500), uint(2000)]; // the rest remains for attack 1
        hornpowerFreqs = [uint(10), uint(20), uint(30), uint(50), uint(60), uint(80), uint(100), uint(150), uint(200)]; // the rest remains for hornpower 1
        elementFreqs = [uint(10), uint(40), uint(150), uint(200), uint(250)]; // the rest remains for element 1
        elements = ["Forest", "Water", "Fire", "Light", "Psiquic", "Quantum"];
        
        emit Transfer(address(0), msg.sender, 0); // Dummy event for BSCScan to recognize token
    }

    // Changes contract owner
    function changeOwner(address newOwner) public isOwner {
        _owner = newOwner;
        emit OwnerSet(_owner, newOwner);
    }

    // Returns contract owner
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    // Adds a trusted user
    function addTrusted(address user) public isOwner {
        _isTrusted[user] = true;
    }

    // Removes a trusted user    
    function removeTrusted(address user) public isOwner {
        _isTrusted[user] = false;
    }
    
    // Changes BMON contract address
    function changeBMONAddress(address newAddress) public isTrusted {
        bmonAddress = payable(newAddress);
        bmonContract = BMON(bmonAddress);
    }

    // Returns BMON contract address
    function getBMONAddress() public view returns (address) {
        return bmonAddress;
    }
    
    // Returns current ticket price
    function getBoosterPrice() public view returns (uint256) {
        return boosterPrice;
    }
    
    // Returns current ticket price
    function setBoosterPrice(uint256 newPrice) public isTrusted {
        boosterPrice = newPrice;
    }

    // Returns token name
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns token symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    // Mandatory and optional ERC721 methods
    
    // Gets file URI for a token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = "https://ipfs.io/ipfs/";
        return string(abi.encodePacked(baseURI, tokenId));
    }

    // Verifies token existance
    function exists(uint256 tokenId) private view returns (bool) {
        return owners[tokenId] != address(0);
    }
    
    // Returns total supply
    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }

    // Returns token by its index
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < tokenCount, "Index is out of range");
        return index + 1; // We just number them starting from 1
    }

    // Returns owner's token by its index
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "Index is out of range");
        
        uint256 current = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (owners[i+1] == owner) {
                if (current == index) return i+1;
                current += 1;
            }
        }
        
        return 0;
    }

    // Returns owner's token by its index
    function tokenDetails(uint256 tokenId) public view returns (BinamonToken memory token, BinamonType memory type_) {
        require(exists(tokenId), "Details query for nonexistent token");
        return (tokens[tokenId], types[tokens[tokenId]._type]);
    }
    
    // Returns balance - ERC721
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return balances[owner];
    }

    // Returns owner of a token - ERC721
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
        return owner;
    }

    // Approves token - ERC721
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is neither owner nor approved for all");

        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Approval query - ERC721
    function getApproved(uint256 tokenId) public view returns (address) {
        require(exists(tokenId), "Approved query for nonexistent token");

        return tokenApprovals[tokenId];
    }

    // Sets approval for all - ERC721
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Trying to approve the caller");

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Checks approval for all - ERC721
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    // Checks approval - ERC721
    function isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        require(exists(tokenId), "Operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Transfers token from another address - ERC721
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");

        transfer(from, to, tokenId);
    }

    // Safe transfer - ERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");
        transfer(from, to, tokenId);
    }

    // Safe transfer with data - ERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is neither owner nor approved");
        
        // In Binamon we don't use any data, just transfer token
        transfer(from, to, tokenId);
    }

    // Transfers - ERC721
    function transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from, "Transfer of token that is not owned");
        require(to != address(0), "Transfer to the zero address");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    
    // Binamon specific methods
    
    // Returns total types
    function totalTypes() public view returns (uint256) {
        return typeCount;
    }

    // Returns class name by its index
    function typeByIndex(uint256 index) public view returns (BinamonType memory) {
        require(index < typeCount, "Index is out of range");
        return types[index + 1];
    }
    
    // RNG, on-chain timestamp based
    function random(uint256 modulo, uint256 salt) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp - 47 * salt, block.difficulty, msg.sender))) % modulo;
    }
    
    // Selects random class
    function randomClass(uint256 salt) private view returns (uint256) {
        // Class frequencies
        uint256 number = random(100000, salt);
        
        uint256 border = 0;
        for (uint8 i = 0; i < 11; i++) {
            border += classFreqs[i];
            if (number < border) return 12 - i;
        }
        
        return 1;
    }
    
    // Selects random attack
    function randomAttack(uint256 salt) private view returns (uint256) {
        // Attack frequencies
        uint256 number = random(10000, salt);
        
        uint256 border = 0;
        for (uint8 i = 0; i < 11; i++) {
            border += attackFreqs[i];
            if (number < border) return 12 - i;
        }
        
        return 1;
    }
    
    // Selects random hornpower
    function randomHornpower(uint256 salt) private view returns (uint256) {
        // Hornpower frequencies
        uint256 number = random(1000, salt);
        
        uint256 border = 0;
        for (uint8 i = 0; i < 9; i++) {
            border += hornpowerFreqs[i];
            if (number < border) return 10 - i;
        }
        
        return 1;
    }
    
    // Selects random element
    function randomElement(uint256 salt) private view returns (uint256) {
        uint256 number = random(1000, salt);
        
        uint256 border = 0;
        for (uint8 i = 0; i < 5; i++) {
            border += elementFreqs[i];
            if (number < border) return 5 - i;
        }
        
        return 0;
    }
    
    // Selects random type of class
    function randomTypeOfClass(uint256 class, uint256 salt) private view returns (uint256) {
        require(typesByClass[class].length > 0, "No Binamons for choosen class");
        
        uint256 index = random(typesByClass[class].length, salt);
        return typesByClass[class][index];
    }
    
    // Adds a Binamon type (admin method)
    function addNewType(uint256 class, string memory hash, string memory name_, string memory extra, string memory info) public isTrusted {
        typeCount += 1; // We want type IDs to start from 1
        
        BinamonType memory type_;
        type_._class = class;
        type_._hash = hash;
        type_._name = name_;
        type_._extra = extra;
        type_._info = info;
        
        types[typeCount] = type_;
        typesByClass[class].push(typeCount);
    }
    
    // Buys and generates a boost
    function buyBooster() public {
        require(bmonContract.boosterBuyingAllowance(msg.sender), "User account is not approved for buying Binamons");
        require(bmonContract.balanceOf(msg.sender) >= boosterPrice, "Not enough BMON to buy a booster");
        
        if (bmonContract.transferFrom(msg.sender, _owner, boosterPrice) == true) {
            
            // We don't use loop here because EVM hates loops and randomly throws error - we just repeat code 3 times
            
            tokenCount += 1; // We don't want any valid tokenId to be zero
            uint256 tokenId = tokenCount;
            balances[msg.sender] += 1;
            owners[tokenId] = msg.sender;
                
            // Set random stats for the new token
            BinamonToken memory token;
            uint256 class = randomClass(1);
            token._type = randomTypeOfClass(class, 2);
            token._attack = randomAttack(3);
            token._hornpower = randomHornpower(4);
            token._element = elements[randomElement(5)];
    
            tokens[tokenId] = token;
            emit Transfer(address(0), msg.sender, tokenId);
            
            tokenCount += 1; // We don't want any valid tokenId to be zero
            uint256 tokenId2 = tokenCount;
            balances[msg.sender] += 1;
            owners[tokenId2] = msg.sender;
                
            // Set random stats for the new token
            BinamonToken memory token2;
            uint256 class2 = randomClass(6);
            token2._type = randomTypeOfClass(class2, 7);
            token2._attack = randomAttack(8);
            token2._hornpower = randomHornpower(9);
            token2._element = elements[randomElement(10)];
    
            tokens[tokenId2] = token2;
            emit Transfer(address(0), msg.sender, tokenId2);
            
            tokenCount += 1; // We don't want any valid tokenId to be zero
            uint256 tokenId3 = tokenCount;
            balances[msg.sender] += 1;
            owners[tokenId3] = msg.sender;
                
            // Set random stats for the new token
            BinamonToken memory token3;
            uint256 class3 = randomClass(11);
            token3._type = randomTypeOfClass(class3, 12);
            token3._attack = randomAttack(13);
            token3._hornpower = randomHornpower(14);
            token3._element = elements[randomElement(15)];
    
            tokens[tokenId3] = token3;
            emit Transfer(address(0), msg.sender, tokenId3);
        }
    }
    
    // Mints an NFT of custom characteristics
    function mint(uint256 type_, uint256 attack, uint256 hornpower, string memory element) public isTrusted {
        require(type_ > 0 && type_ <= typeCount, "Trying to mint nonexistent type of token");
        
        tokenCount += 1; // We don't want any valid tokenId to be zero
        uint256 tokenId = tokenCount;
        balances[msg.sender] += 1;
        owners[tokenId] = msg.sender;
            
        BinamonToken memory token;
        token._type = type_;
        token._attack = attack;
        token._hornpower = hornpower;
        token._element = element;
            
        tokens[tokenId] = token;
        emit Transfer(address(0), msg.sender, tokenId);
    }
    
    // ERC165 Interface discovery
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
    
}