/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

contract SupportsInterface is ERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;
    
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true;     // ERC165
    }
    
    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}


contract HodlBag is ERC721, ERC721Metadata, SupportsInterface {
    uint32 constant BASEPRICE = 1000000;            // 0.01 ETH, 8 decimals
    uint32 constant INCREMENT = 30;                 // 3%
    uint32 constant DECREMENT = 20;                 // 2%
    uint8  constant DESIGNS   = 4;                  // Number of designs (BTC, ETH, DOGE, ???)
    
    string internal nftName;
    string internal nftSymbol;
    uint256 internal tokenCount;
    
    uint64[4] public nftPrices;                     // Price array for each design
    address public admin;
    
    // Mapping from NFT ID to metadata uri.
    mapping (uint256 => string) internal idToUri;
    
    // Mapping from NFT ID to the address that owns it.
    mapping (uint256 => address) internal idToOwner;
    
    // Mapping from NFT ID to approved address.
    mapping (uint256 => address) internal idToApproval;
    
    // Mapping from owner address to count of his tokens.
    mapping (address => uint256) private ownerToNFTokenCount;
    
    // Mapping from owner address to mapping of operator addresses.
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    
    // Mapping from NFT ID to redeemed state.
    mapping (uint256 => bool) public idToRedeemed;
    
    
    // Guarantees that the msg.sender is an owner or operator of the given NFT.
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], 'NOT_OWNER_OR_OPERATOR');
        _;
    }
    
    // Guarantees that the msg.sender is allowed to transfer NFT.
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[tokenOwner][msg.sender], 'NOT_OWNER_APPROVED_OR_OPERATOR');
        _;
    }
    
    // Guarantees that _tokenId is a valid Token.
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), 'NOT_VALID_NFT');
        _;
    }
    
    constructor() {
        nftName = "HODLbag NFT";
        nftSymbol = "HDLN";
        
        admin = msg.sender;
        initPrices();
    
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    }
    
    function initPrices() private {
        for (uint i = 0; i < DESIGNS; i++) {
            nftPrices[i] = BASEPRICE;
        }
    }
    
    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), 'ZERO_ADDRESS');
        return ownerToNFTokenCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external override view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), 'NOT_VALID_NFT');
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, 'NOT_OWNER');
        require(_to != address(0), 'ZERO_ADDRESS');

        _transfer(_to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, 'IS_OWNER');
    
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
        
    }
    
    function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }
    
    function totalSupply() external view returns (uint256 _totalsupply) {
        _totalsupply = tokenCount;
    }
    
    function name() external override view returns (string memory _name) {
        _name = nftName;
    }
    
    function symbol() external override view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
    
    // A distinct URI (RFC 3986) for a given NFT.
    function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory) {
        return idToUri[_tokenId];
    }
    
    function _setTokenUri(uint256 _tokenId, string memory _uri) internal validNFToken(_tokenId) {
        idToUri[_tokenId] = _uri;
    }
    
    function isContract(address _addr) internal view returns (bool addressCheck) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_addr) } // solhint-disable-line
        addressCheck = (codehash != 0x0 && codehash != accountHash);
    }
    
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        
        // Clear approval
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
        
        // Transfer
        require(idToOwner[_tokenId] == from, 'NOT_OWNER');
        
        ownerToNFTokenCount[from]--;
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to]++;
        
        emit Transfer(from, _to, _tokenId);
    }
    
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, 'NOT_OWNER');
        require(_to != address(0), 'ZERO_ADDRESS');

        _transfer(_to, _tokenId);
        
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == 0x150b7a02, 'NOT_ABLE_TO_RECEIVE_NFT');
        }
    }
    
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), 'ZERO_ADDRESS');
        require(idToOwner[_tokenId] == address(0), 'NFT_ALREADY_EXISTS');
        
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to]++;
        
        emit Transfer(address(0), _to, _tokenId);
    }
    
    function _setPrices(uint8 _designId) private {
        for (uint i = 0; i < DESIGNS; i++) {
            if (i == _designId) {
                // Increase the price for the minted design
                nftPrices[i] = nftPrices[i] * (1000 + INCREMENT) / 1000;
            }
            else {
                // Decrease the price for every other designs
                uint256 decrement = nftPrices[i] * DECREMENT / 1000 / (DESIGNS - 1);
                nftPrices[i] -= uint32(decrement);
            }
        }
    }
    
    function getPrice(uint8 _designId) public view returns (uint256) {
        require(_designId < DESIGNS, 'DESIGN_NOT_FOUND');
        
        return (uint256(nftPrices[_designId]) * 10 ** 10);
    }
    
    function mint(address _to, uint8 _designId, string calldata _uri) external payable {
        require(_designId < DESIGNS, 'DESIGN_NOT_FOUND');
        require(msg.value == getPrice(_designId), 'WRONG_AMOUNT');
        
        uint256 _tokenId = tokenCount;
        tokenCount++;
        
        _setPrices(_designId);
        _mint(_to, _tokenId);
        _setTokenUri(_tokenId, _uri);
    }
    
    function adminWithdraw(address payable _address, uint256 _amount) external{
        require(msg.sender == admin, 'NOT_ADMIN');
        
        _address.transfer(_amount);
    }
    
    function redeem(uint256 _tokenId) canOperate(_tokenId) external {
        require(!idToRedeemed[_tokenId], 'ALREADY_REDEEMED');
        
        idToRedeemed[_tokenId] = true;
    }
    
    fallback() external payable {}
    receive() external payable {}
}