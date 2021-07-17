/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Registry {

	address public provenanceProxy;
	address public assetProxy;

	function getProvenance () public view returns (address) {
		return provenanceProxy;
	}

	function setProvenance (address proxy) public onlyOwner {
		provenanceProxy = proxy;
	}

	function getAsset () public view returns (address) {
		return assetProxy;
	}

	function setAsset (address proxy) public onlyOwner {
		assetProxy = proxy;
	}

	address public provenanceSource;
	address public identitySource;
	address public assetSource;
	address public collectionSource;
	address public assetSigner;

	function getProvenanceSource () public view returns (address) {
		return provenanceSource;
	}

	function setProvenanceSource (address source) public onlyOwner {
		provenanceSource = source;
	}

	function getIdentitySource () public view returns (address) {
		return identitySource;
	}

	function setIdentitySource (address source) public onlyOwner {
		identitySource = source;
	}

	function getAssetSource () public view returns (address) {
		return assetSource;
	}

	function setAssetSource (address source) public onlyOwner {
		assetSource = source;
	}

	function getCollectionSource () public view returns (address) {
		return collectionSource;
	}

	function setCollectionSource (address source) public onlyOwner {
		collectionSource = source;
	}

	function getAssetSigner () public view returns (address) {
		return assetSigner;
	}

	function setAssetSigner (address source) public onlyOwner {
		assetSigner = source;
	}

	mapping (bytes32 => address) public customSources;

	function getCustomSource (string memory name) public view returns (address) {
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