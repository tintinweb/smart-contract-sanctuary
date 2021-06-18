// SPDX-License-Identifier: U-U-U-UPPPP
pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./ERC1155TokenReceiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract NFTClaimStation is ERC1155TokenReceiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC1155 public nftToken;

    uint256 public artId;
    uint256 public recoverUnclaimedNftTime;

    mapping (address => bool) public eligibleUsers;

    event ClaimedNFT(address ClaimedBy);

    constructor(uint256 _artId, IERC1155 _nftToken) public {
        artId = _artId;
        nftToken = _nftToken;        
    }

    function setRecoverUnclaimedNftTime() public onlyOwner {  
        recoverUnclaimedNftTime = block.timestamp + 696969; //you will have 8 days to claim, unclaimed NFTs will be shattered into a million pieces
    }

    function setClaimAddresses(address[] memory addresses) public onlyOwner {  
        for (uint i = 0; i < addresses.length; i++) {
            eligibleUsers[addresses[i]] = true;
        }
    }

    function claimNFT() public {
        address claimer = msg.sender;
        require(eligibleUsers[claimer], "Not eligible or your address has not been added yet" );
        require(nftToken.balanceOf(address(this), artId) > 0, "NFTs not yet added");
        nftToken.safeTransferFrom(address(this), claimer, artId, 1, "");
        eligibleUsers[claimer] = false;
        emit ClaimedNFT(claimer);
    }

    function recoverUnclaimedNFTs() public onlyOwner {
        require (block.timestamp > recoverUnclaimedNftTime);
        uint256 amountRemaining = nftToken.balanceOf(address(this), artId);
        nftToken.safeTransferFrom(address(this), owner(), artId, amountRemaining, "");
    }

    function recoverTokens(IERC20 token) public onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}