// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./TrusteeManagedSC.v0.2.sol";

contract STSToken is
	TrusteeManagedSC
{
	string  public name = "SmartTrust Settlor Token";
	string  public symbol = "STST";
	string  public standard = "SmartTrust Settlor Token v1.1";

	uint256 public settlorID;
	string  public settlorInfoHash;

	// Notarized documents - hash SHA256 -> time of notarization
	mapping(string => uint256) public documentsNotarized;
	// Expiration documents - hash SHA256 -> UNIX timestamp of expiration
	mapping(string => uint256) public documentsExpiration;
	// List of hashes of documents
	string[] public documentsHash;
	// Count of all documents
	uint256 public documentsTotal;

	// Profiling info on contract creation
	uint256 public blockNumber;
	uint256 public creation;

	event SettlorInfoHashUpdate(
		string hashSHA256
	);

	event DocumentNotarize(
		string hashSHA256,
		uint256 expirationTS
	);

	event DocumentRenewExpiration(
		string hashSHA256,
		uint256 expirationTS
	);

	event DocumentRemoveNotarize(
		string hashSHA256
	);

	constructor (uint256 _settlorID, string memory _settlorInfoHash, address[] memory _trustees) public {
		// Add creator to Trustees list
		_trusteeAdd(msg.sender);

		// Add all Trustees of Trust
		for (uint256 i = 0; i < _trustees.length; i++) {
			trusteeAdd(_trustees[i]);
		}

		settlorID = _settlorID;
		settlorInfoHash = _settlorInfoHash;
		documentsTotal = 0;

		blockNumber = block.number;
		creation = now;
	}

	function settlorInfoHashUpdate(string memory _settlorInfoHash)
		public
		onlyTrustee()
	{
		settlorInfoHash = _settlorInfoHash;
		emit SettlorInfoHashUpdate(_settlorInfoHash);
	}

	function documentNotarize(string memory _hashSHA256, uint256 expirationTS)
		public
		onlyTrustee()
	{
		require(documentsNotarized[_hashSHA256] == 0, "Document already notarized");

		documentsNotarized[_hashSHA256] = now;
		documentsExpiration[_hashSHA256] = expirationTS;
		documentsHash.push(_hashSHA256);
		documentsTotal++;

		emit DocumentNotarize(_hashSHA256, expirationTS);
	}

	function documentRenewExpiration(string memory _hashSHA256, uint256 expirationTS)
		public
		onlyTrustee()
	{
		require(documentsNotarized[_hashSHA256] != 0, "Document was not notatrized");

		documentsNotarized[_hashSHA256] = now;
		documentsExpiration[_hashSHA256] = expirationTS;

		emit DocumentRenewExpiration(_hashSHA256, expirationTS);
	}

	function documentRemoveNotarize(string memory _hashSHA256)
		public
		onlyTrustee()
	{
		require(documentsNotarized[_hashSHA256] != 0, "Document was not notarized");

		documentsNotarized[_hashSHA256] = 0;
		documentsExpiration[_hashSHA256] = 0;
		uint256 copy_to = 0;
		for (uint256 i = 0; i < documentsTotal; i++) {
			if (keccak256(abi.encodePacked(documentsHash[i])) == keccak256(abi.encodePacked(_hashSHA256))) {
				delete documentsHash[i];
			} else {
				if (copy_to != i) {
					documentsHash[copy_to] = documentsHash[i];
				}
				copy_to++;
			}
		}
		documentsTotal--;
		emit DocumentRemoveNotarize(_hashSHA256);
	}


}