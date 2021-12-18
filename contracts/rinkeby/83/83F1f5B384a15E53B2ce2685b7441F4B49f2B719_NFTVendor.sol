// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract NFTVendor is Ownable {
	IERC20 public silver;
	IERC20 public gold;
	uint256 public silverPrice;
	uint256 public goldPrice;
	uint256 public ethPrice;

	IERC721 public nft;
	address public holdingAddress;
	uint256 public nextID = 0;

	constructor(address silverAddress, address goldAddress, uint256 _silverPrice, uint256 _goldPrice, uint256 _ethPrice, address holding, address nftAddress) {
		silver = IERC20(silverAddress);
		gold = IERC20(goldAddress);
		silverPrice = _silverPrice;
		goldPrice = _goldPrice;
		ethPrice = _ethPrice;
		holdingAddress = holding;
		nft = IERC721(nftAddress);
	}

	function buyWithSilver(uint256 amount) public {
		silver.transferFrom(_msgSender(), holdingAddress, amount * silverPrice);
		for (uint256 i = 0; i < amount; i++)
			nft.safeTransferFrom(holdingAddress, _msgSender(), nextID + i, "");
		nextID += amount;
	}

	function buyWithGold(uint256 amount) public {
		gold.transferFrom(_msgSender(), holdingAddress, amount * goldPrice);
		for (uint256 i = 0; i < amount; i++)
			nft.safeTransferFrom(holdingAddress, _msgSender(), nextID + i, "");
		nextID += amount;
	}

	function buyWithEth(uint256 amount) public payable {
		require(msg.value == amount * ethPrice, "Incorrect payment.");
		for (uint256 i = 0; i < amount; i++)
			nft.safeTransferFrom(holdingAddress, _msgSender(), nextID + i, "");
		nextID += amount;
	}

	function setSilverAddress(address silverAddress) public onlyOwner {
		silver = IERC20(silverAddress);
	}

	function setGoldAddress(address goldAddress) public onlyOwner {
		gold = IERC20(goldAddress);
	}

	function setHoldingAddress(address holding) public onlyOwner {
		holdingAddress = holding;
	}

	function setPrices(uint256 _silverPrice, uint256 _goldPrice, uint256 _ethPrice) public onlyOwner {
		silverPrice = _silverPrice;
		goldPrice = _goldPrice;
		ethPrice = _ethPrice;
	}

	function setSilverPrice(uint256 price) public onlyOwner {
		silverPrice = price;
	}

	function setGoldPrice(uint256 price) public onlyOwner {
		goldPrice = price;
	}

	function setEthPrice(uint256 price) public onlyOwner {
		ethPrice = price;
	}

	function setNFT(address nftAddress) public onlyOwner {
		nft = IERC721(nftAddress);
	}

	function setNextID(uint256 id) public onlyOwner {
		nextID = id;
	}
}