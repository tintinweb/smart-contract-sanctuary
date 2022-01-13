/**
 *Submitted for verification at Etherscan.io on 2022-01-13
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

abstract contract MerkleWhitelist {
    bytes32 internal _merkleRoot;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual {
        _merkleRoot = merkleRoot_;
    }
    function isWhitelisted(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
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
    bool internal _whitelistMintEnabled; uint256 public _whitelistMintTime;
    function _setWhitelistMint(bool bool_, uint256 time_) internal {
        _whitelistMintEnabled = bool_; _whitelistMintTime = time_; }
    modifier whitelistMintEnabled {
        require(_whitelistMintEnabled && _whitelistMintTime <= block.timestamp, 
            "Whitelist Mint is not enabled yet!"); _; } 
    function whitelistMintStatus() external view returns (bool) {
        return _whitelistMintEnabled && _whitelistMintTime <= block.timestamp; }
}


// Open0x Presets //
// ERC721I_OW (ERC721I 0xInuarashi Edition, Ownable, Whitelist) 

abstract contract ERC721I_OW is ERC721I, Ownable, MerkleWhitelist, Security, PublicMint, WhitelistMint {

    constructor(string memory name_, string memory symbol_) ERC721I(name_, symbol_) {}

    // Ownable Functions for ERC721I_OW //
    
    // Token URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner { 
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // MerkleRoot
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
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

abstract contract PayableGovernance is Ownable {
    // Special Access
    address _payableGovernanceSetter;
    constructor() payable { _payableGovernanceSetter = msg.sender; }
    modifier onlyPayableGovernanceSetter {
        require(msg.sender == _payableGovernanceSetter, "PayableGovernance: Caller is not Setter!"); _; }
    function reouncePayableGovernancePermissions() public onlyPayableGovernanceSetter {
        _payableGovernanceSetter = address(0x0); }

    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Required Variables
    address payable[] internal _payableGovernanceAddresses;
    uint256[] internal _payableGovernanceShares;    
    mapping(address => bool) public addressToEmergencyUnlocked;

    // Withdraw Functionality
    function _withdraw(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }

    // Governance Functions
    function setPayableGovernanceShareholders(address payable[] memory addresses_, uint256[] memory shares_) public onlyPayableGovernanceSetter {
        require(_payableGovernanceAddresses.length == 0 && _payableGovernanceShares.length == 0, "Payable Governance already set! To set again, reset first!");
        require(addresses_.length == shares_.length, "Address and Shares length mismatch!");
        uint256 _totalShares;
        for (uint256 i = 0; i < addresses_.length; i++) {
            _totalShares += shares_[i];
            _payableGovernanceAddresses.push(addresses_[i]);
            _payableGovernanceShares.push(shares_[i]);
        }
        require(_totalShares == 1000, "Total Shares is not 1000!");
    }
    function resetPayableGovernanceShareholders() public onlyPayableGovernanceSetter {
        while (_payableGovernanceAddresses.length != 0) {
            _payableGovernanceAddresses.pop(); }
        while (_payableGovernanceShares.length != 0) {
            _payableGovernanceShares.pop(); }
    }

    // Governance View Functions
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    function payableGovernanceAddresses() public view returns (address payable[] memory) {
        return _payableGovernanceAddresses;
    }
    function payableGovernanceShares() public view returns (uint256[] memory) {
        return _payableGovernanceShares;
    }

    // Withdraw Functions
    function withdrawEther() public onlyOwner {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 && _payableGovernanceShares.length > 0, "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length == _payableGovernanceShares.length, "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the withdrawal process if all conditionals pass
        // store current balance in local memory
        uint256 _totalETH = address(this).balance; 

        // withdraw loop for payable governance
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            uint256 _ethToWithdraw = ((_totalETH * _payableGovernanceShares[i]) / 1000);
            _withdraw(_payableGovernanceAddresses[i], _ethToWithdraw);
        }
    }

    function viewWithdrawAmounts() public view onlyOwner returns (uint256[] memory) {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 && _payableGovernanceShares.length > 0, "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length == _payableGovernanceShares.length, "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the array creation process if all conditionals pass
        // store current balance in local memory and instantiate array for input
        uint256 _totalETH = address(this).balance; 
        uint256[] memory _withdrawals = new uint256[] (_payableGovernanceAddresses.length + 2);

        // array creation loop for payable governance values 
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[i] = ( (_totalETH * _payableGovernanceShares[i]) / 1000 );
        }
        
        // push two last array spots as total eth and added eths of withdrawals
        _withdrawals[_payableGovernanceAddresses.length] = _totalETH;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[_payableGovernanceAddresses.length + 1] += _withdrawals[i]; }

        // return the final array data
        return _withdrawals;
    }

    // Shareholder Governance
    modifier onlyShareholder {
        bool _isShareholder;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            if (msg.sender == _payableGovernanceAddresses[i]) {
                _isShareholder = true;
            }
        }
        require(_isShareholder, "You are not a shareholder!");
        _;
    }
    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        addressToEmergencyUnlocked[msg.sender] = true;
    }

    // Emergency Functions
    modifier onlyEmergency {
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            require(addressToEmergencyUnlocked[_payableGovernanceAddresses[i]], "Emergency Functions are not unlocked!");
        }
        _;
    }
    function emergencyWithdrawEther() public onlyOwner onlyEmergency {
        _withdraw(payable(msg.sender), address(this).balance);
    }
}

interface iYield {
    function updateRewardOnTransfer(address from_, address to_, uint256 tokenId_) external;
}

contract AscendedNFT is ERC721I_OW, PayableGovernance {
    constructor() payable ERC721I_OW("Ascended NFT", "ASCENDED") {}

    // Project Contraints
    uint256 public mintPrice = 0.08 ether;
    uint256 public maxTokens = 8888;

    uint256 public maxMintsPerWl = 4;
    mapping(address => uint256) public addressToWlMints;

    uint256 public maxMintsPerTx = 10;

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }
    function setMaxtokens(uint256 maxTokens_) external onlyOwner {
        require(totalSupply >= maxTokens_, "Below totalSupply");
        maxTokens = maxTokens_;
    }

    // Setting Future-Proof Token Yield
    iYield public Yield;
    function setYieldToken(address address_) external onlyOwner {
        Yield = iYield(address_);
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

    // Owner Mint Functions
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

    // Whitelist Mint Functions
    function whitelistMint(bytes32[] calldata proof_, uint256 amount_) external payable 
    onlySender whitelistMintEnabled {
        require(isWhitelisted(msg.sender, proof_), 
            "You are not Whitelisted!");
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

    /////////////////////////////////////////////////////
    // Withdraw Functions handled by PayableGovernance //
    /////////////////////////////////////////////////////

    // Future-Proof Transfer Hook Yield Overrides
    function transferFrom(address from_, address to_, uint256 tokenId_) public 
    override {
        if ( Yield != iYield(address(0x0)) ) {
            Yield.updateRewardOnTransfer(from_, to_, tokenId_);    
        }
        ERC721I.transferFrom(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, 
    bytes memory data_) public override {
        if ( Yield != iYield(address(0x0)) ) {
            Yield.updateRewardOnTransfer(from_, to_, tokenId_);    
        }
        ERC721I.safeTransferFrom(from_, to_, tokenId_, data_);
    }
}