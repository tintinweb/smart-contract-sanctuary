// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract farm is Ownable {

    IERC20 public buyLandNFTToken;      // 购买土地代币
    IERC20 public buyMysteryBoxToken;   // 购买盲盒代币
    IERC721 public landNFTToken;        // 土地NFT
    address public destroyAddress;      // 销毁地址
    uint256 public landPrice;           // 盲盒价格
    uint256 public mysteryBoxAmount;    // 盲盒数量
    uint256 public sellMysteryBoxAmount;    // 已出售盲盒数量
    address public receiveAddress;
    uint256 public isSell;              // 开启售卖

    struct LandInfoSell {
        address sellAddress;
        uint256 landNftPrice;  // tokenId => 土地价格
    }

    constructor (IERC20 _buyLandNFTToken,IERC721 _landNFTToken) public {
        buyLandNFTToken = _buyLandNFTToken;
        landNFTToken = _landNFTToken;
    }

    mapping (uint256 => LandInfoSell) NFTsells;

    event BuyLand(address indexed user, uint256 _tokenId);
    event BuyLand1(address indexed user, uint256 _amount);
    event BuyMysteryBox(address indexed user);
    event AddSellLandNFT(address indexed user,uint256 _tokenId, uint256 _amount);
    event Redemption(address indexed user,uint256 _tokenId);

    function getSellLandInfo(uint256 _tokenId) public view returns (address _sellAddress, uint256 _landNftPrice) {
        LandInfoSell memory landInfoSell = NFTsells[_tokenId];
        _sellAddress = landInfoSell.sellAddress;
        _landNftPrice = landInfoSell.landNftPrice;
    }

    // 平台开启售卖土地
    function openSell() public onlyOwner returns(bool) {
        isSell = 1;
        return true;
    }

    // 平台关闭售卖土地
    function closeSell() public onlyOwner returns(bool) {
        isSell = 0;
        return true;
    }

    // 设置接受地址
    function setReceiveAddress(address _receiveAddress) public onlyOwner returns(bool) {
        receiveAddress = _receiveAddress;
        return true;
    }

    // 设置购买土地的代币
    function setBuyLandNFTToken(IERC20 _buyLandNFTToken) public onlyOwner returns(bool) {
        buyLandNFTToken = _buyLandNFTToken;
        return true;
    }

    // 设置购买盲盒的代币
    function setBuyMysteryBoxToken(IERC20 _buyMysteryBoxToken) public onlyOwner returns(bool) {
        buyMysteryBoxToken = _buyMysteryBoxToken;
        return true;
    }

    // 设置土地NFT Token
    function setLandNFTToken(IERC721 _landNFTToken) public onlyOwner returns(bool) {
        landNFTToken = _landNFTToken;
        return true;
    }

    // 设置土地价格
    function setLandPrice(uint256 _landPrice) public onlyOwner returns(bool) {
        landPrice = _landPrice;
        return true;
    }

    // 设置销毁地址
    function setDestroyAddress(address _destroyAddress) public onlyOwner returns(bool) {
        destroyAddress = _destroyAddress;
        return true;
    }

    /**
     * 土地NFT授权额度
     **/
    function landNFTTokenAllowance(address _from) public view returns (uint256 _currentAllowance) {
        _currentAllowance = buyLandNFTToken.allowance(_from, address(this));
    }

    /**
     * 购买土地Token授权额度
     **/
    function buyLandTokenAllowance(uint256 _tokenId) public view returns (address _approveAddress) {
        _approveAddress = landNFTToken.getApproved(_tokenId);
    }

    // 挂卖土地NFT(交易市场)
    function addSellLandNFT(uint256 _tokenId, uint256 _amount) public {
        landNFTToken.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        LandInfoSell memory _landInfo = NFTsells[_tokenId];
        _landInfo.sellAddress = address(msg.sender);
        _landInfo.landNftPrice = _amount;
        emit AddSellLandNFT(msg.sender, _tokenId, _amount);
    }

    // 赎回土地NFT(交易市场)
    function redemption(uint256 _tokenId) public {
        LandInfoSell memory _landInfo = NFTsells[_tokenId];
        require(_landInfo.sellAddress == address(msg.sender), "redemption: redemption error");

        landNFTToken.transferFrom(address(this), address(msg.sender), _tokenId);
        _landInfo.sellAddress = address(0x0000000000000000000000000000000000000000);
        _landInfo.landNftPrice = 0;
        emit Redemption(msg.sender, _tokenId);
    }

    // 购买土地(交易市场)
    function buyLand(uint256 _tokenId) public {
        LandInfoSell memory _landInfo = NFTsells[_tokenId];
        require(_landInfo.sellAddress == address(0x0000000000000000000000000000000000000000), "buyLand: land error");

        landNFTToken.transferFrom(address(this), address(msg.sender), _tokenId);
        buyLandNFTToken.transferFrom(address(msg.sender), _landInfo.sellAddress, _landInfo.landNftPrice);

        _landInfo.sellAddress = address(0x0000000000000000000000000000000000000000);
        _landInfo.landNftPrice = 0;
        emit BuyLand(msg.sender, _tokenId);
    }

    //  购买盲盒(平台出售)
    function buyMysteryBox() public {
        require(mysteryBoxAmount >= sellMysteryBoxAmount, "buyMysteryBox: Sold out");
        require(isSell == 1, "buyMysteryBox: sell close");
        buyLandNFTToken.transferFrom(address(msg.sender), destroyAddress, landPrice);
        sellMysteryBoxAmount += 1;
        emit BuyMysteryBox(msg.sender);
    }

    // 购买土地(平台出售)
    function buyLand1(uint256 _amount) public {
        require(isSell == 1, "buyLand1: sell close");
        buyLandNFTToken.transferFrom(address(msg.sender), receiveAddress, _amount);
        emit BuyLand1(msg.sender, _amount);
    }
}