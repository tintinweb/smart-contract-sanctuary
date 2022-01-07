// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";

contract MetaStationLSIntermediateNft is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public msnftPrice;

    uint256 public msnftPriceBnb;
    uint256 public msnftPriceBusd;

    address public buyMsNftAddress;

    uint256 public maxMsBuyBnb;
    uint8   public maxMs;

    bool canBuy;

    mapping (address => EnumerableSet.UintSet) private _metasOfUser;

    constructor(
        address buyMsNftAddress_, //received
        uint256 msnftPrice_,
        uint256 msnftPriceBnb_,
        uint256 maxMsBuyBnb_
    ) ERC721("MetaStationLSIntermediateNft", "MetaStationLSIntermediateNft") {
        buyMsNftAddress = buyMsNftAddress_;
        maxMsBuyBnb = maxMsBuyBnb_;
        msnftPrice = msnftPrice_ * 10**uint256(18);
        msnftPriceBnb = msnftPriceBnb_ * 10**uint256(16);
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

    function setCanBuyMsNft(bool canBuy_) external onlyOwner {
        canBuy = canBuy_;
    }

    function setMsnftPriceBnb(uint256 msnftPriceBnb_) external onlyOwner {
        msnftPriceBnb = msnftPriceBnb_;
    }

    function setMsnftPriceBusd(uint256 msnftPriceBusd_) external onlyOwner {
        msnftPriceBusd = msnftPriceBusd_;
    }

    function setMsnftPrice(uint256 msnftPrice_)  external onlyOwner {
        msnftPrice = msnftPrice_;
    }

    function setMaxMsBuyBnb(uint256 maxMsBuyBnb_)  external onlyOwner {
        maxMsBuyBnb = maxMsBuyBnb_;
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