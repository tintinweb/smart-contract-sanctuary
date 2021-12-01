// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract AlienSecretSociety is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public MAX_SUPPLY;
    uint256 public WL_SUPPLY;

    // Whitelist
    mapping(address => uint) public whitelistRedeemed;
    bool public whitelistSaleEnabled; // flags if whitelist sale is enabled or not.
    //    Whitelist One
    bytes32 public whitelist;
    uint256 public whitelistPrice;
    uint256 public whitelistMaxAmount;
    uint256 public redeemedCount;
    
    // Dutch Auction
    mapping(address => uint) public dutchAuctionPurchased;
    bool public dutchAuctionEnabled; // flags if the dutch auction is enabled or not.
    uint256 public dutchAuctionStartPrice; // stores the start price of the token.
    uint256 public dutchAuctionFloorPrice; // stores the min price settable.
    uint256 public dutchAuctionStartTimestamp; // stores timestamp of start of auction. resets after each sale.
    uint256 public dutchAuctionPriceDecreaseBy; // store the value by which to decrease price every tick.
    uint256 public dutchAuctionChangeTick; // (stored: seconds, constructed: minutes) Holds the tick value at which we need to decrease price. 
    uint256 public dutchAuctionLimitPerWallet; // stores limit of tokens allowed to be minted per address/wallet.
    
    // State variables.
    bool public revealed; // flags nfts being revealed
    string baseURI; // initially set to unrevealed URI. Updated on reveal.
    string unreveleadTokenURI; // stores the unrevealed URI.
    
    event DutchAuctionPurchased(uint256 tokenId);

    constructor(
        uint256 whitelistPrice_,
        uint256 whitelistMaxAmount_,
        uint256 dutchAuctionStartPrice_,
        uint256 dutchAuctionFloorPrice_,
        uint256 dutchAuctionPriceDecreaseBy_,
        uint256 dutchAuctionLimitPerWallet_,
        uint256 dutchAuctionChangeTick_,
        string memory unrevealedBaseURI_, 
        string memory unrevealedTokenURI_
    ) ERC721("Alien Secret Society", "A$$"){
        MAX_SUPPLY = 9999;
        WL_SUPPLY = 3000;
       
        // Whitelist
        whitelistSaleEnabled = true;
        whitelistPrice = whitelistPrice_;
        whitelistMaxAmount = whitelistMaxAmount_;
        // // Dutch Auction 
        dutchAuctionEnabled = false;
        dutchAuctionStartPrice = dutchAuctionStartPrice_;
        dutchAuctionFloorPrice = dutchAuctionFloorPrice_;
        dutchAuctionPriceDecreaseBy = dutchAuctionPriceDecreaseBy_;
        dutchAuctionChangeTick = dutchAuctionChangeTick_.mul(60); // storing in seconds.
        dutchAuctionLimitPerWallet = dutchAuctionLimitPerWallet_;
        // URIs
        baseURI = unrevealedBaseURI_;
        unreveleadTokenURI = unrevealedTokenURI_;
    }

    /*********************
     * Public Functions 
     *********************/

    function dutchAuctionCurrentPrice() public view returns (uint256) {
        uint256 delta = block.timestamp - dutchAuctionStartTimestamp;
        uint256 ticks = delta.div(dutchAuctionChangeTick);
        uint256 decrement = dutchAuctionPriceDecreaseBy.mul(ticks);
        if (decrement > dutchAuctionStartPrice) {
            return dutchAuctionFloorPrice; // cannot go lower than the floor price.
        }
        uint256 price = dutchAuctionStartPrice.sub(decrement);
        
        if (price < dutchAuctionFloorPrice) {
            price = dutchAuctionFloorPrice;
        }
        return price;
    }

    function buyNow(uint256 amount) external payable whenNotPaused {
        require(amount >= 1 , "cannot mint 0");
        require(dutchAuctionEnabled == true, "auction is closed");
        require(MAX_SUPPLY >= totalSupply().add(amount), "cannot mint token. maxSupply was reached");
        require(dutchAuctionPurchased[msg.sender].add(amount) <= dutchAuctionLimitPerWallet, "wallet limit reached");
        uint256 priceMultiple=dutchAuctionStartPrice.mul(amount.sub(1));
        uint256 price = dutchAuctionCurrentPrice().add(priceMultiple);

        require(price <= msg.value, "not enough ETH sent");
        
        dutchAuctionPurchased[msg.sender] = dutchAuctionPurchased[msg.sender].add(amount);
    
         for (uint i = 0; i < amount; i++) {
            safeMint(msg.sender);
            emit DutchAuctionPurchased(_tokenIdCounter.current());
        }
        
    }

    function redeem(uint256 amount, bytes32[] calldata proof)
    external payable whenNotPaused
    {
        require(whitelistSaleEnabled == true, "whitelist sale has ended");
        require(amount > 0, "need to mint at least one token");
        require(msg.value != 0, "cannot mint for free");
        require(MAX_SUPPLY >= totalSupply().add(amount), "cannot mint tokens. will go over maxSupply limit");
        require(WL_SUPPLY >= redeemedCount.add(amount), "cannot mint tokens. will go over wlSupply limit");
     
        // Verify caller is on at least one whitelist.
        bool isOnWhitelist = _verify(_leaf(msg.sender, 0), proof);

        require(isOnWhitelist, "address not verified on the whitelist");

        uint256 price = whitelistPrice;
        uint256 maxAmount = whitelistMaxAmount;
        uint256 alreadyRedeemed = whitelistRedeemed[msg.sender];

        require(price != 0, "failed to get token price");
        require(maxAmount != 0, "failed to get caller maxAmount");
        require(alreadyRedeemed.add(amount) <= maxAmount, "tokens minted will go over user limit");
        require(price.mul(amount) <= msg.value, "not enough ETH sent for requested amount of tokens");
        
        //redeemedCount incrementation
        redeemedCount=redeemedCount.add(amount);

    

        for (uint i = 0; i < amount; i++) {
            whitelistRedeemed[msg.sender] = whitelistRedeemed[msg.sender] + 1;
            safeMint(msg.sender);
        }
    }

    /***************************
     * Owner Protected Functions 
     ***************************/

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPresaleLimit(uint256 amount) public onlyOwner {
        WL_SUPPLY = amount;
    }

    function setWhitelist(bytes32 whitelist_) public onlyOwner {
        whitelist = whitelist_;
    }

    function setWhitelistSaleEnabled(bool value) public onlyOwner {
        whitelistSaleEnabled = value;
    }

    function setDutchAuctionEnabled(bool value) public onlyOwner {
        require(whitelistSaleEnabled == false, "whitelist sale needs to be disabled first");
        dutchAuctionStartTimestamp = block.timestamp;
        dutchAuctionEnabled = value;
    }

    function reveal(string memory revealedBaseURI) public onlyOwner {
        //require(revealed == false, "already revealed.");
        baseURI = revealedBaseURI;
        revealed = true;
    }
    
    function mintByOwner(address to, uint256 amount) public onlyOwner {
        require(MAX_SUPPLY >= totalSupply().add(amount), "cannot mint tokens. will go over maxSupply limit");
        for (uint i = 0; i < amount; i++) {
            safeMint(to);
        }
    }

    /*
     * Function to mint all NFTs for giveaway and partnerships
    */
    function mintMultipleByOwner(
        address[] memory _to
    ) 
        public 
        onlyOwner
    {
        require(MAX_SUPPLY >= totalSupply().add(_to.length), "cannot mint tokens. will go over maxSupply limit");
       for(uint256 i = 0; i < _to.length; i++){
       
            safeMint(_to[i]);
            
        }
    }

    /*********************
     * Internal Functions 
     *********************/

    function safeMint(address to) 
    internal whenNotPaused {
        require(MAX_SUPPLY >= totalSupply().add(1), "cannot mint so many tokens. limit will be reached");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        string memory uri = string(abi.encodePacked(uintToString(tokenId), ".json"));
        _setTokenURI(tokenId, uri);
    }

    function _leaf(address account, uint256 amount)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, whitelist, leaf);
    }

    function uintToString(uint256 v) internal pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*************************************************************
     * The following functions are overrides required by Solidity.
    *************************************************************/
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (revealed) {
            string memory uri = super.tokenURI(tokenId);
            return uri;
        } else {
            return unreveleadTokenURI;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}