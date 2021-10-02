pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ECDSA.sol";

contract RFC is ERC721 {
    using ECDSA for bytes32;
    using Strings for uint256;
    
    //  Events
    event newMint(uint256 uniqueId); 
    
    
    //  Storage Variables
    
    address internal admin;
    address public signer = 0x9e3b5C16a82C9fE6b91BC12091096D6CAB5F4D54; // Used to validate whitelist mint and giveaway claim
    
    uint256 public totalSupply;
    
    bool public isSaleActive;
    bool public metadataLocked;
    
    string currentBaseURI;
    
    mapping(uint256 => uint256) public lastTransfer;
    
    
    //  Constructor
    
    constructor() ERC721("RFC", "RFC"){
        admin = msg.sender;
        
        _mint(address(this),0);
        for(uint256 i = 1; i <= 10; i++) {
            _mint(msg.sender, i);
        }
        totalSupply = 11;
        isSaleActive = true;
    }
    
    //  Modifiers
    
    modifier adminOnly {
        require(msg.sender == admin,"Only the admin can call this function");
        _;
    }
    modifier userOnly {
        require(tx.origin == msg.sender,"Only a user may call this function!");
        _;
    }
    
    modifier isValidSignature(bytes calldata _calldata, bytes32 functionVerify) {
        require(_calldata.length == 69, "Incorrect data");        
        require(keccak256(_calldata[:2]) == functionVerify, "Function signature missmatch");
        
        address signerAddress = keccak256(abi.encode(_calldata[:2],_calldata[2:4],msg.sender)).toEthSignedMessageHash().recover(_calldata[4:]); // Signature is created using the function signature, the data(token id to mint or amount to mint) and the sender to make sure it can't be used by other users or with other data
        require(signerAddress == signer, "Signature validation failed");
        _;
    }
    
    //   Minting and giveaway
    // Calldata for functions that require a signature will look like 0xa3d4271140e874c3b995b7397c5a3... the first 2 bytes(a3d4) is the function signature, the next 2(2711) is the data which is either the amount to mint or which token is being given away
    
    function redeemGiveaway(bytes calldata _calldata) userOnly external isValidSignature(_calldata,0x858505580b6d652b3cd3f7398e00c2edfa68067f99eafa91059134afd77f85c9) { // The hash is hardcoded cause solidity was giving me a hard time, works well now
        
        uint16 tokenId = getData(_calldata);
        require(tokenId >= 10000 && tokenId < 10400,"That token is not reserved!");
        _mint(msg.sender,tokenId);
    }
    
    function mintWithWhitelist(bytes calldata _calldata) payable userOnly external isValidSignature(_calldata,0xa4a707902697c8bdba996a2aebc226e7f56b53f74013de4bf82dd3fff296e94e) { // The hash is hardcoded cause solidity was giving me a hard time, works well now
        
        uint16 amountToMint = getData(_calldata);
        require(amountToMint <= 4,"Maximum amount of characters mintable at once is 4");
        internalMint(amountToMint);
    }
    
    function publicMint(uint256 numberToMint) payable userOnly external {
        require(isSaleActive, "Sale is not active!");
        require(numberToMint <= 20, "Maximum amount of characters mintable at once is 20");
        
        internalMint(numberToMint);
    }
    
    function publicMint() payable userOnly external {
        require(isSaleActive, "Sale is not active!");
        
        internalMint(1);
    }
    
    //  Internal functions
    
    function getData(bytes calldata _calldata) internal pure returns(uint16) { // Conversion to uint16
        bytes memory idData = _calldata[2:4]; 
        uint16 data;
        assembly {
            data := mload(add(add(idData, 0x2), 0))
        }
        return data;
    }
    
    function internalMint(uint256 numberToMint) internal {
        uint256 _totalSupply = totalSupply;
        require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        require(msg.value >= numberToMint * 0.1 ether, "0.1 ether are required to create each token!");
        
        for(uint256 i = 0; i < numberToMint; i++) {
            _mint(msg.sender, _totalSupply + i);
            
        }
        
        totalSupply = _totalSupply + numberToMint;
        if(msg.value > numberToMint * 0.1 ether) { // Refund excess ether
            payable(msg.sender).transfer(msg.value - numberToMint * 0.1 ether);
        }
    }
    
    function _beforeTokenTransfer(address _from,address to,uint256 tokenId) internal override {
        if(_from == address(0)) {
            emit newMint(tokenId);
        } else {
            lastTransfer[tokenId] = block.timestamp;
        }
    }
    
    
    //  External/public functions
    
    function safeTransferTo(address to,uint256 tokenId) external {
        safeTransferFrom(msg.sender,to,tokenId);
    }
    
    function transferTo(address to,uint256 tokenId) external {
        transferFrom(msg.sender,to,tokenId);
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
        return 10400;
    }
    
    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId),"Invalid tokenId");
        
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),".json")) : "";
    }
    
    function owner() external view returns(address) {
        return admin;
    }
    
    
    //  Admin only functions
    
    function _adminMint(uint256 numberToMint,address _address) external adminOnly {
        uint256 _totalSupply = totalSupply;
        require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        
        for(uint256 i = 0; i < numberToMint; i++) {
            _mint(_address, _totalSupply + i);
        }
        
        totalSupply = _totalSupply + numberToMint;
    }
    
    function _adminMint(uint256 numberToMint) external adminOnly {
        uint256 _totalSupply = totalSupply;
        require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        
        for(uint256 i = 0; i < numberToMint; i++) {
            _mint(msg.sender, _totalSupply + i);
        }
        
        totalSupply = _totalSupply + numberToMint;
    }
    
    function _adminLockMetadata() external adminOnly{ metadataLocked = true; }
    
    function _adminSetAdmin(address _admin) external adminOnly { admin = _admin; }
    
    function _adminSetSigner (address _signer) external adminOnly { signer = _signer; }
    
    function _adminWithdraw() external adminOnly { payable(msg.sender).transfer(address(this).balance); }
    
    function _adminSetBaseURI(string memory baseURI) external adminOnly { require(!metadataLocked); currentBaseURI = baseURI; }
    
    function _adminFlipSaleState() external adminOnly { isSaleActive = !isSaleActive; }
    
    function _adminEmergencySetSupply(uint256 supply) external adminOnly { totalSupply = supply; }
}