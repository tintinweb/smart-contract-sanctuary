// SPDX-License-Identifier: U-U-U-UPPPP
pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./ERC1155TokenReceiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract NFTForge is ERC1155TokenReceiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC1155 public NftToken;
    uint256 public upgradeCost;

    uint256 public commonArtId;
    uint256 public rareArtId;

    event Upgraded(address UpgradedBy);

    function setNFTsAndCost(uint256 _commonArtId, uint256 _rareArtId, uint256 _upgradeCost, IERC1155 _nftToken) public onlyOwner {
        commonArtId = _commonArtId;
        rareArtId = _rareArtId;
        upgradeCost = _upgradeCost;
        NftToken = _nftToken;
    }

    function UpgradeNFT() public {
        address upgrading = msg.sender;
        NftToken.safeTransferFrom(upgrading, address(this), commonArtId, upgradeCost, "");
        NftToken.safeTransferFrom(address(this), upgrading, rareArtId, 1, "");
        NftToken.safeTransferFrom(address(this), owner(), commonArtId, 1, "");
        NftToken.burn(address(this), commonArtId, upgradeCost.sub(1));
        emit Upgraded(msg.sender);
    }

    function recoverNFTs() public onlyOwner() {
        uint256 amountRemaining = NftToken.balanceOf(address(this), rareArtId);
        NftToken.safeTransferFrom(address(this), owner(), rareArtId, amountRemaining, "");
    }

    function recoverTokens(IERC20 token) public onlyOwner() 
    {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

}