// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract DickInDisguise is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant DID_GIFT = 369;
    uint256 public constant DID_PRESALE = 2200;
    uint256 public constant DID_PUBLIC = 4400;
    uint256 public constant DID_MAX = DID_GIFT + DID_PRESALE + DID_PUBLIC;
    uint256 public DID_PER_MINT = 5;
    uint256 public DID_PRICE = 0.03 ether;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    mapping(string => bool) private _usedNonces;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://didid.gg/api/metadata/";
    string private _notRevealedUri;
    address private _signerAddress = 0x989c8DE75AC4e3E72044436b018090c97635A7fa;

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public presaleAmountMinted;
    uint256 public presalePurchaseLimit = 2;
    uint256 public presaleRound = 1;
    bool public presaleLive;
    bool public saleLive;
    bool public locked;
    bool public revealed = false;
    
    constructor(

    ) ERC721("Dick In Disguise", "DID") {

    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE");
            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            presalerList[entry] = false;
        }
    }
    
    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );
          
          return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(!presaleLive, "ONLY_PRESALE");
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
        require(totalSupply() < DID_MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= DID_PUBLIC, "EXCEED_PUBLIC");
        require(tokenQuantity <= DID_PER_MINT, "EXCEED_DID_PER_MINT");
        require(DID_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
        _usedNonces[nonce] = true;
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(totalSupply() < DID_MAX, "OUT_OF_STOCK");
        require(DID_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(presaleRound >=1 && presaleRound <=3, "NOT_CORRECT_ROUND");
        require(presalerList[msg.sender], "NOT_QUALIFIED");
        require(presaleAmountMinted + tokenQuantity <= DID_PRESALE, "EXCEED_PRESALE");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            presaleAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= DID_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= DID_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }
    
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function setPresaleRound(uint256 round) external onlyOwner {
        presaleRound = round;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
    
    function reveal() public onlyOwner notLocked {
        revealed = true;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner notLocked {
        DID_PRICE = _newPrice;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner notLocked {
        DID_PER_MINT = _newmaxMintAmount;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner notLocked {
        _tokenBaseURI = _newBaseURI;
    }
    
    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner notLocked {
        _notRevealedUri = _newNotRevealedURI;
    }

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    // aWYgeW91IHJlYWQgdGhpcywgc2VuZCBGcmVkZXJpayMwMDAxLCAiZnJlZGR5IGlzIGJpZyI=
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        if(revealed == false) {
            return _notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
            : "";
    }
}