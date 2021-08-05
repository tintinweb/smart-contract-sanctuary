// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract LuckyAnimals is ERC721Enumerable, Ownable {
	using SafeMath for uint256;
	
	uint256 public constant MAX_TOKENS = 29; // Full 9009 + 1 zero token
	
    uint256 private _reserved; // Saved for the team and for promotional purposes
	uint256 private _price; // This is currently .02 eth or 2 * 10**16
	uint256 private _startingIndex;
	
	bool public _saleStarted; // Allow for starting/pausing sale
	string public _baseTokenURI;
	
	constructor() ERC721("Lucky Animals Test 6", "LAT6") {
		_reserved = 9;//117;
		_price = 0.02 ether;
		_saleStarted = true;//false;
		setBaseURI("https://luckyanimals.site/api/v1/animals/");
	}
    
	modifier whenSaleStarted() {
		require(_saleStarted, "Sale Stopped");
		_;
	}
	
	// Sale Started
	function startSale() public onlyOwner {
		_saleStarted = true;
	}
	
	//Sale Stopped
	function pauseSale() public onlyOwner {
		_saleStarted = false;
	}
	
	function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }
	
	// Make it possible to change the price
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }
	
	function getReserved() public view returns (uint256) {
        return _reserved;
    }
	
	// Create zero token
	/*function zeroMint() external onlyOwner {
		uint256 totalSupply = totalSupply();
		
		require(totalSupply < 1, "Zero token is created");
		
		_safeMint(owner(), totalSupply + 1);
	}*/
	
    // Allows for the early reservation of 117 lucky animals from the creators for promotional usage
    function takeReserves(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
		
		//require(totalSupply != 0, "Zero token was not created");
        require(_count <= _reserved, "That would exceed the max reserved.");
		
        for (uint256 i; i < _count; i++) {
            _safeMint(owner(), totalSupply + i);
        }
		
		_reserved -= _count;
    }
	
	function mintLuckyAnimals(uint256 _count) external payable whenSaleStarted {
		uint256 totalSupply = totalSupply();
		
		if (_count == 5) {
			_price = _price - _price * 25 / 100;
		} else if (_count == 10) {
			_price = _price - _price * 50 / 100;
		}
		
		//require(totalSupply != 0, "Zero token was not created");
		require(_count < 11, "Exceeds the max token per transaction limit.");
		require(_count + totalSupply <= MAX_TOKENS - _reserved, "A transaction of this size would surpass the token limit.");
        require(totalSupply < MAX_TOKENS, "All tokens have already been minted.");
		require(_count * _price <= msg.value, "The value submitted with this transaction is too low.");
		
		for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
	}
	
	function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
		
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
		
        return tokensId;
    }
	
	function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}