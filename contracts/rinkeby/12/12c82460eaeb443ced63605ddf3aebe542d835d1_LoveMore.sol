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
    string private ipfsUri = "https://ipfs.io/ipfs/";

    // Public constants
    uint256 public constant MAX_SUPPLY = 15000;

    // Public fields
    bool public open = false;

    // This hash is the SHA256 output of the concatenation of the IPFS image hash data for all 15k Ethermore heroes.
    string public constant provenanceHash = "864c593d34087d67879f06fed08808afff24d34308bb61ec42780d90b4d732bf";

    // This contract will then return a decentralised IPFS URI when tokenURI() is called.
    // Once all rounds are complete, lock() will be called to permanently set the URI of every token to the IPFS hosted one.
    string[5] public roundHash;

    // This value will be set by an admin to an IPFS url that will list the hash and CID of all Ethermore heroes.
    string public provenanceURI = "";

    // After all rounds are complete, and provenance records updated, the contract will be locked by an admin and then
    // the state of the contract will be immutable for the rest of time.
    bool public locked = false;

    modifier notLocked() {
        require(!locked, "Contract has been locked");
        _;
    }

    constructor(string memory baseURI)
    ERC721("Ethermore", "ETE")
    {
        _setBaseURI(baseURI);
	ownerMint(1);
    }

    fallback()
    external payable
    {
        uint256 quantity = getQuantityFromValue(msg.value);
        mint(quantity);
    }

    // Public methods
    function mint(uint256 quantity)
    public payable
    {
        require(open, "Ethermore drop not open yet");
        require(quantity > 0, "Quantity must be at least 1");

        // Limit buys to 50 Ethermore
        if (quantity > 50) {
            quantity = 50;
        }

        // Limit buys that exceed MAX_SUPPLY
        if (quantity.add(totalSupply()) > MAX_SUPPLY) {
            quantity = MAX_SUPPLY.sub(totalSupply());
        }

        uint256 price = getPrice(quantity);

        // Ensure enough ETH
        require(msg.value >= price, "Not enough ETH sent");

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

    function getQuantityFromValue(uint256 value)
    public view
    returns (uint256)
    {
        uint256 totalSupply = totalSupply();
        uint256 quantity = 0;
        uint256 priceOfOne = 0;

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (totalSupply >= 2000) {
                priceOfOne = 0.04 ether;
            } else if (totalSupply >= 1000) {
                priceOfOne = 0.01 ether;
            } else {
                priceOfOne = 0.005 ether;
            }

            if (value >= priceOfOne) {
                totalSupply++;
                quantity++;
                value -= priceOfOne;
            } else {
                break;
            }
        }
        return quantity;
    }

    function getPrice(uint256 quantity)
    public view
    returns (uint256)
    {
        require(quantity <= MAX_SUPPLY);

        uint256 totalSupply = totalSupply();
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < quantity; i++) {
            if (totalSupply >= 2000) {
                totalPrice += 0.04 ether;
            } else {
                totalPrice += 0.01 ether;
            }
            totalSupply++;
        }
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
        require(tokenId > 0 && tokenId <= totalSupply(), "URI query for nonexistent token");
        uint256 round;

        if (tokenId > 2000) {
            round = 2;
        } else if (tokenId > 1000) {
            round = 1;
        } else {
            round = 0;
        }

        // Construct IPFS URI or fallback
        if (bytes(roundHash[round]).length > 0) {
            return string(abi.encodePacked(ipfsUri, roundHash[round], "/", tokenId.toString()));
        }

        // Fallback to centralised URI
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    // Admin methods
    function ownerMint(uint256 quantity)
    public onlyOwner
    {
        require(!open, "Owner cannot mint after sale opens");

        for (uint256 i = 0; i < quantity; i++) {
            _mintEthermore(msg.sender);
        }
    }

    function openSale()
    external onlyOwner
    {
        open = true;
    }

    function setBaseURI(string memory newBaseURI)
    external onlyOwner notLocked
    {
        _setBaseURI(newBaseURI);
    }

    function setIpfsURI(string memory _ipfsUri)
    external onlyOwner notLocked
    {
        ipfsUri = _ipfsUri;
    }

    function setRoundHash(uint256 _round, string memory _roundHash)
    external onlyOwner notLocked
    {
        roundHash[_round] = _roundHash;
    }

    function setProvenanceURI(string memory _provenanceURI)
    external onlyOwner notLocked
    {
        provenanceURI = _provenanceURI;
    }

    function lock()
    external onlyOwner
    {
        locked = true;
    }

    function withdrawEther()
    external onlyOwner
    {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
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