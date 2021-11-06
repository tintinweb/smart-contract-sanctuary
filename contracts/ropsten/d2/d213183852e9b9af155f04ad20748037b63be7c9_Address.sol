/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IDivineAnarchyToken is IERC721, IERC721Metadata {

    function getTokenClass(uint256 _id) external view returns(uint256);
    function getTokenClassSupplyCap(uint256 _classId) external view returns(uint256);
    function getTokenClassCurrentSupply(uint256 _classId) external view returns(uint256);
    function getTokenClassVotingPower(uint256 _classId) external view returns(uint256);
    function getTokensMintedAtPresale(address account) external view returns(uint256);
    function isTokenClass(uint256 _id) external pure returns(bool);
    function isTokenClassMintable(uint256 _id) external pure returns(bool);
    function isAscensionApple(uint256 _id) external pure returns(bool);
    function isBadApple(uint256 _id) external pure returns(bool);
    function consumedAscensionApples(address account) external view returns(uint256);
    function airdropApples(uint256 amount, uint256 appleClass, address[] memory accounts) external;
}


interface IERC721Enumerable is IERC721 {
  
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {
  
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Pausable is Context {
    
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

   
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library MerkleProof {
    
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

interface IOracle {

    function getRandomNumbers() external returns(uint256[][] memory);
    function wait() external pure returns(bool);
}

interface IAdminWallets {

    function getOwnerWallet() external pure returns(address);
    function getDiversityWallet() external pure returns(address);
    function getAssetBenderWallet() external pure returns(address);
    function getMarketingWallet() external pure returns(address);
    function getDivineTreasuryWallet() external pure returns(address);
}
contract DivineAnarchyToken is IDivineAnarchyToken, ERC165, Ownable, Pausable, ReentrancyGuard {

    using Address for address;
    using Strings for string;

    // Contract variables.
    IAdminWallets public adminWallets;
    IOracle public oracle;

    string private _baseURI;
    string private _name;
    string private _symbol;

    uint256 public constant THE_UNKNOWN = 0;
    uint256 public constant KING = 1;
    uint256 public constant ADAM_EVE = 2;
    uint256 public constant HUMAN_HERO = 3;
    uint256 public constant HUMAN_NEMESIS = 4; 
    uint256 public constant ASCENSION_APPLE = 5;
    uint256 public constant BAD_APPLE = 6;

    mapping(uint256 => uint256) private _tokenClass;
    mapping(uint256 => uint256) private _tokenClassSupplyCap;
    mapping(uint256 => uint256) private _tokenClassSupplyCurrent;
    mapping(uint256 => uint256) private _tokenClassVotingPower;

    uint256 private _mintedToTreasury;
    uint256 public  MAX_MINTED_TO_TREASURY = 270; 
    bool private _mintedToTreasuryHasFinished = false;

    uint256 private constant MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE = 3;
    mapping(address => uint256) private _tokensMintedByAddressAtPresale;

    uint256 public MAX_TOKENS_MINTED_BY_ADDRESS = 4;
    mapping(address => uint256) private _tokensMintedByAddress;

    uint256 private _initAscensionApple = 10011;
    uint256 private _initBadApple = 13011;
    mapping(address => uint256) private _consumedAscensionApples;

    uint256 public  TOKEN_UNIT_PRICE = 0.09 ether;
    
    bytes32 public root = 0x71eb2b2e3c82409bb024f8b681245d3eea25dcfd0dc7bbe701ee18cf1e8ecbb1;
    bool isPresaleActive = true;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;
    
    bool public toRescue;
    bool public oracleForced;
    
    event oracleRescued(uint256[][] _tokens, uint256 timestamp, address receiver);
    event val(uint256[][] _tokens);

    // Contract constructor
    constructor (string memory name_, string memory symbol_, string memory baseURI_, address _adminwallets, address _oracle) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;

        adminWallets = IAdminWallets(_adminwallets);
        oracle = IOracle(_oracle);

        _tokenClassSupplyCap[THE_UNKNOWN] = 1;
        _tokenClassSupplyCap[KING] = 8;
        _tokenClassSupplyCap[ADAM_EVE] = 2;
        _tokenClassSupplyCap[HUMAN_HERO] = 5000;
        _tokenClassSupplyCap[HUMAN_NEMESIS] = 5000; 
        _tokenClassSupplyCap[ASCENSION_APPLE] = 3000;
        _tokenClassSupplyCap[BAD_APPLE] = 1500;

        _tokenClassVotingPower[KING] = 2000;
        _tokenClassVotingPower[ADAM_EVE] = 1000;
        _tokenClassVotingPower[HUMAN_HERO] = 1;
        _tokenClassVotingPower[HUMAN_NEMESIS] = 1;
        
        _beforeTokenTransfer(address(0), adminWallets.getDivineTreasuryWallet(), 0);
        _balances[adminWallets.getDivineTreasuryWallet()] += 1;
        _owners[0] = adminWallets.getDivineTreasuryWallet();
        _tokenClass[0] = THE_UNKNOWN;
        _tokenClassSupplyCurrent[THE_UNKNOWN] = 1;
        
        _beforeTokenTransfer(address(0), adminWallets.getDiversityWallet(), 1);
        _beforeTokenTransfer(address(0), adminWallets.getAssetBenderWallet(), 2);
        _beforeTokenTransfer(address(0), adminWallets.getMarketingWallet(), 3);

        // Minting three kings for Diversity, AssetBender and Marketing.
        _balances[adminWallets.getDiversityWallet()] += 1;
        _balances[adminWallets.getAssetBenderWallet()] += 1;
        _balances[adminWallets.getMarketingWallet()] += 1;

        _owners[1] = adminWallets.getDiversityWallet();
        _owners[2] = adminWallets.getAssetBenderWallet();
        _owners[3] = adminWallets.getMarketingWallet();
        _owners[4] = adminWallets.getMarketingWallet();

        for(uint256 i = 1; i <= 5; i++) {
            _tokenClass[i] = KING;
        }
 
        _tokenClassSupplyCurrent[KING] = 3;
    }


    // Contract functions.
    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function getAdminWalletsAddress() public view returns(address) {
        return address(adminWallets);
    }

    function getOracleAddress() public view returns(address) {
        return address(oracle);
    }

    function getTokenClass(uint256 _id) external view override returns(uint256) {
        return _tokenClass[_id];
    }

    function setTokenClass(uint _id) public pure returns(uint256) {
        // This can be erased if not necessary.
        if (_id == 0) { 
            return THE_UNKNOWN;
        } else if (_id >= 1 && _id <= 8) {
            return KING;
        } else if (_id == 9 && _id == 10) {
            return ADAM_EVE;
        } else if (_id >= 11 && _id <= 5010) {
            return HUMAN_HERO;
        } else if (_id >= 5011 && _id <= 10010) {
            return HUMAN_NEMESIS;
        } else if (_id >= 10011 && _id <= 13010) {
            return ASCENSION_APPLE;
        } else if (_id >= 13011 && _id <= 14510) {
            return BAD_APPLE;
        } else {
            revert('This ID does not belong to a valid token class');
        }
    }

    function getTokenClassSupplyCap(uint256 _classId) external view override returns(uint256) {
        return _tokenClassSupplyCap[_classId];
    }

    function getTokenClassCurrentSupply(uint256 _classId) external view override returns(uint256) {
        return _tokenClassSupplyCurrent[_classId];
    }

    function getTokenClassVotingPower(uint256 _classId) external view override returns(uint256) {
        return _tokenClassVotingPower[_classId];
    }

    function getTokensMintedAtPresale(address account) external view override returns(uint256) {
        return _tokensMintedByAddressAtPresale[account];
    }

    function isTokenClass(uint256 _id) public pure override returns(bool) {
        return (_id >= 0 && _id <= 14510);
    }

    function isTokenClassMintable(uint256 _id) public pure override returns(bool) {
        return (_id >= 0 && _id <= 10010);
    }

    function isAscensionApple(uint256 _id) public pure override returns(bool) {
        return (_id >= 10011 && _id <= 13010);
    }

    function isBadApple(uint256 _id) public pure override returns(bool) {
        return (_id >= 13011 && _id <= 14510);
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function ownerOf(uint256 _id) public view returns(address) {
        return _owners[_id];
    }

    function consumedAscensionApples(address account) public view override returns(uint256) {
        return _consumedAscensionApples[account];
    }

    // Functions to comply with ERC721.
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address operator) {
        require(exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(_msgSender() != operator, "Error: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function getMintedToTreasuryFinished() public view returns(bool) {
        return _mintedToTreasuryHasFinished;
    }
    
    // Minting & airdropping.
    function airdropToTreasury(uint256[][] memory treasuryRandom) external onlyOwner {
        address divineTreasuryWallet = adminWallets.getDivineTreasuryWallet();
        require(!paused(), "Error: token transfer while paused");
        uint256[] memory tokenIds = treasuryRandom[0];
        uint256[] memory classIds = treasuryRandom[1];
        require(classIds.length == tokenIds.length);
        uint256 amount = tokenIds.length;
        require(_mintedToTreasury + amount <= MAX_MINTED_TO_TREASURY, 'Error: you are exceeding the max airdrop amount to Treasury');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _beforeTokenTransfer(address(0), divineTreasuryWallet, tokenIds[i]);
            _balances[divineTreasuryWallet] += 1;
            _owners[tokenIds[i]] = divineTreasuryWallet;
            _tokenClass[tokenIds[i]] = classIds[i];
            _tokenClassSupplyCurrent[classIds[i]] += 1;
            emit Transfer(address(0), divineTreasuryWallet, tokenIds[i]);
        }

        _mintedToTreasury += amount;

        if(_mintedToTreasury == MAX_MINTED_TO_TREASURY) {
            _mintedToTreasuryHasFinished = true;
        }
    }    

    function mint(address account, uint256 amount, bytes32[] memory proof) external nonReentrant payable {
        // Pre minting checks.
        address operator = _msgSender();

        require(msg.value >= TOKEN_UNIT_PRICE * amount, 'Make sure you can afford 0.09 eth per token');
        require(account != address(0), "Error: mint to the zero address");
        require(!paused(), "Error: token transfer while paused");
        require(_mintedToTreasuryHasFinished == true, 'Error: Wait until airdropping to Treasury has finished');
        if (isPresaleActive == true) {
            require(_tokensMintedByAddressAtPresale[operator] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE, 'Error: you cannot mint more tokens at presale');
            require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(operator))), "you are not allowed to mint during presale");
        } else {
            require(_tokensMintedByAddress[operator] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: you cannot mint more tokens');
        }

        uint256[][] memory randomList = getRand(amount);
        uint256[] memory tokensIds = randomList[0];
        uint256[] memory classIds = randomList[1];

        for (uint256 i = 0; i < amount; i++) {
            _beforeTokenTransfer(address(0), account, tokensIds[i]);

            _owners[tokensIds[i]] = account;
            _balances[account] += 1;
            _tokenClass[tokensIds[i]] = classIds[i];
            _tokenClassSupplyCurrent[classIds[i]] += 1;

            emit Transfer(address(0), account, tokensIds[i]);
        }

        // Post minting.
        if (isPresaleActive == true) {
            _tokensMintedByAddressAtPresale[operator] += amount;
        } else {
            _tokensMintedByAddress[operator] += amount;
        }
    }

    function transferFrom(address from, address to, uint256 id) public {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public  {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);
        // Post transfer: check IERC721Receiver.
        require(_checkOnERC721Received(from, to, id, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public  {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);

        // Post transfer: check IERC721Receiver with data input.
        require(_checkOnERC721Received(from, to, id, data), "ERC721: transfer to non ERC721Receiver implementer");

    }

    function _transfer(address from, address to, address operator, uint256 id) internal virtual {
        require(_owners[id] == from);
        require(from == operator || getApproved(id) == operator || isApprovedForAll(from, operator), "Error: caller is neither owner nor approved");
        _beforeTokenTransfer(from, to, id);

        // Transfer.
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[id] = to;

        emit Transfer(from, to, id);
        _tokenApprovals[id] = address(0);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids) public {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        if (from != operator && isApprovedForAll(from, operator) == false) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(getApproved(ids[i]) == operator, 'Error: caller is neither owner nor approved');
            }
        }

        // Transfer.
        for (uint256 i = 0; i < ids.length; i++) {
            require(_owners[ids[i]] == from);
            _beforeTokenTransfer(from, to, ids[i]);
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[ids[i]] = to;

            emit Transfer(from, to, ids[i]);
            _tokenApprovals[ids[i]] = address(0);

            require(_checkOnERC721Received(from, to, ids[i], ""), "ERC721: transfer to non ERC721Receiver implementer");
        }
    }
    
    function burn(address account, uint256 id) public {
        // Pre burning checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        require(account == operator || getApproved(id) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");
        require(account != address(0), "Error: burn from the zero address");
        require(_owners[id] == account, 'Error: account is not owner of token id');
         _beforeTokenTransfer(account, address(0), id);

        // Burn process.
        _owners[id] = address(0);
        _balances[account] -= 1;

        emit Transfer(account, address(0), id);

        // Post burning.
        _tokenApprovals[id] = address(0);
    }

    function burnBatch(address account, uint256[] memory ids) public {
        // Pre burning checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        if (account != operator && isApprovedForAll(account, operator) == false) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(getApproved(ids[i]) == operator, 'Error: caller is neither owner nor approved');
            }
        } 

        for (uint256 i = 0; i < ids.length; i++) {
            require(_owners[ids[i]] == account, 'Error: account is not owner of token id');
        }

        // Burn process.
        for (uint256 i = 0; i < ids.length; i++) {
            _beforeTokenTransfer(account, address(0), ids[i]);
            _owners[ids[i]] = address(0);
            _balances[account] -= 1;
            emit Transfer(account, address(0), ids[i]);
        }

        // Post burning.
        for (uint256 i=0; i < ids.length; i++) {
            _tokenApprovals[ids[i]] = address(0);
        }
    }

    function airdropApples(uint256 amount, uint256 appleClass, address[] memory accounts) external override onlyOwner {        
        require(accounts.length == amount, "amount not egal to list length");
        require(appleClass == ASCENSION_APPLE || appleClass == BAD_APPLE, 'Error: The token class is not an apple');
        require(_tokenClassSupplyCurrent[appleClass] + amount <= _tokenClassSupplyCap[appleClass], 'Error: You exceed the supply cap for this apple class');

        uint256 appleIdSetter;

        if (appleClass == ASCENSION_APPLE) {
            appleIdSetter = _initAscensionApple + _tokenClassSupplyCurrent[ASCENSION_APPLE];
        } else {
            appleIdSetter = _initBadApple + _tokenClassSupplyCurrent[BAD_APPLE];
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 appleId = appleIdSetter + i;
            _beforeTokenTransfer(address(0), accounts[i], appleId);
            _owners[appleId] = accounts[i];
            _balances[accounts[i]] += 1;
            _tokenClass[appleId] = appleClass;
        } 

        _tokenClassSupplyCurrent[appleClass] += amount;
    }

    function ascensionAppleConsume(address account, uint256 appleId) external {
        address operator = _msgSender();

        require(isAscensionApple(appleId), 'Error: token provided is not ascension apple');
        require(_owners[appleId] == operator || getApproved(appleId) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");
        burn(account, appleId);
        _consumedAscensionApples[account] += 1;
    }

    function badAppleConsume(address account, uint256 appleId, uint256 tokenId) external {
        address operator = _msgSender();

        require(isBadApple(appleId), 'Error: token provided is not bad apple');
        require(isTokenClassMintable(tokenId), "Error: token provided is an apple");

        require(_owners[appleId] == operator || getApproved(appleId) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");

        burn(account, appleId);
        burn(account, tokenId);

        // Rewarding with 1 ascension apple.
        require(_tokenClassSupplyCurrent[ASCENSION_APPLE] + 1 <= _tokenClassSupplyCap[ASCENSION_APPLE], 'Error: You exceed the supply cap for this apple class');

        uint256 ascensionAppleId = _initAscensionApple + _tokenClassSupplyCurrent[ASCENSION_APPLE];
            
        _beforeTokenTransfer(address(0), account, ascensionAppleId);
        _owners[ascensionAppleId] = account;
        _balances[account] += 1;
        _tokenClassSupplyCurrent[ASCENSION_APPLE] += 1;
    }

    // Auxiliary functions.
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual  returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual  returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual  returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    
       function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal   {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }
    
    function getData(address _account)external view returns(uint256[][] memory){
        uint256[][] memory data = new uint256[][](2);
        uint256[] memory arrayOfTokens = walletOfOwner(_account);
        uint256[] memory othersData = new uint256[](2);
        othersData[0] = totalSupply();
        othersData[1] = TOKEN_UNIT_PRICE;
        data[0] = arrayOfTokens;
        data[1] = othersData;
        return data;
    }
    
    function withdrawAll() external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is 0.");
        (bool success,) = payable(msg.sender).call{value: balance}(new bytes(0));
        if(!success)revert("withdraw: transfer error");    
        
    }

    function withdraw(uint256 _amount) external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is 0.");
        require(balance > _amount, "balance must be superior to amount");
        (bool success,) = payable(msg.sender).call{value: _amount}(new bytes(0));
        if(!success)revert("withdraw: transfer error");
    }
    
    function setPresale(bool _bool) external onlyOwner{
        isPresaleActive = _bool;
    }
    
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
    
    function setMaxMintedTreasury(uint256 _amount) external onlyOwner {
        MAX_MINTED_TO_TREASURY = _amount;
                if(_mintedToTreasury == MAX_MINTED_TO_TREASURY) {
            _mintedToTreasuryHasFinished = true;
        }
    }
    function setOracle(address _oracle) external onlyOwner{
        oracle = IOracle(_oracle);
    }
    
    function setAdminWallet(address _adminwallets) external onlyOwner {
        adminWallets = IAdminWallets(_adminwallets);
    }
    
    function oracleRescue(uint256 _amount) public view returns(uint256[][]memory) {
        uint256[][] memory array = new uint256[][](2);
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256[] memory classIds = new uint256[](_amount);
        uint256 initRand = 0;
        uint256 each = 0;
        bytes32 bHash = blockhash(block.number - 1);

        while(initRand != _amount){
            uint256 randomNumber = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp, 
                            bHash, 
                            _msgSender(), 
                            each
                        )
                    )
                ) % 10011
            );
            bool inArray;
            for(uint256 i = 0; i<initRand; i++){
                if(randomNumber == tokenIds[i]){
                    inArray = true;
                }
            }
            if(!exists(randomNumber) && !inArray){
                tokenIds[initRand] = randomNumber;
                classIds[initRand] = setTokenClass(randomNumber);
                initRand += 1;
            }
            each += 1;
        }
        array[0] = tokenIds;
        array[1] = classIds;
    return array;
       
    }
    
    function setRescue(bool _value) external onlyOwner {
        toRescue = _value;
    }
    
    function forceOracle(bool _value) external onlyOwner {
        oracleForced = _value;
    }
    
    function getRand(uint256 _amount) internal returns(uint256[][] memory ){
        if(!toRescue && !oracleForced){
            try oracle.getRandomNumbers() returns(uint256[][] memory array){
                return (array);
            } catch {
                uint256[][] memory arr = oracleRescue(_amount);
                emit oracleRescued(arr, block.timestamp, msg.sender);
                return arr;
            }
        } else if(!toRescue && oracleForced){
            return oracle.getRandomNumbers();
        } else {
            uint256[][] memory arr = oracleRescue(_amount);
            emit oracleRescued(arr, block.timestamp, msg.sender);
            return arr;        
        }
    }
    
    function setMaxTokenMintedByAddress(uint256 _amount) external onlyOwner{
        MAX_TOKENS_MINTED_BY_ADDRESS = _amount;
    }
    
    function setNewTokenPrice(uint256 _newPrice) external onlyOwner{
        TOKEN_UNIT_PRICE = _newPrice;
    }
    
    function getPresaleState()external view returns(bool){
        return isPresaleActive;
    }
    
  
}