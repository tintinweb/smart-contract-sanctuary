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
        for(uint256 i = 1; i <= 30; i++) {
            _mint(msg.sender, i);
        }
        totalSupply = 31;
        // isSaleActive = false;
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
    
    modifier isValidSignature(bytes calldata _calldata, address _signer) {
        // Signature is created using a function identifier, the data(token id to mint or amount to mint) and the sender to make sure it can't be used by other users or with other data
        require(keccak256(abi.encode(_calldata[:_calldata.length-65],msg.sender)).toEthSignedMessageHash().recover(_calldata[_calldata.length-65:]) == _signer, "Signature validation failed");
        _;
    }
    
    //   Minting and giveaway
     
    function redeemGiveaway(bytes[] calldata _calldata) userOnly external  {
        address _signer = signer;
        for(uint256 i = 0; i < _calldata.length; i++) {
            internalGiveaway(_calldata[i],_signer);
        }
    }
    
    function mintWithWhitelist(bytes calldata _calldata) payable userOnly external isValidSignature(_calldata, signer) {
        bytes memory data = _calldata[:2]; // to get data bytes, remove the last 65 bytes (signature)
        
        require(bytes1(_calldata[:1]) == 0x00);
        uint8 amountToMint;
        
        assembly {
            amountToMint := mload(add(data,0x2)) // load 1 bytes(uint8) (0x2)
        }
        
        require(amountToMint <= 20,"Maximum mintable at once is 20!");
        _batchMint(amountToMint);
    }
    
    function publicMint(uint256 numberToMint) payable userOnly external {
        require(isSaleActive, "Sale is not active!");
        require(numberToMint <= 20, "Maximum amount of characters mintable at once is 20");
        
        _batchMint(numberToMint);
    }
    
    function mintTest(uint256 numberToMint) payable userOnly external {
        _mint(msg.sender,totalSupply);
        totalSupply++;
    }
    
    //  Internal functions
    
    function internalGiveaway(bytes calldata _calldata, address _signer) internal isValidSignature(_calldata,_signer) {
        bytes memory data = _calldata;
        
        require(bytes1(_calldata[:1]) == 0x01);
        uint16 tokenId;
        
        assembly {
            tokenId := mload(add(data,0x03))
        }
        
        require(tokenId >= 10000 && tokenId <= 10399,"That token is not reserved!");
        _mint(msg.sender,tokenId);
    }
    
    function _batchMint(uint256 numberToMint) internal {
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
    
    // function _adminMint(uint256 numberToMint,address _address) external adminOnly {
    //     uint256 _totalSupply = totalSupply;
    //     require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        
    //     for(uint256 i = 0; i < numberToMint; i++) {
    //         _mint(_address, _totalSupply + i);
    //     }
        
    //     totalSupply = _totalSupply + numberToMint;
    // }
    
    // function _adminMint(uint256 numberToMint) external adminOnly {
    //     uint256 _totalSupply = totalSupply;
    //     require(_totalSupply + numberToMint <= 10000, "The limit of allowable tokens has been reached!");
        
    //     for(uint256 i = 0; i < numberToMint; i++) {
    //         _mint(msg.sender, _totalSupply + i);
    //     }
        
    //     totalSupply = _totalSupply + numberToMint;
    // }
    
    function _adminLockMetadata() external adminOnly{ metadataLocked = true; }
    
    function _adminSetAdmin(address _admin) external adminOnly { admin = _admin; }
    
    function _adminSetSigner (address _signer) external adminOnly { signer = _signer; }
    
    function _adminWithdraw() external adminOnly { payable(msg.sender).transfer(address(this).balance); }
    
    function _adminSetBaseURI(string memory baseURI) external adminOnly { require(!metadataLocked); currentBaseURI = baseURI; }
    
    function _adminFlipSaleState() external adminOnly { isSaleActive = !isSaleActive; }
    
    // function _adminEmergencySetSupply(uint256 supply) external adminOnly { totalSupply = supply; }
}