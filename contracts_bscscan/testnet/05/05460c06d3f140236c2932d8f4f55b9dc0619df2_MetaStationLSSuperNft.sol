// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";

contract MetaStationLSSuperNft is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public msnftPriceBnb;
    uint256 public msnftPriceBusd;

    address public buyMsNftAddress;

    uint256 public maxMsBuyBnb;
    uint256 public maxMsBuyBusd;
    uint8   public maxMs;

    bool canBuy;

    mapping (address => EnumerableSet.UintSet) private _metasOfUser;
    address public  theBusdAddress;

    constructor(
        address buyMsNftAddress_, //received
        address theBusdAddress_,
        uint256 msnftPriceBnb_,
        uint256 msnftPriceBusd_,
        uint256 maxMsBuyBnb_,
        uint256 maxMsBuyBusd_
    ) ERC721("MetaStationLSSuperNft", "MetaStationLSSuperNft") {
        
        buyMsNftAddress = buyMsNftAddress_;
        theBusdAddress = theBusdAddress_;
        maxMsBuyBnb = maxMsBuyBnb_;
        maxMsBuyBusd = maxMsBuyBusd_;
        msnftPriceBnb = msnftPriceBnb_ * 10**uint256(16);
        msnftPriceBusd = msnftPriceBusd_ * 10**uint256(16);

    }

    function buyMetaNftBnb() public payable
    {

        require(canBuy, "MetaStation buying NFT not start");
        require(msg.value == msnftPriceBnb, "Not enough bnb");
        require(totalSupply() <= maxMsBuyBnb, "Buy MetaStation BNB max");

        (bool success, ) = buyMsNftAddress.call{value: msg.value}(new bytes(0));
        _tokenIds.increment();
        uint256 newMetaId = _tokenIds.current();

        _mint(msg.sender, newMetaId);
        _metasOfUser[msg.sender].add(newMetaId);

    }

    function buyMetaNftBusd() public payable
    {

        require(canBuy, "MetaStation buying NFT not start");
        require(msg.value == msnftPriceBusd, "Not enough Busd");
        require(totalSupply() <= maxMsBuyBusd, "Buy MetaStation Busd max");

        IERC20(theBusdAddress).transferFrom(msg.sender, buyMsNftAddress, msg.value);
        _tokenIds.increment();
        uint256 newMetaId = _tokenIds.current();

        _mint(msg.sender, newMetaId);
        _metasOfUser[msg.sender].add(newMetaId);

    }

    function buyMetaNftOwner(uint8 numberOfMeta)
        public onlyOwner
    {
        require(canBuy, "MetaStation buying NFT not start");
        require(numberOfMeta >= 1, "Minimum 1 MetaStation-NFT per time");

        for (uint256 index = 0; index < numberOfMeta; index++) {
            _tokenIds.increment();
            uint256 newMetaId = _tokenIds.current();

            _mint(msg.sender, newMetaId);
            _metasOfUser[msg.sender].add(newMetaId);
            
        }
    }

    function setTheBusdAddress(address theBusdAddress_) external onlyOwner {
        theBusdAddress = theBusdAddress_;
    }

    function setCanBuyMsNft(bool canBuy_) external onlyOwner {
        canBuy = canBuy_;
    }

    function setMsnftPriceBnb(uint256 msnftPriceBnb_) external onlyOwner {
        msnftPriceBnb = msnftPriceBnb_;
    }

    function setMsnftPriceBusd(uint256 msnftPriceBusd_) external onlyOwner {
        msnftPriceBusd = msnftPriceBusd_;
    }

    function setMaxMsBuyBnb(uint256 maxMsBuyBnb_)  external onlyOwner {
        maxMsBuyBnb = maxMsBuyBnb_;
    }

    function setMaxMsBuyBusd(uint256 maxMsBuyBusd_)  external onlyOwner {
        maxMsBuyBusd = maxMsBuyBusd_;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        _metasOfUser[to].add(tokenId);
        _metasOfUser[from].remove(tokenId);
    }

    function handleOutgoing(address to, uint256 amount) external onlyOwner {
        _safeTransferBNB(to, amount);
    }

    function _safeTransferBNB(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    receive() external payable {}
    fallback() external payable {}
}