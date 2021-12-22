// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract farm is Ownable {

    IERC20 public buyLandNFTToken;
    IERC20 public buyMysteryBoxToken;
    IERC721 public landNFTToken;
    address public destroyAddress;
    uint256 public landPrice;

    struct LandInfoSell {
        address sellAddress;
        uint256 landNftPrice;  // tokenId => 土地价格
    }

    constructor (IERC20 _buyLandNFTToken,IERC721 _landNFTToken) public {
        buyLandNFTToken = _buyLandNFTToken;
        landNFTToken = _landNFTToken;
    }

    mapping (uint256 => LandInfoSell) NFTsells;

    event BuyLand(address indexed user, uint256 tokenId);
    event BuyMysteryBox(address indexed user);

    function setBuyLandNFTToken(IERC20 _buyLandNFTToken) public onlyOwner returns(bool) {
        buyLandNFTToken = _buyLandNFTToken;
        return true;
    }

    function setBuyMysteryBoxToken(IERC20 _buyMysteryBoxToken) public onlyOwner returns(bool) {
        buyMysteryBoxToken = _buyMysteryBoxToken;
        return true;
    }

    function setLandNFTToken(IERC721 _landNFTToken) public onlyOwner returns(bool) {
        landNFTToken = _landNFTToken;
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

    // 挂卖土地NFT
    function addSellLandNFT(uint256 tokenId, uint256 _amount) public {
        landNFTToken.transferFrom(address(msg.sender), address(this), tokenId);
        LandInfoSell memory _landInfo = NFTsells[tokenId];
        _landInfo.sellAddress = address(msg.sender);
        _landInfo.landNftPrice = _amount;
    }

    // 购买土地
    function buyLand(uint256 tokenId) public {
        LandInfoSell memory _landInfo = NFTsells[tokenId];
        landNFTToken.transferFrom(address(this), address(msg.sender), tokenId);
        buyLandNFTToken.transferFrom(address(msg.sender), _landInfo.sellAddress, _landInfo.landNftPrice);
        emit BuyLand(msg.sender, tokenId);
    }

    //  购买盲盒
    function buyMysteryBox() public {
        buyLandNFTToken.transferFrom(address(msg.sender), destroyAddress, landPrice);
        emit BuyMysteryBox(msg.sender);
    }
}