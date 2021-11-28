// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Strings.sol";

contract EGG is ERC1155, Ownable, ERC1155Burnable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_EGG = 10000;
    uint256 public constant MAX_EGG_PER_TX = 20;

    uint256 public constant PRESALE_MAX_EGG_PER_WALLET = 2;

    uint256 public constant PRICE = 0.049 ether;

    address public constant creator1Address =
        0xF6c2D1301d6f98B271c378ffa19a8Ff9a822C2da;

    bool public saleOpen = false;
    bool public presaleOpen = false;

    mapping(address => uint256) private _whitelist;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _presaleMemberTracker;

    event saleStatusChange(bool pause);
    event presaleStatusChange(bool pause);
    string public name;
    string public symbol;
    string public baseTokenURI;

    constructor(string memory baseURI) ERC1155(baseURI) {
        name = "EGG";
        symbol = "EGG";
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_EGG, "Soldout!");
        require(saleOpen, "Sale is not open");
        _;
    }

    modifier presaleIsOpen() {
        require(totalSupply() <= MAX_EGG, "Soldout!");
        require(presaleOpen, "Presale is not open");
        _;
    }

    modifier authorizedToPresale() {
        address wallet = _msgSender();
        bool isAuthorized = _whitelist[wallet] >= 1;
        require(
            isAuthorized,
            "You are not in the whitelist or you already minted the allowed amount"
        );
        _;
    }

    modifier notAuthorizedToPresale() {
        address wallet = _msgSender();
        bool isAuthorized = _whitelist[wallet] >= 1;
        require(
            !isAuthorized,
            "You are not in the whitelist or you already minted the allowed amount"
        );
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply(), "Token not minted yet.");
        return string(abi.encodePacked(baseTokenURI, toString(_tokenId)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Total claimed egg.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalPresaler() public view returns (uint256) {
        return _presaleMemberTracker.current();
    }

    function amIPresaler() public view returns (bool) {
        address wallet = _msgSender();
        return _whitelist[wallet] > 0;
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE * _count;
    }

    function setSaleStatus(bool _isOpen) public onlyOwner {
        saleOpen = _isOpen;
        emit saleStatusChange(saleOpen);
    }

    function setPresaleStatus(bool _isOpen) public onlyOwner {
        presaleOpen = _isOpen;
        emit presaleStatusChange(presaleOpen);
    }

    function setWhitelistBulk(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = PRESALE_MAX_EGG_PER_WALLET;
        }
    }

    function setWhitelist(address addr, uint256 count) external onlyOwner {
        _whitelist[addr] = count;
    }

    function _mintEgg(address _to, uint256 _tokenId) private {
        _mint(_to, _tokenId, 1, "");
        _tokenIdTracker.increment();
    }

    function mintPresale(uint256 _numberOfTokens)
        public
        payable
        presaleIsOpen
        authorizedToPresale
    {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Eggs");
        require(
            _numberOfTokens <= _whitelist[wallet],
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_EGG,
            "Purchase would exceed max supply of Eggs"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            uint256 tokenToMint = totalSupply();
            _mintEgg(wallet, tokenToMint);
            _whitelist[wallet] -= 1;
        }
    }

    function mintSale(uint256 _numberOfTokens) public payable saleIsOpen {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Eggs");
        require(
            _numberOfTokens <= MAX_EGG_PER_TX,
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_EGG,
            "Purchase would exceed max supply of Eggs"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            uint256 tokenToMint = totalSupply();
            _mintEgg(wallet, tokenToMint);
        }
    }

    function reserveEgg(uint256 _numberOfTokens) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _numberOfTokens <= MAX_EGG);
        _mintEgg(owner(), _numberOfTokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator1Address, (balance * 15) / 100);
        _widthdraw(creator1Address, (balance * 42) / 100);
        _widthdraw(creator1Address, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}