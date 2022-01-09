/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721I {

    string public name; string public symbol;
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) { name = name_; symbol = symbol_; }

    uint256 public totalSupply; 
    mapping(uint256 => address) public ownerOf; 
    mapping(address => uint256) public balanceOf; 

    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll; 

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf[tokenId_] == address(0x0), "ERC721I: _mint() Token to Mint Already Exists!");

        // ERC721I Starts Here
        ownerOf[tokenId_] = to_;
        balanceOf[to_]++;
        totalSupply++; 
        // ERC721I Ends Here

        emit Transfer(address(0x0), to_, tokenId_);
        emit Mint(to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], "ERC721I: _transfer() Transfer Not Owner of Token!");
        require(to_ != address(0x0), "ERC721I: _transfer() Transfer to Zero Address!");

        // ERC721I Starts Here
        // checks if there is an approved address clears it if there is
        if (getApproved[tokenId_] != address(0x0)) { 
            _approve(address(0x0), tokenId_); 
        } 

        ownerOf[tokenId_] = to_; 
        balanceOf[from_]--;
        balanceOf[to_]++;
        // ERC721I Ends Here

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC721I: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner || spender_ == getApproved[tokenId_] || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner, "ERC721I: approve() Cannot approve yourself!");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "ERC721I: Caller not owner or Approved!");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721I: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, "ERC721I: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
    // // public view functions
    // never use these for functions ever, they are expensive af and for view only (this will be an issue in the future for interfaces)
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) { _loopThrough++; }
            if (ownerOf[i] == address_) { _tokens[_index] = i; _index++; }
        }
        return _tokens;
    }
}

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

contract VoxxtPrimal is ERC721I, Ownable {
    constructor() payable ERC721I("Voxxt Primal","VP") {}
    
    // Project Settings
    uint256 public mintPrice = 0.08 ether;
    uint256 public maxTokens = 10000;
    
    // Whitelist Stuff
    uint256 public whitelistAmount = 1200; // 1200 (1000 + 200) >> (1200 - 276) = 924
    uint256 public mintsPerWhitelist = 4; // 4 mints per whitelist
    mapping(address => uint256) public addressToWhitelistMinted;
    mapping(address => bool) public isWhitelisted;

    bool public whitelistMintEnabled = false; // default false
    uint256 public whitelistMintStartTime = 1641726000; // Sun Jan 09 2022 11:00:00 GMT+0000

    // Public Mint Stuff
    uint256 public maxMintsPerTx = 10; // 10 mints per tx

    bool public publicMintEnabled = false; // default false
    uint256 public publicMintStartTime; // default unset

    // Modifiers
    modifier onlySender {
        require(msg.sender == tx.origin, 
            "No smart contracts!");
        _;
    }
    modifier whitelistMinting {
        require(whitelistMintEnabled && block.timestamp >= whitelistMintStartTime,
            "Whitelist Mints are not enabled yet!");
        _;
    }
    modifier publicMinting {
        require(publicMintEnabled && block.timestamp >= publicMintStartTime,
            "Public Mints are not enabled yet!");
        _;
    }

    // Owner Administration
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }
    function setMaxTokens(uint256 maxTokens_) external onlyOwner {
        require(maxTokens_ >= totalSupply, 
            "maxTokens cannot be set lower than totalSupply!");

        maxTokens = maxTokens_;
    }
    function setWhitelistAmount(uint256 whitelistAmount_) external onlyOwner {
        whitelistAmount = whitelistAmount_;
    }
    function setMintsPerWhitelist(uint256 mintsPerWhitelist_) external onlyOwner {
        mintsPerWhitelist = mintsPerWhitelist_;
    }
    function setMaxMintsPerTx(uint256 maxMintsPerTx_) external onlyOwner {
        maxMintsPerTx = maxMintsPerTx_;
    }
    function setWhitelists(address[] calldata addresses_, bool bool_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            isWhitelisted[addresses_[i]] = bool_;
        }
    }
    function setWhitelistParams(bool whitelistMintEnabled_, uint256 whitelistMintStartTime_) external onlyOwner {
        whitelistMintEnabled = whitelistMintEnabled_;
        whitelistMintStartTime = whitelistMintStartTime_;
    }
    function setPublicMintParams(bool publicMintEnabled_, uint256 publicMintStartTime_) external onlyOwner {
        publicMintEnabled = publicMintEnabled_;
        publicMintStartTime = publicMintStartTime_;
    }
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string memory ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Internal Mint 
    function _mintMany(address to_, uint256 amount_) internal {
        require(maxTokens >= totalSupply + amount_,
            "Not enough tokens remaining!");

        uint256 _startId = totalSupply + 1; // iterate from 1
        
        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
        }
    }

    // Owner Mint Functions
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        _mintMany(to_, amount_);
    }
    function ownerMintToMany(address[] calldata tos_, uint256[] calldata amounts_) external onlyOwner {
        require(tos_.length == amounts_.length, 
            "Array lengths mismatch!");
            
        for (uint256 i = 0; i < tos_.length; i++) {
            _mintMany(tos_[i], amounts_[i]);
        }
    }

    // Whitelist Mint Functions
    function whitelistMint(uint256 amount_) external payable onlySender whitelistMinting {
        require(isWhitelisted[msg.sender], 
            "You are not whitelisted!");
        require(mintsPerWhitelist >= amount_,
            "Amount exceeds max mints per whitelist!");
        require(mintsPerWhitelist >= addressToWhitelistMinted[msg.sender] + amount_,
            "You don't have enough whitelist mints remaining!");
        require(msg.value == amount_ * mintPrice, 
            "Invalid amount sent!");
        require(whitelistAmount >= totalSupply + amount_,
            "Not enough whitelist mints remaining!");
        
        addressToWhitelistMinted[msg.sender] += amount_;

        _mintMany(msg.sender, amount_);
    }

    // Public Mint Functions
    function publicMint(uint256 amount_) external payable onlySender publicMinting {
        require(maxMintsPerTx >= amount_, 
            "Amount exceeds max mints per tx!");
        require(msg.value == amount_ * mintPrice, 
            "Invalid amount sent!");
        require(maxTokens >= totalSupply + amount_,
            "Not enough tokens remaining!");
        
        _mintMany(msg.sender, amount_);
    }

    // Withdraw Funds
    function _sendETH(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }
    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 _toShare1 = (_balance * 5) / 100;
        uint256 _toShare2 = _balance - _toShare1;

        _sendETH( payable(0x2D3C70A7b4d9C8Cba7D6f78F8B707256eE40A3c0), _toShare1);
        _sendETH( payable(msg.sender), _toShare2);
    }

    // Emergency Withdraw (if all fails!)
    mapping(address => bool) public shareSigned;
    function signShare() external {
        require(msg.sender == owner 
            || msg.sender == 0x2D3C70A7b4d9C8Cba7D6f78F8B707256eE40A3c0,
            "You cannot sign!");
        
        shareSigned[msg.sender] = true;
    }
    function emergencyWithdraw() external onlyOwner {
        require(shareSigned[msg.sender] 
            && shareSigned[0x2D3C70A7b4d9C8Cba7D6f78F8B707256eE40A3c0],
            "Both parties have not agreed to unlock this function!"); // both parties must sign

        _sendETH( payable(msg.sender), address(this).balance); // send contract eth to msg.sender
    }
}