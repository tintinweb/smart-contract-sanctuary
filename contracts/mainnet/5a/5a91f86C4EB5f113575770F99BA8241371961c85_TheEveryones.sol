// SPDX-License-Identifier: GPL-3.0

// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHF        HOFHOFHOFHOF
// HOFHOFHOFHOF      HOF          HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF                   HOFHOFHOFHOF
// HOFHOFHOFHOF           	 	  HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF

// -----------    House Of First   -----------
// -----   The Everyones - Ian Murray    -----

pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TheEveryones is ERC721Enum, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    
    //sale settings
    uint256 public constant SALE_START_TIMESTAMP = 1639504800; // Tuesday Dec 14th 2021 18:00:00 GMT
    uint256 public price = 0.08 ether;
    uint256 public maxSupply = 5000;
    uint256 public reserved = 250; // 250 NFTs reserved for vault
    uint256 public maxMint = 5; // max per transaction
    bool public salePaused = false;

    // whitelist
    address public constant WHITELIST_SIGNER = 0x9Ae97e577C40AE33443917828E4485C6c3894741;
    uint256 public disableWhitelistTimestamp = SALE_START_TIMESTAMP + (86400 * 1); // whitelist active for 1 day
    mapping(address => uint256) public whitelistPurchases;
    
    string _name = "The Everyones";
    string _symbol = "TheEveryones";
    string _initBaseURI = "https://houseoffirst.com:1335/theeveryones/opensea/";

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address
    
    constructor() ERC721P(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }
    
    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }
    
    function mintingHasStarted() public view returns (bool) {
        return block.timestamp > SALE_START_TIMESTAMP;
    }

    function whitelistHasEnded() public view returns (bool) {
        return block.timestamp > disableWhitelistTimestamp;
    }
    
    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    /* whitelist */
    function isWhitelisted(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == WHITELIST_SIGNER;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // public minting
    function mintNFT(uint256 numberOfNfts) public payable nonReentrant {
        require(block.timestamp > disableWhitelistTimestamp, "Public Sale has not started");
        uint256 s = _owners.length;
        require(!salePaused, "Sale Paused");
        require(numberOfNfts > 0 && numberOfNfts <= maxMint, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // whitelist minting
    function whitelistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(block.timestamp > SALE_START_TIMESTAMP, "Sale has not started");
        uint256 s = _owners.length;
        require(!salePaused, "Sale Paused");
        require(numberOfNfts > 0 && numberOfNfts <= maxMint, "Invalid numberOfNfts");
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(whitelistPurchases[msg.sender] + numberOfNfts <= maxMint, "Exceeds Whitelist Allocation");
        require(isWhitelisted(msg.sender, signature), "Address not whitelisted");

        whitelistPurchases[msg.sender] += numberOfNfts;
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // admin minting for reserved NFTs
    function giftNFT(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 s = _owners.length;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity <= maxSupply, "Exceeds Max Supply");
        require(totalQuantity <= reserved, "Exceeds Max Reserved");

        // update remaining reserved count
        reserved -= totalQuantity;

        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSalePaused(bool _salePaused) public onlyOwner {
        salePaused = _salePaused;
    }
    
    function setDisableWhitelistTimestamp(uint256 _disableWhitelistTimestamp) public onlyOwner {
        disableWhitelistTimestamp = _disableWhitelistTimestamp;
    }

    // for transparency regarding ETH raised
    uint256 totalWithdrawn = 0;

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
    /**
     * whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}