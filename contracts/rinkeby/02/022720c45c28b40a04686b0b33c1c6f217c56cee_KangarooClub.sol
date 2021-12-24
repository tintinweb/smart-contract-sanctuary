// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

import "./Ownable.sol";

contract KangarooClub is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public reserved = 50;
    uint256 public presaleSupply = 3333;
    uint256 public presalePrice = 0.03 ether;
    uint256 public tier3Price = 0.05 ether;
    uint256 public tier2Price = 0.04 ether;
    uint256 public tier1Price = 0.03 ether;
    uint256 public MINT_CAP = 21;
    address public dev = 0xE1995a6441B0e5443f5403A69e530a33249C4f2a; //address to withdraw to

    struct WhitelistEntry {
        bool isApproved;
        uint reservedQuantity;
    }

    mapping(address => WhitelistEntry) public whitelist;
    
    bool public presale;
    bool public publicsale;
    bool public revealed;

    string public defaultURI;

    constructor(string memory _defaultURI) ERC721('Kangaroo Club', 'KGC')
    {
        defaultURI = _defaultURI;        
    }

    function _mintKangaroo(uint256 num) internal returns (bool) {
        for (uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_SUPPLY) _safeMint(_msgSender(), tokenIndex);
        }
        return true;
    }

    function presaleKangaroo(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(presale, 'The presale have NOT started, please be patient.');
        require(whitelist[msg.sender].isApproved, "You are not in the whitelist to mint");
        require(num < MINT_CAP,'You are trying to mint too many at a time');
        require(currentSupply + num <= presaleSupply, 'Exceeded pre-sale supply');
        require(whitelist[msg.sender].reservedQuantity >= num, "Insufficient reserved presale quantity");
        require(msg.value >= presalePrice * num,'Ether value sent is not sufficient');
        whitelist[msg.sender].reservedQuantity -= num;
        return _mintKangaroo(num);
    }

    function publicsaleKangaroo(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(publicsale, 'The publicsale have NOT started, please be patient.');
        require(num < MINT_CAP,'You are trying to mint too many at a time');
        require(currentSupply + num <= MAX_SUPPLY - reserved, 'Exceeded total supply');
         
        if(num < 5){
            require(msg.value >= tier3Price * num,'Ether value sent is not sufficient');
        } else if (num < 10){
            require(msg.value >= tier2Price * num,'Ether value sent is not sufficient');
        } else {
            require(msg.value >= tier1Price * num,'Ether value sent is not sufficient');
        }
        return _mintKangaroo(num);
    }

    function tokensOfOwner(address _owner)external view returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");
 
        // show default image before reveal
        if (!revealed) {
            return defaultURI;
        }

        string memory _tokenURI = _tokenUriMapping[tokenId];

        //return tokenURI if it is set
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        //If tokenURI is not set, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    /*
     * Only the owner can do these things
     */

    function addToWhitelist(address _address, uint256 reservedQty) public onlyOwner {
        whitelist[_address] = WhitelistEntry(true, reservedQty);
    }

    function flipWhitelistApproveStatus(address _address) public onlyOwner {
        whitelist[_address].isApproved = !whitelist[_address].isApproved;
    }

    function addressIsPresaleApproved(address _address) public view returns (bool) {
        return whitelist[_address].isApproved;
    }

    function getReservedPresaleQuantity(address _address) public view returns (uint256) {
        return whitelist[_address].reservedQuantity;
    }

    function initPresaleWhitelist(address [] memory addr, uint [] memory quantities) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            whitelist[addr[i]] = WhitelistEntry(true, quantities[i]);
        }
    }

    function togglePublicsale() public onlyOwner {
        publicsale = !publicsale;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setPresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
    }

    function setPreSalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setTier3Price(uint256 _newPrice) public onlyOwner {
        tier3Price = _newPrice;
    }

    function setTier2Price(uint256 _newPrice) public onlyOwner {
        tier2Price = _newPrice;
    }

    function setTier1Price(uint256 _newPrice) public onlyOwner {
        tier1Price = _newPrice;
    }

    function setMintCap(uint256 _mintCap) public onlyOwner {
        MINT_CAP = _mintCap;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devShare = balance.mul(3).div(100);  
        uint256 ownerShare = balance.sub(devShare); 
        payable(msg.sender).transfer(ownerShare);
        payable(dev).transfer(devShare);
    }

    function reserve(uint256 num) public onlyOwner {
        require(num <= reserved, "Exceeds reserved fighter supply" );
        for (uint256 i; i < num; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        reserved -= num;
    }
}