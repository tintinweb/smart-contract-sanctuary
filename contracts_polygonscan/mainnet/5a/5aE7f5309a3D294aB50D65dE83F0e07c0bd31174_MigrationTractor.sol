// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IMigrationTractor.sol";
import "./IHonestFarmerClubV2.sol";
import "./IRegistryFarmer.sol";

contract MigrationTractor is IMigrationTractor, ERC1155Holder, Ownable {
	using Counters for Counters.Counter;

	event Migrate(uint256 indexed tokenId, address indexed owner);

	IRegistryFarmer public registryFarmer;

	uint256 public constant PRE_MIGRATION_TOKEN_COUNT = 441;
	Counters.Counter private _migrationCount;

	mapping(uint256 => bool) public isMigratedByTokenId;

	constructor(IRegistryFarmer _registryFarmer) {
		registryFarmer = _registryFarmer;
	}

	modifier isValidMigration(uint256[] memory ids) {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];

			require(
				id >= 1 && id <= PRE_MIGRATION_TOKEN_COUNT,
				"Invalid token id"
			);
			require(!isMigratedByTokenId[id], "Farmer already migrated");
		}
		_;
	}

	function _migrateFarmers(address to, uint256[] memory ids)
		private
		isValidMigration(ids)
	{
		IHonestFarmerClubV2 honestFarmerClubv2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];

			isMigratedByTokenId[id] = true;
			_migrationCount.increment();
			emit Migrate(id, msg.sender);
		}

		honestFarmerClubv2.migrateFarmers(to, ids);
	}

	function migrateFarmers(uint256[] memory ids) public {
		IHonestFarmerClubV1 honestFarmerClubV1 = IHonestFarmerClubV1(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV1
			)
		);
		require(
			honestFarmerClubV1.isApprovedForAll(msg.sender, address(this)),
			"Not approved"
		);

		uint256[] memory amounts = new uint256[](ids.length);
		for (uint256 i; i < ids.length; i++) {
			amounts[i] = 1;
		}

		honestFarmerClubV1.safeBatchTransferFrom(
			msg.sender,
			address(this),
			ids,
			amounts,
			""
		);

		_migrateFarmers(msg.sender, ids);
	}

	function emergencyMigrateFarmers(uint256[] memory ids, address to)
		public
		onlyOwner
	{
		_migrateFarmers(to, ids);
	}

	function migrationCount() public view returns (uint256) {
		return _migrationCount.current();
	}
}