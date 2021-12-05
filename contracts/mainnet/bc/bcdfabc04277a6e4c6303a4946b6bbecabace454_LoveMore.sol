// SPDX-License-Identifier: MIT
/*
   __                                      
  / /  _____   _____  /\/\   ___  _ __ ___ 
 / /  / _ \ \ / / _ \/    \ / _ \| '__/ _ \
/ /__| (_) \ V /  __/ /\/\ \ (_) | | |  __/
\____/\___/ \_/ \___\/    \/\___/|_|  \___|

Copyright © Tiago Magro 2021
*/
pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract LoveMore is ERC721Enum, Ownable, ReentrancyGuard {
	using Strings for uint256;
	string public baseURI;
	uint256 public _price = 0.07 ether;
	uint256 public maxSupply = 7000;
	uint256 public _reserved = 50;
	bool public _paused = false;
	// --0xTeam--
	// 0xlark
    address t1 = 0x63d229229adeECCF4A0cDCF067CC416E1D21042d;
	// 0xcharity
    address t2 = 0xb0E0F69A80afbcc5D5f5716a5e8edEbbF47CDd67;
	// 0xart
    address t3 = 0x92722f73F4B30412D149a41918aFA1858eDB991c;
	// 0xto
	address t4 = 0x7576bA2d85fB8188B412A59F2F2317408f28317D;
	// 0xr
	address t5 = 0xD84be7ddaa034a096381cA9D7e401074C250688A;
	// 0xw
	address t6 = 0xC6642dc3Bc7f693561AdB38A3f841ED8B7B88565;
	// 0xc
	address t7 = 0xd70C752Cb4f015485D96e5632641a94428f7628F;

	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) ERC721P(_name, _symbol)
	{
	setBaseURI(_initBaseURI);	
	}
	// internal
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}
	function SpreadLove(uint256 _mintAmount) public payable nonReentrant{
		uint256 s = totalSupply();
		require( !_paused,  "Sale paused" );
		require(_mintAmount > 0, "1 Minimum" );		
		require(s + _mintAmount <= maxSupply - _reserved, "Exceeds Max supply" );		
		require(msg.value >= _price * _mintAmount);
		for (uint256 i = 0; i < _mintAmount; ++i) {
			_safeMint(msg.sender, s + i, "");
		}
		delete s;
	}
	function LoveGiveaway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved supply" );
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
        _reserved -= _amount;
    }
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	function setPrice(uint256 _newPrice) public onlyOwner {
		_price = _newPrice;
	}
	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
		maxSupply = _newMaxSupply;
	}
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}
	function setReserved(uint256 _newReserved) public onlyOwner {
        _reserved = _newReserved;
    }
	function pause(bool val) public onlyOwner {
        _paused = val;
    }	
	function HarvestLove()
    external onlyOwner
    {
        uint256 _each = address(this).balance / 20 ;
        require(payable(t1).send(_each * 4));
        require(payable(t2).send(_each * 2));
        require(payable(t3).send(_each * 4));
		require(payable(t4).send(_each * 4));
		require(payable(t5).send(_each * 4));
		require(payable(t6).send(_each * 1));
		require(payable(t7).send(_each * 1));
    }
}