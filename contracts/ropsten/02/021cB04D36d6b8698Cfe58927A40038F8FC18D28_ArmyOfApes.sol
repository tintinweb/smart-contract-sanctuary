// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ArmyOfApes is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MINT_PRICE = 218 ether; //218 SGB

    mapping(uint256=>Order) public orders;

    struct Order {
        bool valid;
        uint256 price;
        address owner;
    }

    event NewOrder(uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event OrderCancelled(uint256 indexed _tokenId, address indexed _owner);
    event OrderAccepted(uint256 indexed _tokenId, address indexed _prevOwner, address indexed _newOwner);

    constructor() ERC721("ArmyOfApes", "AOA") {
        for (uint i = 0; i < 20; i++) {
            _safeMint(msg.sender);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://armyofapes.xyz/api/metadata";
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mintApes(uint256 _total) public payable {
        require(_total <= 10, "You can't mint more than 10 apes");
        require(msg.value == MINT_PRICE * _total, "Invalid amount");

        for (uint i = 0; i < _total; i++) {
            _safeMint(msg.sender);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function placeOrder(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId)== msg.sender, "Invalid owner");

        orders[_tokenId].valid = true;
        orders[_tokenId].price = _price;
        orders[_tokenId].owner = msg.sender;
        
        safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NewOrder(_tokenId, msg.sender, _price);
    }

    function cancelOrder(uint256 _tokenId) public {
        require(orders[_tokenId].valid, "Invalid order");
        require(orders[_tokenId].owner == msg.sender, "Invalid owner");
        
        safeTransferFrom(address(this), msg.sender, _tokenId);
        orders[_tokenId].valid = false;

        emit OrderCancelled(_tokenId, msg.sender);
    }

    function acceptOrder(uint256 _tokenId) public payable {
        require(orders[_tokenId].valid, "Invalid order");
        require(orders[_tokenId].owner != msg.sender, "Can't accept self order");
        require(msg.value == orders[_tokenId].price, "Invalid value");

        orders[_tokenId].valid = false;
        
        safeTransferFrom(address(this), msg.sender, _tokenId);
        require(payable(orders[_tokenId].owner).send(msg.value));

        emit OrderAccepted(_tokenId, orders[_tokenId].owner, msg.sender);
    }

    function _withdrawFees() public {
        require(payable(owner()).send(address(this).balance));
    }
}