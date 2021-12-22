//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract DestinyWarMount is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    struct Item{
        uint number; 
        uint level; 
        string image;
    }
    
    mapping(uint256 => Item) public items;
    string[] public images;
    
    Counters.Counter private _tokenIdCounter;
    uint256 private constant tokenPrice = 35000000000000000; // 0.035 BNB
    uint public constant maxTokenPurchase = 1;
    uint256 public maxSupply = 50000;
    uint256 public _level = 1;
    bool public saleIsActive = true;
    bool public presaleActive = false;
    bool public revealed = true;
    string public notRevealedUri;
    string private baseExtension = ".json";
    string private baseImgExtension = ".png";
    string private _baseURIextended;
    // for Normal NFT
    uint256 public amntNormal = 50000;
    uint256 public amntNormalImg = 90;
    string  public normalImgUri;

    
    address  fundAddr = 0x9fEF2309Faa76aDD97030f2D1359b8149d474709;


    mapping(address => bool) public isMinted;

    // WhiteLists for presale.
    mapping(address => uint256) public Whitelist;

    // StakeHolders for Free mint.
    mapping(address => uint256) public stakeHolderList;
    
    
    constructor(string memory _notrevealURI, string memory _normalImgURI) ERC721("DestinyWarMount", "DWM") { 
        notRevealedUri = _notrevealURI;
        normalImgUri = _normalImgURI;
    }

    function setNormalImgURI(string memory _uri) external onlyOwner {
        normalImgUri = _uri;
    }

     
    function setLevel(uint256 level) external onlyOwner{
        _level = level;
    }

    function setAmntNormal(uint256 _amntNormal) external onlyOwner{
        amntNormal = _amntNormal;
    }

    function setAmntNormalImg(uint256 _amntNormalImg) external onlyOwner{
        amntNormalImg = _amntNormalImg;
    }


    function random(uint256 limit) public view returns (uint256) {
      return uint8(uint256(keccak256(abi.encodePacked(block.timestamp)))%(limit));
    }

    function setFundAddress(address addr) external  onlyOwner {
        fundAddr = addr;
    }   

    function reveal() external onlyOwner {
        revealed = true;
    }
    
    function hide() external onlyOwner {
        revealed = false;
    }

    function setMax(uint256 _supply) external onlyOwner() {
        maxSupply = _supply;
    }

    function addWhiteList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            Whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function isWhiteList(address addr) external view returns (uint256) {
        return Whitelist[addr];
    }

    function addStakeHolderList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            stakeHolderList[addresses[i]] = numAllowedToMint;
        }
    }

    function isHolderList(address addr) external view returns (uint256) {
        return stakeHolderList[addr];
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseImgExtension))
            : "";
        
    }
    
    modifier soldOut {
        require(totalSupply() > maxSupply - 1, "Not Soldout!");
        _;
    }

    function tooglePublicSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function DwarMount(uint256 numberOfTokens) public payable {

        require(numberOfTokens == 1, 'can not mint more than 1 NFT');
        require(isMinted[msg.sender] == false, "already minted Character NFT");
        uint256 holder = stakeHolderList[msg.sender];
        if (holder > 0) {
            require(numberOfTokens <= holder, 'this stakeholder is not allowed to mint that many');
            stakeHolderList[msg.sender] = holder - numberOfTokens;
            for(uint i = 0; i < numberOfTokens; i++) internalMint(msg.sender);
        } else {
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
            if (!saleIsActive) {
                require(presaleActive == true, 'presale is not open');
                uint256 who = Whitelist[msg.sender];
                require(who > 0, 'this address is not whitelisted for the presale');
                require(numberOfTokens <= who, 'this address is not allowed to mint that many during the presale');
                for (uint256 i = 0; i < numberOfTokens; i++) internalMint(msg.sender);
                Whitelist[msg.sender] = who - numberOfTokens;
                return;                
            }
           require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
           for(uint i = 0; i < numberOfTokens; i++) internalMint(msg.sender);
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
      function getItemProperty(uint256 _tokenId) external view returns (uint256 number, uint256 level, string memory image) {
        return (items[_tokenId].number, items[_tokenId].level, items[_tokenId].image);
      }
  
    function internalMint(address to) internal {
        require(totalSupply() < maxSupply, 'supply depleted');
        _tokenIdCounter.increment();
        uint256 imgId =  random(amntNormalImg);
        string memory _image = string(abi.encodePacked(normalImgUri, imgId.toString(), baseImgExtension));
        items[_tokenIdCounter.current()] = Item({number:_tokenIdCounter.current(), level : _level, image : _image });
        _safeMint(to, _tokenIdCounter.current());
        isMinted[to] = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(fundAddr).transfer(balance);
    }

}