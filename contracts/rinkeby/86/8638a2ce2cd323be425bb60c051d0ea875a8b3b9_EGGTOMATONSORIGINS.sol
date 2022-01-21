// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract MINTPASS {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract EGGTOMATONSORIGINS is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

	MINTPASS private mintpass;

  	//settings
	uint256 private maxSupplyEdition1 = 250;
	uint256 private maxSupplyEdition2 = 250;
	uint256 private maxSupplyEdition3 = 250;
	uint256 private maxSupplyEdition4 = 250;
	uint256 private maxSupplyEdition5 = 250;
	uint256 private maxSupplyEdition6 = 250;
	uint256 private maxSupplyEdition7 = 250;
	uint256 totalS = maxSupplyEdition1 + maxSupplyEdition2 + maxSupplyEdition3 + maxSupplyEdition4 + maxSupplyEdition5 + maxSupplyEdition6 + maxSupplyEdition7;
  	bool public statusEdition1 = false;
	bool public statusEdition2 = false;
	bool public statusEdition3 = false;
	bool public statusEdition4 = false;
	bool public statusEdition5 = false;
	bool public statusEdition6 = false;
	bool public statusEdition7 = false;
	uint256[] storeClaim;

	//shares
	address[] private addressList = [
	0x575D9b550006998B2A64FbC5EB1Bf0aC9e4a918b];
	uint[] private shareList = [100];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI,
	address mintpassContractAddress
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
		mintpass = MINTPASS(mintpassContractAddress);
	}

	//check if claim
	function checktheclaim(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < storeClaim.length; i++) {
        if (storeClaim[i] == n) {
            return true;
    }
    }
    return false;
	}

	function startingIndex() public onlyOwner {
	uint tokenID = 0;
	_safeMint(msg.sender, tokenID, "");
	storeClaim.push(tokenID);
	}

	// editon1
	function freeclaimEdition1(uint256 tokenID) public {
	require(statusEdition1, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenID, "");
	storeClaim.push(tokenID);
	}

	// editon2
	function freeclaimEdition2(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1;
	require(statusEdition2, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	// editon3
	function freeclaimEdition3(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1 + maxSupplyEdition2;
	require(statusEdition3, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	// editon4
	function freeclaimEdition4(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1 + maxSupplyEdition2 + maxSupplyEdition3;
	require(statusEdition4, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	// editon5
	function freeclaimEdition5(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1 + maxSupplyEdition2 + maxSupplyEdition3 + maxSupplyEdition4;
	require(statusEdition5, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	// editon6
	function freeclaimEdition6(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1 + maxSupplyEdition2 + maxSupplyEdition3 + maxSupplyEdition4 + maxSupplyEdition5;
	require(statusEdition6, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	// editon7
	function freeclaimEdition7(uint256 tokenID) public {
	uint256 tokenToMint = tokenID + maxSupplyEdition1 + maxSupplyEdition2 + maxSupplyEdition3 + maxSupplyEdition4 + maxSupplyEdition5 + maxSupplyEdition6;
	require(statusEdition7, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenToMint) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, tokenToMint, "");
	storeClaim.push(tokenToMint);
	}

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(tokenId <= totalS);
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function setEdition1(bool _status) public onlyOwner {
	statusEdition1 = _status;
	}

	function setEdition2(bool _status) public onlyOwner {
	statusEdition2 = _status;
	}

	function setEdition3(bool _status) public onlyOwner {
	statusEdition3 = _status;
	}

	function setEdition4(bool _status) public onlyOwner {
	statusEdition4 = _status;
	}

	function setEdition5(bool _status) public onlyOwner {
	statusEdition5 = _status;
	}

	function setEdition6(bool _status) public onlyOwner {
	statusEdition6 = _status;
	}

	function setEdition7(bool _status) public onlyOwner {
	statusEdition7 = _status;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}