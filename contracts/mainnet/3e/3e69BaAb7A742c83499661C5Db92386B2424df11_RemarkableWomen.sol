// SPDX-License-Identifier: GPL-3.0

// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHF        HOFHOFHOFHOF
// HOFHOFHOFHOF      HOF          HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF                   HOFHOFHOFHOF
// HOFHOFHOFHOF                   HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOF      HOFHOFH      HOFHOFHOFHOF
// HOFHOFHOFHOFHOFHOFHOFHOFHOFHOFHHOFHOFHOFHOF

// -----------    House Of First   -----------
// --   Remarkable Women - Rachel Winter    --

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

contract RemarkableWomen is ERC721Enum, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    
    //sale settings
    bool ambassadorMode = true; // switched to false before presale starts
    uint256 public SALE_START_TIMESTAMP = 1643565600; // time when presale starts - NOT FINAL VALUE - TBC
    uint256 public price = 0.06 ether; // NOT FINAL VALUE - TBC
    uint256 public maxSupply = 5000; // NOT FINAL VALUE - TBC
    uint256 public reserved = 300; // 300 NFTs reserved for vault
    uint256 public maxMint = 20; // max per transaction
    uint256 public ambassadorAllowance = 2; // max per ambassador
    uint256 public presaleAllowance = 5; // max per presale address
    bool public salePaused = false;

    // whitelist
    address public constant WHITELIST_SIGNER = 0x333D70087c40b98bAC3C955AcB263213b63D9C1c;
    uint256 public disableWhitelistTimestamp = SALE_START_TIMESTAMP + (86400 * 1); // presale active for 1 day
    mapping(address => uint256) public whitelistPurchases;
    
    string _name = "Remarkable Women";
    string _symbol = "RemarkableWomen";
    string _initBaseURI = "https://houseoffirst.com:1335/remarkablewomen/opensea/";

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address
    
    constructor() ERC721P(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function getWhitelistPurchases(address addr) external view returns (uint256) {
        return whitelistPurchases[addr];
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

    function getPresaleAllowance() public view returns (uint256) {
        if(ambassadorMode) {
            return ambassadorAllowance;
        }
        return presaleAllowance;
    }
    
    /**
     * @dev Gets current NFT Price
     */
    function getNFTPrice() public view returns (uint256) {
        if(ambassadorMode) {
            return 0;
        }
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
            _mint(msg.sender, s + i);
        }
        delete s;
    }

    // whitelist minting
    function whitelistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(!salePaused, "Sale Paused");
        uint256 s = _owners.length;
        require((s + numberOfNfts) <= (maxSupply - reserved), "Exceeds Max Supply");
        require(isWhitelisted(msg.sender, signature), "Address not whitelisted");

        uint256 allowance = presaleAllowance;

        // ambassador minting
        if(ambassadorMode) {
            allowance = ambassadorAllowance;
        }
        // presale minting
        else {
            require(block.timestamp > SALE_START_TIMESTAMP, "Sale has not started");
            require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        }
        require(numberOfNfts > 0 && numberOfNfts <= allowance, "Invalid numberOfNfts");
        require(whitelistPurchases[msg.sender] + numberOfNfts <= allowance, "Exceeds Allocation");

        whitelistPurchases[msg.sender] += numberOfNfts;
        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _mint(msg.sender, s + i);
        }
        delete s;
        delete allowance;
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
                _mint(recipient[i], s++);
            }
        }
        delete s;
    }
    
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setReserved(uint256 _reserved) public onlyOwner {
        reserved = _reserved;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setAmbassadorAllowance(uint256 _newAllowance) public onlyOwner {
        ambassadorAllowance = _newAllowance;
    }

    function setPresaleAllowance(uint256 _newAllowance) public onlyOwner {
        presaleAllowance = _newAllowance;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSalePaused(bool _salePaused) public onlyOwner {
        salePaused = _salePaused;
    }

    function setAmbassadorMode(bool _mode) public onlyOwner {
        ambassadorMode = _mode;
    }
    
    function setDisableWhitelistTimestamp(uint256 _disableWhitelistTimestamp) public onlyOwner {
        disableWhitelistTimestamp = _disableWhitelistTimestamp;
    }

    function setPresaleStartTimestamp(uint256 _timestamp) public onlyOwner {
        SALE_START_TIMESTAMP = _timestamp;
        disableWhitelistTimestamp = SALE_START_TIMESTAMP + (86400 * 1); // presale active for 1 day
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