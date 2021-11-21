pragma solidity <=8.7.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";

contract LGBTNFT is ERC721, ReentrancyGuard, Ownable {
	uint256 public price = 100000000000000000;
	uint256 public maxSupply = 4869;
	uint256 public currentSupply = 0;
	address public LGBTokenContract;
	uint256 public LGBTokenDropPerMint = 1000000000000;
	uint256 public openAt = 1638554400;

	constructor() ERC721("LGBT NFT", "LGBT+") {
		_setBaseURI(string("https://lgbt-nft.online/meta/"));
	}

	function isOpen() public view returns (bool) {
		if (block.timestamp >= openAt) {
			return true;
		}
		return false;
	}

	function mint() public payable nonReentrant {
		require(isOpen(), "Minting is not yet enabled");
		require(price <= msg.value, "Not enough Ether sent");
		uint256 Count = msg.value/price;
		require(currentSupply < maxSupply, "Minting closed");
		uint256 remaining = maxSupply-currentSupply;
		require(Count <= remaining, "Not enough NFT remaining for this Ether amount");
		for (uint256 i=0; i<Count; i++) {
			_safeMint(msg.sender, currentSupply);
			if (currentSupply < maxSupply/2) {
				ERC20(LGBTokenContract).transfer(msg.sender, LGBTokenDropPerMint);
			}
			currentSupply += 1;
		}
	}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function setLGBTokenContract(address contractAddress) external onlyOwner {
		LGBTokenContract = contractAddress;
	}

	receive() external payable {}
}

interface ERC20 {
	function transfer(address, uint256) external returns (bool);
	function approve(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}