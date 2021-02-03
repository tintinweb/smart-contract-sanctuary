// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import './TransferHelper.sol';
import "./ReentrancyGuard.sol";

contract YOLOPresale is ReentrancyGuard{
	using SafeMath for uint256;
	using Address for address;
	uint256 private constant rate = 3285700000000000;
	uint256 private constant presaleAmount = 16428500000000000000000;
	address public immutable YoloToken;
	address payable private immutable owner;
	bool public ended;

	event PresaleEnded(uint256 timestamp);

	event PresaleStart(uint256 timestamp);

	event PurchasedToken(address indexed buyer, uint256 amount);

	constructor(address _YoloToken) {
		ended = false;
		YoloToken = _YoloToken;
		owner = msg.sender;
	}

	modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

	function purchaseYoloToken() external payable nonReentrant returns (uint256) {
		require(!ended, "The presale is ended");
		require(msg.value > 0, "Invalid input ETH amount");

		uint256 currentBalance = IERC20(YoloToken).balanceOf(address(this));
		require(currentBalance > 0, "The presale is ended");
		uint256 amount = msg.value.mul(10**18).div(rate);

		if (amount > currentBalance) {
			amount = currentBalance;
		}

		TransferHelper.safeTransfer(YoloToken, msg.sender, amount);
		msg.sender.transfer(msg.value.sub(amount.mul(rate).div(10**18)));

		emit PurchasedToken(msg.sender, amount);
		return amount;
	}

	function presaleStart() external onlyOwner {
		TransferHelper.safeTransferFrom(YoloToken, msg.sender, address(this), presaleAmount);
		emit PresaleStart(block.timestamp);
	}

	function presaleEnd() external onlyOwner {
		require(!ended, "The presale is already ended");

		ended = true;

		owner.transfer(address(this).balance);
		uint256 currentBalance = IERC20(YoloToken).balanceOf(address(this));
		if (currentBalance > 0) {
			TransferHelper.safeTransfer(YoloToken, owner, currentBalance);
		}

		emit PresaleEnded(block.timestamp);
	}
}