// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AirdropSetting.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract Airdrop is Ownable {
    using SafeMath for uint256;

    IAirdropSetting public AIRDROP_SETTING;

    event AirdropToken(address userAddress, string tokenType, uint256 numberAddress, uint256 totalAmount, uint256 feeAmount);

    constructor(address _airdropSettingAddress) {
        AIRDROP_SETTING = IAirdropSetting(_airdropSettingAddress);
    }

    function airdropMain(
        address[] memory listAddress,
        uint256[] memory listAmount
    ) public payable {

        require(listAddress.length > 0, 'AIRDROP: INVALID LIST ADDRESS');
        require(listAddress.length == listAmount.length, 'AIRDROP: INVALID DATA LENGTH');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < listAmount.length; i++) {
            totalAmount = totalAmount.add(listAmount[i]);
        }
        uint256 amountWithFee = totalAmount.add(AIRDROP_SETTING.getFeeAmount());
        require(msg.value == amountWithFee, 'AIRDROP: INVALID AMOUNT');
        payable(AIRDROP_SETTING.getFeeAddress()).transfer(AIRDROP_SETTING.getFeeAmount());

        for (uint256 i = 0; i < listAddress.length; i++) {
            payable(listAddress[i]).transfer(listAmount[i]);
        }
        emit AirdropToken(msg.sender, "main", listAddress.length, totalAmount, AIRDROP_SETTING.getFeeAmount());
    }

    function airdropToken(
        address tokenAddress,
        address[] memory listAddress,
        uint256[] memory listAmount
    ) public payable {

        require(listAddress.length > 0, 'AIRDROP: INVALID LIST ADDRESS');
        require(listAddress.length == listAmount.length, 'AIRDROP: INVALID DATA LENGTH');
        require(msg.value == AIRDROP_SETTING.getFeeAmount(), 'AIRDROP: INVALID FEE AMOUNT');
        payable(AIRDROP_SETTING.getFeeAddress()).transfer(AIRDROP_SETTING.getFeeAmount());

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < listAmount.length; i++) {
            totalAmount = totalAmount.add(listAmount[i]);
        }
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(tokenBalance >= totalAmount, "AIRDROP: INVALID SENDER BALANCE");
        for (uint256 i = 0; i < listAddress.length; i++) {
            TransferHelper.safeTransferFrom(tokenAddress, address(msg.sender), listAddress[i], listAmount[i]);
        }
        emit AirdropToken(msg.sender, "erc20", listAddress.length, totalAmount, AIRDROP_SETTING.getFeeAmount());
    }

}