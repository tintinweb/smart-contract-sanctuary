// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721_.sol";

contract iconeeFactory {
    address iconeeOfficialAddress = msg.sender;

    mapping(address => uint256) copyrightHolderIdMap;
    mapping(address => uint256) copyrightHolderIdSupply;
    mapping(address => uint256) copyrightHolderIdPrice;
    mapping(address => address) copyrightHolderContractMap;
    mapping(uint256 => bool) idIsUsed;
    string baseMetadataURI =
        "https://dev-iconee-nft-metadata.s3.ap-northeast-1.amazonaws.com/";

    function newIconee() public returns (address) {
        require(copyrightHolderIdMap[msg.sender] != 0);
        string memory uri = string(
            abi.encodePacked(
                baseMetadataURI,
                Strings.toString(copyrightHolderIdMap[msg.sender]),
                "/"
            )
        );
        iconeeNFT newContract = new iconeeNFT(
            iconeeOfficialAddress,
            msg.sender,
            uri,
            copyrightHolderIdSupply[msg.sender],
            copyrightHolderIdPrice[msg.sender]
        );
        copyrightHolderContractMap[msg.sender] = address(newContract);
        copyrightHolderIdMap[msg.sender] = 0;
        return address(newContract);
    }

    function copyrightHolderIconeeNFTaddress(address _copyrightHolder)
        public
        view
        returns (address)
    {
        return copyrightHolderContractMap[_copyrightHolder];
    }

    function copyrightHolderRegistration(
        address _copyrightHolder,
        uint256 _copyrightHolderID,
        uint256 _copyrightHolderSupply,
        uint256 _copyrightHolderPrice
    ) public {
        require(msg.sender == iconeeOfficialAddress);
        require( idIsUsed[_copyrightHolderID] != true);
        require(1 <= _copyrightHolderSupply);
        require(_copyrightHolderSupply <= 10000);
        require(1000000000000 <= _copyrightHolderPrice); // 0.000001eth
        copyrightHolderIdMap[_copyrightHolder] = _copyrightHolderID;
        copyrightHolderIdSupply[_copyrightHolder] = _copyrightHolderSupply;
        copyrightHolderIdPrice[_copyrightHolder] = _copyrightHolderPrice; // 0.1eth
        idIsUsed[_copyrightHolderID] = true;
    }

    function setBaseMetadataURI(string memory _URI) public {
        require(msg.sender == iconeeOfficialAddress);
        baseMetadataURI = _URI;
    }
}

contract iconeeNFT is ERC721URIStorage, ERC721Enumerable {
    address public owner;
    address iconeeOfficialAddress;

    uint256 public price;
    uint256 iconeeDevide = 0;
    uint256 ownerDevide = 0;
    uint256 public copyrightHolderSupply;

    string base = "";
    bool public isSale = false;
    mapping(uint256 => uint256) public specialPrice;

    event Mint();

    function rangeMint(uint256 _startnum, uint256 _num) public payable {
        uint256 endnum = _startnum + _num - 1;
        require(endnum <= copyrightHolderSupply);
        require(0 < _startnum);
        require(_startnum <= endnum);
        require(isSale);
        for (uint256 i = _startnum; i <= endnum; i++) {
            if (_owners[i] == address(0)) {
                if (specialPrice[i] == 0) {
                    require(msg.value == price);
                } else {
                    require(msg.value == specialPrice[i]);
                }

                iconeeDevide = iconeeDevide + (msg.value / 100);
                ownerDevide = ownerDevide + ((msg.value / 100) * 99);
                _safeMint(msg.sender, i);
                emit Mint();
                return;
            }
        }
        require(false, "rangeMint failed.");
    }

    function checkNFTInventoryCount(uint256 _startnum, uint256 _num)
        public
        view
        returns (uint256)
    {
        uint256 endnum = _startnum + _num - 1;
        require(endnum <= copyrightHolderSupply);
        require(0 < _startnum);
        require(_startnum <= endnum);
        uint256 hitcount = 0;
        for (uint256 i = _startnum; i <= endnum; i++) {
            if (_owners[i] == address(0)) {
                hitcount = hitcount + 1;
            }
        }
        return hitcount;
    }

    function getAllTokenIdOfOwner(address _userAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256 lastIndexId = balanceOf(_userAddress);
        uint256[] memory allTokenIds = new uint256[](lastIndexId);
        if (lastIndexId == 0) {
            return allTokenIds;
        } else {
            for (uint256 i = 0; i < lastIndexId; i++) {
                allTokenIds[i] = tokenOfOwnerByIndex(_userAddress, i);
            }
            return allTokenIds;
        }
    }

    function iconeeWithdraw() public {
        require(msg.sender == iconeeOfficialAddress);
        uint256 amountToWithdraw = iconeeDevide;
        iconeeDevide = 0;
        (bool success, ) = iconeeOfficialAddress.call{value:amountToWithdraw}("");
        require(success, "Transfer failed.");
    }

    function ownerWithdraw() public {
        require(msg.sender == owner);
        uint256 amountToWithdraw = ownerDevide;
        ownerDevide = 0;
        (bool success, ) = owner.call{value:amountToWithdraw}("");
        require(success, "Transfer failed.");
    }

    function giftFromOwner(address _gifted, uint256 _nftid) public {
        require(msg.sender == owner);
        _safeMint(_gifted, _nftid);
    }

    function _baseURI() internal view override returns (string memory) {
        return base;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setRangeSpecialPrice(
        uint256 _startnum,
        uint256 _num,
        uint256 _price
    ) public {
        uint256 endnum = _startnum + _num - 1;
        require(msg.sender == owner || msg.sender == iconeeOfficialAddress);
        require(endnum <= copyrightHolderSupply);
        require(0 < _startnum);
        require(_startnum <= endnum);
        for (uint256 i = _startnum; i <= endnum; i++) {
            specialPrice[i] = _price;
        }
    }

    function setIsSale(bool _isSale) public {
        require(msg.sender == owner || msg.sender == iconeeOfficialAddress);
        isSale = _isSale;
    }

    function setCopyrightHolderSupply(uint256 _copyrightHolderSupply) public {
        require(msg.sender == iconeeOfficialAddress);
        copyrightHolderSupply = _copyrightHolderSupply;
    }

    function setMetadataBaseURI(string memory _URI) public {
        require(msg.sender == iconeeOfficialAddress);
        base = _URI;
    }

    function changeContractOwner(address _to) public {
        require(msg.sender == iconeeOfficialAddress);
        owner = _to;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor(
        address _iconeeOfficialAddress,
        address _copyrightHolderAddress,
        string memory _URI,
        uint256 _supply,
        uint256 _price
    ) ERC721("iconee", "ICONEE") {
        iconeeOfficialAddress = _iconeeOfficialAddress;
        owner = _copyrightHolderAddress;
        base = _URI;
        copyrightHolderSupply = _supply;
        price = _price;
    }
}