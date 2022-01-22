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
    string public baseURI1;
    string public baseURI2;
    string public baseURI3;
    string public baseURI4;
    string public baseURI5;
    string public baseURI6;
    string public baseURI7;

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
	uint256[] claimE1; 	uint256[] mintedE1;
	uint256[] claimE2; 	uint256[] mintedE2;
	uint256[] claimE3; 	uint256[] mintedE3;
	uint256[] claimE4; 	uint256[] mintedE4;
	uint256[] claimE5; 	uint256[] mintedE5;
	uint256[] claimE6; 	uint256[] mintedE6;
	uint256[] claimE7; 	uint256[] mintedE7;

	//shares
	address[] private addressList = [
	0x575D9b550006998B2A64FbC5EB1Bf0aC9e4a918b];
	uint[] private shareList = [100];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	address mintpassContractAddress
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
		mintpass = MINTPASS(mintpassContractAddress);
	}

	//check if claim
	function checkE1(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE1.length; i++) {
        if (claimE1[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE1minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE1.length; i++) {
        if (mintedE1[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE2(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE2.length; i++) {
        if (claimE2[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE2minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE2.length; i++) {
        if (mintedE2[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE3(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE3.length; i++) {
        if (claimE3[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE3minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE3.length; i++) {
        if (mintedE3[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE4(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE4.length; i++) {
        if (claimE4[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE4minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE4.length; i++) {
        if (mintedE4[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE5(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE5.length; i++) {
        if (claimE5[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE5minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE5.length; i++) {
        if (mintedE5[i] == n) {
            return true;
    }
    }
    return false;
	}

	function checkE6(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE6.length; i++) {
        if (claimE6[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE6minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE6.length; i++) {
        if (mintedE6[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE7(uint256 n) private view returns (bool) {
    for (uint256 i = 0; i < claimE7.length; i++) {
        if (claimE7[i] == n) {
            return true;
    }
    }
    return false;
	}
	function checkE7minted(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < mintedE7.length; i++) {
        if (mintedE7[i] == n) {
            return true;
    }
    }
    return false;
	}
	

	function startingIndex() public onlyOwner {
	uint tokenID = 0;
	_safeMint(msg.sender, tokenID, "");
	}

	// editon1
	function freeclaimEdition1(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition1, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE1minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE1.push(s);
	delete s;
	mintedE1.push(tokenID);
	}

	// editon2
	function freeclaimEdition2(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition2, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE2minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE2.push(s);
	delete s;
	mintedE2.push(tokenID);
	}

	// editon3
	function freeclaimEdition3(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition3, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE3minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE3.push(s);
	delete s;
	mintedE3.push(tokenID);
	}

	// editon4
	function freeclaimEdition4(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition4, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE4minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE4.push(s);
	delete s;
	mintedE4.push(tokenID);
	}

	// editon5
	function freeclaimEdition5(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition5, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE5minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE5.push(s);
	delete s;
	mintedE5.push(tokenID);
	}

	// editon6
	function freeclaimEdition6(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition6, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE6minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE6.push(s);
	delete s;
	mintedE6.push(tokenID);
	}

	// editon7
	function freeclaimEdition7(uint256 tokenID) public {
	uint256 s = totalSupply();
	require(statusEdition7, "Mint pass is not active" );
	require(mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checkE7minted(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	claimE7.push(s);
	delete s;
	mintedE7.push(tokenID);
	}

	//read metadata
	function _baseURI1() internal view virtual returns (string memory) {
	return baseURI1;
	}
		//read metadata
	function _baseURI2() internal view virtual returns (string memory) {
	return baseURI2;
	}
		//read metadata
	function _baseURI3() internal view virtual returns (string memory) {
	return baseURI3;
	}
		//read metadata
	function _baseURI4() internal view virtual returns (string memory) {
	return baseURI4;
	}
		//read metadata
	function _baseURI5() internal view virtual returns (string memory) {
	return baseURI5;
	}
		//read metadata
	function _baseURI6() internal view virtual returns (string memory) {
	return baseURI6;
	}
		//read metadata
	function _baseURI7() internal view virtual returns (string memory) {
	return baseURI7;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(_exists(tokenId));
	if(tokenId == 0){
		string memory currentBaseURI = _baseURI1();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE1(tokenId)){
		string memory currentBaseURI = _baseURI1();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE2(tokenId)){
		string memory currentBaseURI = _baseURI2();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE3(tokenId)){
	string memory currentBaseURI = _baseURI3();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE4(tokenId)){
	string memory currentBaseURI = _baseURI4();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE5(tokenId)){
	string memory currentBaseURI = _baseURI5();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else if(checkE6(tokenId)){
	string memory currentBaseURI = _baseURI6();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	else{
		string memory currentBaseURI = _baseURI7();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
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

	//write metadata
	function setURI1(string memory _newBaseURI) public onlyOwner {
	baseURI1 = _newBaseURI;
	}
	function setURI2(string memory _newBaseURI) public onlyOwner {
	baseURI2 = _newBaseURI;
	}
	function setURI3(string memory _newBaseURI) public onlyOwner {
	baseURI3 = _newBaseURI;
	}
	function setURI4(string memory _newBaseURI) public onlyOwner {
	baseURI4 = _newBaseURI;
	}
	function setURI5(string memory _newBaseURI) public onlyOwner {
	baseURI5 = _newBaseURI;
	}
	function setURI6(string memory _newBaseURI) public onlyOwner {
	baseURI6 = _newBaseURI;
	}
	function setURI7(string memory _newBaseURI) public onlyOwner {
	baseURI7 = _newBaseURI;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}