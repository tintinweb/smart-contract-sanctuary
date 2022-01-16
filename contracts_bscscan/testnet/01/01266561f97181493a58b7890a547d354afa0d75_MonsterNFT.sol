// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

// https://etherscan.io/address/0x219b8ab790decc32444a6600971c7c3718252539

contract MonsterNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public monster_gift_count = 100;
    uint256 public monster_presale_count = 100;
    uint256 public monster_public_count = 800;
    uint256 public monster_max_count = monster_gift_count + monster_presale_count + monster_public_count;

    // sale price
    uint256 public monster_price_st = 100e18;
    uint256 public monster_price_lp = 100e18;

    uint256 public lock_duration = 90 days;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;

    string private _contractURI;
    string private _tokenBaseURI;
    address public artistAddress;

    address public st;
    address public lp;
    address public usdt;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 1;
    bool public presaleLive;
    bool public saleLive;

    struct UserInfo {
        uint256 lpAmount; // lp staked
        uint256 releaseTime;
    }
    // user staking info
    mapping (address => UserInfo) public userInfo;

    constructor(address _st, address _lp, address _usdt) ERC721("Monster NFT", "NFT") {
        st = _st;
        lp = _lp;
        usdt = _usdt;
        artistAddress = msg.sender;
    }

    function setST(address _st) public onlyOwner {
        st = _st;
    }

    function setLP(address _lp) public onlyOwner {
        lp = _lp;
    }

    function setUsdt(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setPrice(uint256 _stPrice, uint256 _lpPrice) public onlyOwner {
        monster_price_st = _stPrice;
        monster_price_lp = _lpPrice;
    }

    function setGiftCount(uint256 _count) public onlyOwner {
        monster_gift_count = _count;

        monster_max_count = monster_gift_count + monster_presale_count + monster_public_count;
    }

    function setPresaleCount(uint256 _count) public onlyOwner {
        monster_presale_count = _count;

        monster_max_count = monster_gift_count + monster_presale_count + monster_public_count;
    }

    function setPublicCount(uint256 _count) public onlyOwner {
        monster_public_count = _count;

        monster_max_count = monster_gift_count + monster_presale_count + monster_public_count;
    }

    function setLockDuration(uint256 value) public onlyOwner {
        lock_duration = value;
    }

    function addToPresaleList(address[] calldata entries) public onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            presalerList[entry] = true;
        }
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            presalerList[entry] = false;
        }
    }

    function getEquivalentLpAmount() public view returns (uint256) {
        // for test
        return 200e18;

        uint256 totalSupply = IBEP20(lp).totalSupply();
        uint256 totalUsdt = IBEP20(usdt).balanceOf(lp);
        return monster_price_lp.mul(totalSupply).div(totalUsdt);
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(!presaleLive, "ONLY_PRESALE");
        require(totalSupply() < monster_max_count, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= monster_public_count, "EXCEED_PUBLIC");

        uint256 lpAmount = getEquivalentLpAmount().mul(tokenQuantity);
        // transfer st
        TransferHelper.safeTransferFrom(st, msg.sender, address(artistAddress), monster_price_st * tokenQuantity);
        // stake lp
        TransferHelper.safeTransferFrom(lp, msg.sender, address(this), lpAmount);
        userInfo[msg.sender].lpAmount = userInfo[msg.sender].lpAmount.add(lpAmount);
        if (userInfo[msg.sender].releaseTime == 0) {
            userInfo[msg.sender].releaseTime = block.timestamp.add(lock_duration);
        }

        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(presalerList[msg.sender], "NOT_QUALIFIED");
        require(totalSupply() < monster_max_count, "OUT_OF_STOCK");
        require(privateAmountMinted + tokenQuantity <= monster_presale_count, "EXCEED_PRIVATE");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");

        uint256 lpAmount = getEquivalentLpAmount().mul(tokenQuantity);
        // transfer st
        TransferHelper.safeTransferFrom(st, msg.sender, address(artistAddress), monster_price_st * tokenQuantity);
        // stake lp
        TransferHelper.safeTransferFrom(lp, msg.sender, address(this), lpAmount );
        userInfo[msg.sender].lpAmount = userInfo[msg.sender].lpAmount.add(lpAmount);
        if (userInfo[msg.sender].releaseTime == 0) {
            userInfo[msg.sender].releaseTime = block.timestamp.add(lock_duration);
        }

        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function withdrawLp() public {
        require(block.timestamp >= userInfo[msg.sender].releaseTime, "time not comes");
        TransferHelper.safeTransfer(lp, msg.sender, userInfo[msg.sender].lpAmount);
        delete userInfo[msg.sender];
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= monster_max_count, "MAX_MINT");
        require(giftedAmount + receivers.length <= monster_gift_count, "GIFTS_EMPTY");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(artistAddress).transfer(address(this).balance * 2 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }

    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setArtistAddress(address addr) external onlyOwner {
        artistAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}