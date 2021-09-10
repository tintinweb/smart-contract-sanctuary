/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___        
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_       
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_      
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__     
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____    
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________   
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________  
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________ 
        _______\/////////__\///_______\///__\///////////__\///____________*/

contract CxipRegistry {

	address public pa1dProxy;

	function getPA1D () public view returns (address) {
		return pa1dProxy;
	}

	function setPA1D (address proxy) public onlyOwner {
		pa1dProxy = proxy;
	}

	address public pa1dSource;

	function getPA1DSource () public view returns (address) {
		return pa1dSource;
	}

	function setPA1DSource (address source) public onlyOwner {
		pa1dSource = source;
	}

	address public assetProxy;

	function getAsset () public view returns (address) {
		return assetProxy;
	}

	function setAsset (address proxy) public onlyOwner {
		assetProxy = proxy;
	}

	address public assetSource;

	function getAssetSource () public view returns (address) {
		return assetSource;
	}

	function setAssetSource (address source) public onlyOwner {
		assetSource = source;
	}

	address public copyrightProxy;

	function getCopyright () public view returns (address) {
		return copyrightProxy;
	}

	function setCopyright (address proxy) public onlyOwner {
		copyrightProxy = proxy;
	}

	address public copyrightSource;

	function getCopyrightSource () public view returns (address) {
		return copyrightSource;
	}

	function setCopyrightSource (address source) public onlyOwner {
		copyrightSource = source;
	}

	address public provenanceProxy;

	function getProvenance () public view returns (address) {
		return provenanceProxy;
	}

	function setProvenance (address proxy) public onlyOwner {
		provenanceProxy = proxy;
	}

	address public provenanceSource;

	function getProvenanceSource () public view returns (address) {
		return provenanceSource;
	}

	function setProvenanceSource (address source) public onlyOwner {
		provenanceSource = source;
	}

	address public identitySource;

	function getIdentitySource () public view returns (address) {
		return identitySource;
	}

	function setIdentitySource (address source) public onlyOwner {
		identitySource = source;
	}

	address public erc721CollectionSource;

	function getERC721CollectionSource () public view returns (address) {
		return erc721CollectionSource;
	}

	function setERC721CollectionSource (address source) public onlyOwner {
		erc721CollectionSource = source;
	}

	address public erc1155CollectionSource;

	function getERC1155CollectionSource () public view returns (address) {
		return erc1155CollectionSource;
	}

	function setERC1155CollectionSource (address source) public onlyOwner {
		erc1155CollectionSource = source;
	}

	address public assetSigner;

	function getAssetSigner () public view returns (address) {
		return assetSigner;
	}

	function setAssetSigner (address source) public onlyOwner {
		assetSigner = source;
	}

	mapping (bytes32 => address) public customSources;

	function getCustomSource (bytes32 name) public view returns (address) {
		return customSources [name];
	}

	function getCustomSourceFromString (string memory name) public view returns (address) {
		return customSources [sha256 (abi.encodePacked (name))];
	}

	function setCustomSource (string memory name, address source) public onlyOwner {
		customSources [sha256 (abi.encodePacked (name))] = source;
	}

	event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

	address private _owner;

	constructor () {
		_setOwner (tx.origin);
	}

	function _msgSender () internal view returns (address) {
		return msg.sender;
	}

	function owner () public view returns (address) {
		return _owner;
	}

	modifier onlyOwner () {
		require (owner () == _msgSender (), 'Ownable: caller is not the owner');
		_;
	}

	function renounceOwnership () public onlyOwner {
		_setOwner (address (0));
	}

	function transferOwnership (address newOwner) public onlyOwner {
		require (newOwner != address (0), 'Ownable: new owner is the zero address');
		_setOwner (newOwner);
	}

	function _setOwner (address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred (oldOwner, newOwner);
	}

}