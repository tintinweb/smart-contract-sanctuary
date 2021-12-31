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
    uint256 public boxPrice;           // 盲盒价格
    uint256 public mysteryBoxAmount;    // 盲盒数量
    uint256 public sellMysteryBoxAmount;    // 已出售盲盒数量
    address public receiveAddress;
    uint256 public isSell;              // 开启售卖
    uint256 public blackLandPreSale;    // 黑土地预售数量
    uint256 public redLandPreSale;      // 红土地预售数量
    uint256 public yellowLandPreSale;   // 黄土地预售数量

    uint256 public blackLandSellAmount; // 黑土地已出售数量
    uint256 public redLandSellAmount;   // 红土地已出售数量
    uint256 public yellowLandSellAmount;// 黄土地已出售数量

    uint256 public blackLandPrice;      // 黑土地价格
    uint256 public redLandPrice;        // 红土地价格
    uint256 public yellowLandPrice;     // 黄土地价格


    struct LandInfoSell {
        address sellAddress;
        uint256 landNftPrice;  // tokenId => 土地价格
    }

    constructor (IERC20 _buyLandNFTToken,IERC20 buyMysteryBoxToken,IERC721 _landNFTToken) public {
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

    // 设置土地预售数量
    function setLandSellAmount(uint256 _blackLandPreSale, uint256 _redLandPreSale, uint256 _yellowLandPreSale) public onlyOwner returns(bool) {
        blackLandPreSale = _blackLandPreSale;
        redLandPreSale = _redLandPreSale;
        yellowLandPreSale = _yellowLandPreSale;
        return true;
    }

    // 设置土地出售价格
    function setLandSellPrice(uint256 _blackLandPrice, uint256 _redLandPrice, uint256 _yellowLandPrice) public onlyOwner returns(bool) {
        blackLandPrice = _blackLandPrice;
        redLandPrice = _redLandPrice;
        yellowLandPrice = _yellowLandPrice;
        return true;
    }

    // 盲盒总量
    function setMysteryBoxAmount(uint256 _mysteryBoxAmount) public onlyOwner returns(bool) {
        mysteryBoxAmount = _mysteryBoxAmount;
        return true;
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

    // 设置盲盒价格
    function setBoxPrice(uint256 _boxPrice) public onlyOwner returns(bool) {
        boxPrice = _boxPrice;
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
        landNFTToken.transferFrom(address(msg.sender), address(this), _tokenId);
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
        require(mysteryBoxAmount > sellMysteryBoxAmount, "buyMysteryBox: Sold out");
        require(isSell == 1, "buyMysteryBox: sell close");
        buyLandNFTToken.transferFrom(address(msg.sender), destroyAddress, (boxPrice * 2)/10);
        buyLandNFTToken.transferFrom(address(msg.sender), receiveAddress, (boxPrice * 8)/10);
        sellMysteryBoxAmount += 1;
        emit BuyMysteryBox(msg.sender);
    }

    // 购买土地(平台出售)
    function buyLand1(uint256 _amount) public {
        require(isSell == 1, "buyLand1: sell close");

        if(blackLandPrice == _amount) {
            require(blackLandPreSale > blackLandSellAmount, "buyLand1: Black land sold out");
            blackLandSellAmount += 1;
        }

        if(redLandPrice == _amount) {
            require(redLandPreSale > redLandSellAmount, "buyLand1: Red land sold out");
            redLandSellAmount += 1;
        }
        
        if(yellowLandPrice == _amount) {
            require(yellowLandPreSale > yellowLandSellAmount, "buyLand1: Yellow land sold out");
            yellowLandSellAmount += 1;
        }

        buyLandNFTToken.transferFrom(address(msg.sender), destroyAddress, (_amount * 2)/10);
        buyLandNFTToken.transferFrom(address(msg.sender), receiveAddress, (_amount * 8)/10);
        emit BuyLand1(msg.sender, _amount);
    }
}