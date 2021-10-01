pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ECDSA.sol";

contract RFC is ERC721 {
    using ECDSA for bytes32;
    
    event newMint(uint256 uniqueId); 
    
    address internal admin;
    address public signer = 0x9e3b5C16a82C9fE6b91BC12091096D6CAB5F4D54; // Used to validate whitelist mint and giveaway claim
    
    uint256 public totalSupply = 31;
    
    bool public isSaleActive = true;
    bool public metadataLocked = false;
    
    string currentBaseURI;
    
    mapping(uint256 => uint256) public lastTransfer;
    
    constructor() ERC721("RFC", "RFC"){
        admin = msg.sender;
        
        _mint(address(this),0);
        for(uint256 i = 1; i <= 30; i++) {
            _mint(msg.sender, i);
        }
    }
    
    
    modifier adminOnly {
        require(msg.sender == admin,"Only the admin can call this function");
        _;
    }
    modifier userOnly {
        require(tx.origin == msg.sender,"Only a user may call this function!");
        _;
    }
    
    function redeemGiveaway(bytes calldata rawdata) userOnly external {
        require(rawdata.length == 67, "Incorrect data");
        
        bytes memory idData = rawdata[:2];
        uint16 tokenId;
        assembly {
            tokenId := mload(add(add(idData, 0x2), 0))
        }
        
        require(tokenId > 10000 && tokenId < 10400);
        address signerAddress = keccak256(abi.encode(msg.sender,tokenId)).toEthSignedMessageHash().recover(rawdata[2:]);
        require(signerAddress == signer, "Signature validation failed");
        
        _mint(msg.sender,tokenId);
        emit newMint(tokenId);
    }
    
    function mintWithWhitelist(bytes calldata _data, bytes calldata _signature) payable userOnly external {
        address signerAddress = keccak256(abi.encode(msg.sender, _data)).toEthSignedMessageHash().recover(_signature);
        require(signerAddress == signer, "Signature validation failed");
        
        uint8 numberToMint = abi.decode(_data, (uint8));
        assert(numberToMint < 5); // Should always be 1-4 otherwise there is a problem with the backend
        
        internalMint(numberToMint);
    }
    
    function mint(uint256 numberToMint) payable userOnly external {
        require(isSaleActive, "Sale is not active!");
        require(numberToMint <= 20, "Maximum amount of characters mintable at once is 20");
        
        internalMint(numberToMint);
    }
    
    function getTokenOfOwnerByIndexByPage(address _owner, uint256 index, uint256 page) external view returns(uint256) {
        uint256 _index = 0;
        for(uint256 i = page * 1000; i < page * 1000 + 1000; i++) {
            if(_owner == _owners[i]) {
                if(_index == index)
                    return i;
                _index++;
            }
        }
        return 10000;
    }
    
    function internalMint(uint256 numberToMint) internal {
        uint256 _totalSupply = totalSupply;
        require(_totalSupply + numberToMint < 10001, "The limit of allowable tokens has been reached!");
        require(msg.value >= numberToMint * 0.1 ether, "0.1 ether are required to create each token!");
        
        for(uint256 i = 0; i < numberToMint; i++) {
            _mint(msg.sender, _totalSupply + i);
            emit newMint(_totalSupply + i);
        }
        
        totalSupply = _totalSupply + numberToMint;
        if(msg.value > numberToMint * 0.1 ether) { // Refund excess ether
            payable(msg.sender).transfer(msg.value - numberToMint * 0.1 ether);
        }
    }
    
    function adminTestMint(uint256 numberToMint,address _address) external adminOnly {
        uint256 _totalSupply = totalSupply;
        require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        
        for(uint256 i = 0; i < numberToMint; i++) {
            _mint(_address, _totalSupply + i);
            emit newMint(_totalSupply + i);
        }
        
        totalSupply = _totalSupply + numberToMint;
    }
    
    function adminLockMetadata() external adminOnly{
        metadataLocked = true; // lock metadata once we transition to ipfs
    }
    
    function adminSetOwner(address _admin) external adminOnly {
        admin = _admin;
    }
    
    function adminSetSigner (address _signer) external adminOnly {
        signer = _signer; // signer account that will be used on the server backend to sign transactions for the presale only to whitelisted addresses.
    }
    
    function adminWithdraw() external adminOnly {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
    
    function adminSetBaseURI(string memory baseURI) public adminOnly {
        require(!metadataLocked);
        currentBaseURI = baseURI;
    }
    
    function adminFlipSaleState() external adminOnly {
        isSaleActive = !isSaleActive;
    }
    
    
    function _transfer(address from,address to,uint256 tokenId) internal override {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1; 
        _owners[tokenId] = to;
        lastTransfer[tokenId] = block.timestamp;
        emit Transfer(from, to, tokenId);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }
    
    function balance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function owner() external view returns(address) {
        return admin;
    }
    
    fallback() external {
        revert();
    }    
}