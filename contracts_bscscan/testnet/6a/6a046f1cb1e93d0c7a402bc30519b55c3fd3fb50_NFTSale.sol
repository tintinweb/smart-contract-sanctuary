// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract NFTSale is ERC721Enumerable, Ownable {

    uint256 public constant MAX_ELEMENTS = 20;
    uint256 public constant WHITELIST_PRICE = 0.002 ether;
    uint256 public constant PRICE = 0.003 ether;
    uint256 public constant MAX_BUY_NUM = 10;
    uint256 public constant WHITELIST_TOTAL = 10;
    uint256 public whiteListMinted = 0;

    mapping(address => uint256) public whitelistMap;

    bool private PAUSE = true;
    bool public whitelistMintBegin = false;
    bool public publicMintBegine = false;

    string public baseTokenURI;

    event PauseEvent(bool pause);
    event welcomeToMekaVerse(uint256 indexed id);
    mapping(uint256=>uint256) public rarityMap;

    constructor() ERC721("NFT", "symbol") {
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setWhitelistMintBegin(bool _val) public onlyOwner {
        whitelistMintBegin = _val;
    }

    function setPublicMintBegine(bool _val) public onlyOwner {
        publicMintBegine = _val;
    }

    function setRarity(uint256[] calldata _tokenIdList,
        uint256[] calldata _rarityList) public onlyOwner {
        for(uint256 i = 0; i < _tokenIdList.length; i++) {
            rarityMap[_tokenIdList[i]] = _rarityList[i];
        }
    }

    function bulkGetRarity(uint256[] calldata _tokenIdList) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_tokenIdList.length);
        for(uint256 i = 0; i < _tokenIdList.length; i++) {
            result[i] = rarityMap[_tokenIdList[i]];
        }
        return result;
    }

    function updateWhitelist(
        address[] calldata _whiteListUsers,
        uint256[] calldata _mintNum
    ) public onlyOwner {
        require(
            _whiteListUsers.length == _mintNum.length,
            "data must have same length"
        );
        for (uint256 i = 0; i < _whiteListUsers.length; i++) {
            whitelistMap[_whiteListUsers[i]] = _mintNum[i];
        }
    }

    function whitelistMint(uint256 buyNum) public payable saleIsOpen {
        require(whitelistMintBegin || publicMintBegine, "mint not begin!");
        require(
            whitelistMap[msg.sender] >= buyNum,
            "reach whitelist max buy num"
        );
        require(msg.value >= WHITELIST_PRICE * buyNum, "Value below price");

        whitelistMap[msg.sender] -= buyNum;
        address wallet = _msgSender();

        uint256 _tokenId = 0;
        for (uint8 i = 0; i < buyNum; i++) {
            _tokenId = totalSupply() + 1;
            require(_tokenId <= MAX_ELEMENTS, "SALE OUT");
            _safeMint(wallet, _tokenId);
        }
        whiteListMinted += buyNum;
    }

    function publicMint(uint256 buyNum) public payable saleIsOpen {
        require(publicMintBegine, "mint not begin!");
        require(buyNum <= MAX_BUY_NUM, "reach max buy num!");
        require(msg.value >= PRICE * buyNum, "Value below price");

        address wallet = _msgSender();
        uint256 _tokenId = 0;
        for (uint8 i = 0; i < buyNum; i++) {
            _tokenId = totalSupply() + 1;
            require(_tokenId <= MAX_ELEMENTS, "SALE OUT");
            _safeMint(wallet, _tokenId);
        }
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyOwner {
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function getUnsoldTokens(uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](limit);

        for (uint256 i = 0; i < limit; i++) {
            uint256 key = i + offset;
            if (rawOwnerOf(key) == address(0)) {
                tokens[i] = key;
            }
        }

        return tokens;
    }
}