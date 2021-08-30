// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeMath.sol";


contract TestNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint8;
	using SafeMath for uint256;
	using Strings for string;
	
	uint public constant MAX_TOKENS = 10000;
	uint public constant MAX_GIVEAWAY_TOKENS = 100;
	uint256 public constant TOKEN_PRICE = 70000000000000000; //0.07ETH

	bool public isStarted = true;
	
	uint public countMintedGiveawayTokens = 0;
	uint public nextTokenId = 0;
	string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("Test NFT", "TNFT") {
		_baseTokenURI = baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _setBaseURI(string memory baseURI) internal virtual {
		_baseTokenURI = baseURI;
	}

	function _baseURI() internal view override returns (string memory) {
		return _baseTokenURI;
	}
    
    function setIsStarted(bool newState) public onlyOwner {
        isStarted = newState;
    }
	
	function getMintedCount() public view returns(uint) {
		return nextTokenId;
	}
	
	function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
		  
			for (uint256 index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
		  
			return result;
		}
	}
    
    function mint(uint256 numTokens) external payable nonReentrant {
		require(isStarted, "Paused or hasn't started");
		require(totalSupply() < MAX_TOKENS, "We've got all");
		require(numTokens > 0 && numTokens <= 20, "Must mint from 1 to 20 NFTs");
		require(totalSupply().add(numTokens) <= MAX_TOKENS.sub(MAX_GIVEAWAY_TOKENS.sub(countMintedGiveawayTokens)), "Can't get more than 10000 NFTs");
		require(msg.value >= TOKEN_PRICE.mul(numTokens), "Not enough ETH for transaction");

		for (uint i = 0; i < numTokens; i++) {
			nextTokenId++;
			_safeMint(msg.sender, nextTokenId);
		}
	}

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "Withdrawal failed");
    }
}