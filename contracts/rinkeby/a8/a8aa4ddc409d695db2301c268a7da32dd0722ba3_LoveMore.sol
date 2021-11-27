// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./ERC165.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract LoveMore is Ownable, ERC165, ERC721 {
    // Libraries
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // Private fields
    Counters.Counter private _tokenIds;

    // Public constants
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _price = 0.0007 ether;

    // team
    // x0
    address t1 = 0xfE1b8A59c855355940176D3519f9Dc58f6D8828B;
    // to
    address t2 = 0xfE1b8A59c855355940176D3519f9Dc58f6D8828B;
    // ti
    address t3 = 0xfE1b8A59c855355940176D3519f9Dc58f6D8828B;

    constructor(string memory baseURI)
    ERC721("LoveMoreTest", "LM")
    {
        _setBaseURI(baseURI);
	ownerMint(1);
    }

    fallback()
    external payable
    {
        uint256 quantity = msg.value;
        mint(quantity);
    }

    // Public methods
    function mint(uint256 quantity)
    public payable
    {
        require(quantity > 0, "Quantity must be at least 1");

        // Limit buys that exceed MAX_SUPPLY
        if (quantity.add(totalSupply()) > MAX_SUPPLY) {
            quantity = MAX_SUPPLY.sub(totalSupply());
        }

        uint256 price = getPrice(quantity);

        // Ensure enough ETH
        require(msg.value >= _price, "Not enough ETH sent");

        for (uint256 i = 0; i < quantity; i++) {
            _mintEthermore(msg.sender);
        }

        // Return any remaining ether after the buy
        uint256 remaining = msg.value.sub(price);

        if (remaining > 0) {
            (bool success, ) = msg.sender.call{value: remaining}("");
            require(success);
        }
    }

    function getPrice(uint256 quantity)
    public view
    returns (uint256)
    {
        require(quantity <= MAX_SUPPLY);

        uint256 totalPrice = _price * quantity;

        return totalPrice;
    }

    function tokenOfOwnerPage(address owner, uint256 page)
    external view
    returns (uint256 total, uint256[12] memory Ethermore)
    {
        total = balanceOf(owner);
        uint256 start = page * 12;
        if (total > start) {
            uint256 countOnPage = 12;
            if (total - start < 12) {
                countOnPage = total - start;
            }
            for (uint256 i = 0; i < countOnPage; i ++) {
                Ethermore[i] = tokenOfOwnerByIndex(owner, start + i);
            }
        }
    }

    function tokenURI(uint256 tokenId)
    public view virtual override
    returns (string memory)
    {
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    // Admin methods
    function ownerMint(uint256 quantity)
    public onlyOwner
    {

        for (uint256 i = 0; i < quantity; i++) {
            _mintEthermore(msg.sender);
        }
    }

    function setBaseURI(string memory newBaseURI)
    external onlyOwner
    {
        _setBaseURI(newBaseURI);
    }

    function withdrawEther()
    external onlyOwner
    {
        uint256 _each = address(this).balance / 3;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
    }

    // Private Methods
    function _mintEthermore(address owner)
    private
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
    }
}