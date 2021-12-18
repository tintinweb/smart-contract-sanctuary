// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

interface AttributesInterface {

    function initAttributes(uint256 tokenId) external;
    
}

contract TheGirl is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public SALE_PRICE = 98000000000000000;

    uint256 public saleStartTime;

    address public _attributesAddress;

    mapping(uint256 => bool) public isInitAttribute;

    mapping(address => uint256) public refCode;

    mapping(uint256 => address) refCodeToAddress;

    mapping(address => uint256) refRate;

    uint256 public baseRate = 2000;//20%
 
    string private _baseURIExtended = "ipfs://QmWKLrJp6B6pv8TrPP7yvJ6zRRBAEnm2tjpp6DvPp8QRxT/";

    event InitAttributes(address account, uint256 tokenId);
    
    constructor() ERC721("The Girl Games", "THEGIRL") { }

    function mint(uint256 quantity, uint256 code) external payable nonReentrant {
        require(block.timestamp > saleStartTime || refRate[msg.sender]>0, "Mint hasn't started");
        require(quantity > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        uint256 amount = SALE_PRICE * quantity;
        require(msg.value >= amount,"Sent ether value is incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
            if(refCode[msg.sender] == 0) {
                refCode[msg.sender] = tokenId;
                refCodeToAddress[tokenId] = msg.sender;
            }
        }
        address refaddr = refCodeToAddress[code];
        if(code > 0 && refaddr != address(0)) {
            uint256 rate = getRate(refaddr);
            if(rate>0){
                uint256 reward = (amount * rate) / 10000;
                if(reward > 0 && reward < amount) {
                    payable(refaddr).transfer(reward);
                }
            }
        }
    }

    function initAttributes(uint256 tokenId) public {
        require(_exists(tokenId),"ERC721Metadata: nonexistent token");
        require(!isInitAttribute[tokenId], "TokenId has been initialized");
        AttributesInterface(_attributesAddress).initAttributes(tokenId);
        isInitAttribute[tokenId] = true;
        emit InitAttributes(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        string memory url  = string(abi.encodePacked(base, tokenId.toString()));
        return string(abi.encodePacked(url,".json"));
    }

    function initAttributeStatus(uint256 tokenId) public view returns (bool) {
        return isInitAttribute[tokenId];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getRate(address addr) public view virtual returns (uint256) {
        if(refRate[addr] == 0){
            return baseRate;
        }else{
            return refRate[addr];
        }
    }

    function getCode(address addr) public view virtual returns (uint256) {
        return refCode[addr];
    }

    function remainingTime() public view returns (uint256) {
        if(saleStartTime > block.timestamp) {
            return saleStartTime - block.timestamp;
        }
        return 0;
    }

    function setRate(address[] memory addrs,uint256 rate) external onlyOwner {
        require(rate <= 10000,"Exceeds the maximum number");
        for(uint256 i=0;i<addrs.length;i++){
            address item = addrs[i];
            refRate[item] = rate;
        } 
    }

    function setBaseRate(uint256 rate) external onlyOwner {
        require(rate <= 10000,"Exceeds the maximum number");
        baseRate = rate;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        SALE_PRICE = price;
    }

    function setSaleStartTime(uint256 startTime) external onlyOwner {
        saleStartTime = startTime;
    }

    function setAttributesAddress(address attributesAddr) external onlyOwner {
        _attributesAddress = attributesAddr;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}