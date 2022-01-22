/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ERC721I - ERC721I (ERC721 0xInuarashi Edition) - Gas Optimized
    Author: 0xInuarashi || https://twitter.com/0xinuarashi 
    Open Source: with the efforts of the [0x Collective] <3 */

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
        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        // totalSupply++; // I removed this for a bit better gas management on multi-mints ~ 0xInuarashi
        
        // ERC721I Ends Here

        emit Transfer(address(0x0), to_, tokenId_);
        
        // emit Mint(to_, tokenId_); // I removed this for a bit better gas management on multi-mints ~ 0xInuarashi
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
    function _isApprovedOrOwner(address sender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (sender_ == _owner || sender_ == getApproved[tokenId_] || isApprovedForAll[_owner][sender_]);
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

    // so not sure when this will ever be really needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
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

abstract contract Security {
    // Prevent Smart Contracts
    modifier onlySender {
        require(msg.sender == tx.origin, "No Smart Contracts!"); _; }
}

abstract contract PublicMint {
    // Public Minting
    bool public _publicMintEnabled; uint256 public _publicMintTime;
    function _setPublicMint(bool bool_, uint256 time_) internal {
        _publicMintEnabled = bool_; _publicMintTime = time_; }
    modifier publicMintEnabled { 
        require(_publicMintEnabled && _publicMintTime <= block.timestamp, 
            "Public Mint is not enabled yet!"); _; }
    function publicMintStatus() external view returns (bool) {
        return _publicMintEnabled && _publicMintTime <= block.timestamp; }
}

abstract contract WhitelistMint {
    // Whitelist Minting
    mapping(address => bool) private _allowList;
    bool internal _whitelistMintEnabled; 
    uint256 public _whitelistMintTime;
    function _setWhitelistMint(bool bool_, uint256 time_) internal {
        _whitelistMintEnabled = bool_; _whitelistMintTime = time_; }
    function _addWhitelistAddress(address address_) internal {
        _allowList[address_] = true; }
    function _removeWhitelistAddress(address address_) internal {
        _allowList[address_] = false; }
    modifier whitelistMintEnabled {
        require(_whitelistMintEnabled && _whitelistMintTime <= block.timestamp, 
            "Whitelist Mint is not enabled yet!"); _; } 
    modifier isWhitelisted {
        require(_allowList[msg.sender], 
            "You are not whitelisted!"); _; } 
    function whitelistMintStatus() external view returns (bool) {
        return _whitelistMintEnabled && _whitelistMintTime <= block.timestamp; }
}


// Open0x Presets //
// ERC721I_OW (ERC721I 0xInuarashi Edition, Ownable, Whitelist) 

abstract contract ERC721I_OW is ERC721I, Ownable, Security, PublicMint, WhitelistMint {

    constructor(string memory name_, string memory symbol_) ERC721I(name_, symbol_) {}

    // Ownable Functions for ERC721I_OW //
    
    // Token URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner { 
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Public Mint
    function setPublicMint(bool bool_, uint256 time_) external onlyOwner {
        _setPublicMint(bool_, time_);
    }
    
    // Whitelist Mint
    function setWhitelistMint(bool bool_, uint256 time_) external onlyOwner {
        _setWhitelistMint(bool_, time_);
    }

}

contract TunaFish is ERC721I_OW {
    constructor() payable ERC721I_OW("Tuna Fish", "TUNA") {}

    // Project Contraints
    uint256 public mintPrice = 0.03 ether;
    uint256 public maxTokens = 10000;

    uint256 public maxMintsPerWl = 5;
    mapping(address => uint256) public addressToWlMints;

    uint256 public maxMintsPerTx = 5;

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }
    function setMaxtokens(uint256 maxTokens_) external onlyOwner {
        require(totalSupply <= maxTokens_, "Below totalSupply");
        maxTokens = maxTokens_;
    }

    // Internal Mint
    function _mintMany(address to_, uint256 amount_) internal {
        require(maxTokens >= totalSupply + amount_,
            "Not enough tokens remaining!");

        uint256 _startId = totalSupply + 1; // iterate from 1

        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
        }
        totalSupply += amount_;
    }

    // Owner Functions
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        _mintMany(to_, amount_);
    }
    function ownerMintToMany(address[] calldata tos_, uint256[] calldata amounts_) 
    external onlyOwner {
        require(tos_.length == amounts_.length, 
            "Array lengths mismatch!");
        
        for (uint256 i = 0; i < tos_.length; i++) {
            _mintMany(tos_[i], amounts_[i]);
        }
    }
    function ownerAddWl(address address_) external onlyOwner {
        _addWhitelistAddress(address_);
    }
    function ownerAddManyWl(address[] calldata addressList_) external onlyOwner {
        for (uint256 i = 0; i < addressList_.length; i++) {
            _addWhitelistAddress(addressList_[i]);
        }
    }
    function ownerRemoveWl(address address_) external onlyOwner {
        _removeWhitelistAddress(address_);
    }
    function ownerRemoveManyWl(address[] calldata addressList_) external onlyOwner {
        for (uint256 i = 0; i < addressList_.length; i++) {
            _removeWhitelistAddress(addressList_[i]);
        }
    }
    function withdrawAll() external onlyOwner{
        require(payable(msg.sender).send(address(this).balance));
    }



    // Whitelist Mint Functions
    function whitelistMint(uint256 amount_) external payable 
    onlySender whitelistMintEnabled isWhitelisted{
        require(maxMintsPerWl >= addressToWlMints[msg.sender] + amount_,
            "Over Max Mints per TX or Not enough whitelist mints remaining for you!");
        require(msg.value == mintPrice * amount_,   
            "Invalid value sent!");
        
        // Add address to WL minted
        addressToWlMints[msg.sender] += amount_;

        _mintMany(msg.sender, amount_);
    }

    // Public Mint Functions
    function publicMint(uint256 amount_) external payable onlySender publicMintEnabled {
        require(maxMintsPerTx >= amount_,
            "Over maxmimum mints per Tx!");
        require(msg.value == mintPrice * amount_, 
            "Invalid value sent!");

        _mintMany(msg.sender, amount_);
    }

    // Public View Functions
    function getAllForOwner(address _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](balanceOf[_owner]);
    uint counter = 0;
    for (uint i = 0; i < totalSupply; i++) {
      if (ownerOf[i] == _owner) {
        result[counter] = i;
        counter++;
      }
      if (result.length == balanceOf[_owner]){
          break;
      }
    }
    return result;
  }
}