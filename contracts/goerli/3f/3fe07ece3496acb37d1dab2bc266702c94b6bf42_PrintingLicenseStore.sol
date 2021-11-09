/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.4.2;

/*
 * Contract for the SAMPL HMI demo project.
 * It handles the Solidity part of the use case "n onetime printing licenses".
 */
contract PrintingLicenseStore {

	/*
	 * Structure to hold all information of a license.
	 * A license is always bound to _one_ CAD file which is identified by fileHash.
	 * A license has one ID which is not part of this structure but is used as a key in licenseMap.
	 * The license contains a count to specify how many items may be printed from the CAD file.
	 */
	struct License {
		address from; // licenser
		address to; // licensee
		uint256 fileHash; // SHA-256 hash of the file to print
		uint64 count; // count of licensed items to print
		uint256[] items; // list of items printed with this license
	}

	/**
	 * Structure to hold all information of a printed item.
	 * It its identified by its id (uid/serial number).
	 * It is bound the a license by the licenseId.
	 * The array pass describes the manufacturing passes of the item:
	 * fileHashes and fileKeys are used to identify optional files with process logs
	 */
	struct Item {
		uint256 licenseId;
		uint64[] pass;
		uint256[] fileHashes;
		bytes32[] fileKeys;
	}

	/*
	 * mapping licenseId -> License
	 */
	mapping (uint256 => License) private licenseMap;

	/*
	 * mapping itemId -> Item
	 */
	mapping (uint256 => Item) private itemMap;

	/*
	 * event to monitor the grant of a license
	 */
	event LicenseGrant(
		uint256 indexed _licenseId, 
		address indexed _from, 
		address indexed _to, 
		uint256 _fileHash,
		uint64 _count
	);

	/*
	 * event to monitor the usage of a license
	 */
	event LicenseUse(
		uint256 indexed _licenseId, 
		address indexed _from, 
		address indexed _to, 
		uint256 _fileHash,
		uint64 _count
	);

	/*
	 * event to monitor the pass of an item
	 */
	event ItemPass(
		uint256 indexed _itemId,
		uint256 indexed _licenseId,
		uint64 _pass,
		uint256 _fileHash
	); 

	/*
	 * event to monitor a failure in the license store
	 * _reason: 
	 *   1 - Only the licenser may grant licenses.
	 *   2 - The requested license is not available.
	 *   3 - License Id is already in use.
	 *  10 - UID is already registered.
	 *  11 - Only the licensee may register or pass items.
	 */
	event LicenseStoreFailure(uint8 _reason);

	/*
	 * Ctor
	 */
	function PrintingLicenseStore() public {
	}

	/*
	 * Grant a license.
	 * This is a transactional method.
	 *
	 * id: license id
	 * from: licenser
	 * to: licensee
	 * fileHash: SHA-256 hash of the file
	 * count: count of licensed items
	 */
	function grantLicense(uint256 id, address from, address to, uint256 fileHash, uint64 count) public {
		if (msg.sender != from) {
			// only the licenser may grant
			LicenseStoreFailure(1);
			return;
		}
		License storage lic = licenseMap[id];
		if (lic.count > 0) {
			// license id is alread in use
			LicenseStoreFailure(3);
			return;
		}
		licenseMap[id] = License(from, to, fileHash, count, new uint256[](0));
		LicenseGrant(id, from, to, fileHash, count);
	}

	/* private */
	function _useLicense(uint256 id, uint256 fileHash, uint64 amount) private returns (uint8) {
		License storage lic = licenseMap[id];
		
		uint256 fh;
		if (fileHash == 0) {
		    // demo 3: we dont't have the fileHash yet because the file is encrpyted
			fh = lic.fileHash;
		} else {
		    // backwards compatiblity with demo 1 and 2
		    fh = fileHash;
		}
		
		if (lic.to == msg.sender && lic.fileHash == fh && lic.count >= amount) {
			// ok
			lic.count-=amount;
			licenseMap[id] = lic;
			LicenseUse(id, lic.from, lic.to, lic.fileHash, amount);
			return 0;
		} else {
			// no license available
			LicenseStoreFailure(2);
			return 2;
		}
	}

	/*
	 * Use one license for one item to print.
	 * This is a transcational method.
	 * The method checks if at least one item is available for the combination of
	 * (address_of_caller, id, fileHash). If yes, then the count of available items is decremented.
	 * 
	 * id: license id
	 * fileHash: SHA-256 hash of the file to print
	 */
	function useLicense(uint256 id, uint256 fileHash) public {
		_useLicense(id, fileHash, 1);
	}
	
	/*
	 * Use a number of licenses for one item to print.
	 * This is a transcational method.
	 * The method checks if at least one item is available for the combination of
	 * (address_of_caller, id, fileHash). If yes, then the count of available items is decremented.
	 * 
	 * id: license id
	 * fileHash: SHA-256 hash of the file to print
	 * count: number of licenses to use 
	 */
	function useNumberOfLicenses(uint256 id, uint256 fileHash, uint64 count) public {
		_useLicense(id, fileHash, count);
	}

	/*
	 * Check the file hash for the given license id.
	 * This is a constant method.
	 * 
	 * id: license id
	 * fileHash: SHA-256 hash of the file to print
	 * returns: true if fileHash matches the hash stored in the contract.
	 */
	function checkFileHash(uint256 id, uint256 fileHash) public constant returns(bool) {
		License storage lic = licenseMap[id];
		return (lic.fileHash == fileHash);
	}

	/*
	 * Get the count of available items for the given license id.
	 * This is a constant method.
	 * 
	 * id: license id
	 * returns: count of items still available to print
	 */
	function availableLicenses(uint256 id) public constant returns(uint64) {
		License storage lic = licenseMap[id];
		return lic.count;
	}

	/*
	 * Register the item id (serial number) for a given license.
	 * This is a transcational method.
	 * 
	 * licenseId: license id
	 * itemId: item id (serial number)
	 */
	function registerItem(uint256 licenseId, uint256 itemId) public {
		Item storage item = itemMap[itemId];
		if (item.licenseId != 0) {
			// item already registered
			LicenseStoreFailure(10);
			return;
		}

		License storage lic = licenseMap[licenseId];
		if (msg.sender != lic.to) {
			// only the licensee may register
			LicenseStoreFailure(11);
			return;
		}

		lic.items.push(itemId);
		licenseMap[licenseId] = lic;

		item.licenseId = licenseId;
		item.pass.push(1); // id is registered
		item.fileHashes.push(0); // no fileHash
		item.fileKeys.push(0); // no fileKey
		itemMap[itemId] = item;
		ItemPass(itemId, licenseId, 1, 0);
	}

	/*
	 * Register the uid (serial number) of one item and use one license to print.
	 * This is a transcational method.
	 * The method checks if at least one item is available for the combination of
	 * (address_of_caller, id, fileHash). If yes, then the count of available items is decremented.
	 * 
	 * licenseId: license id
	 * fileHash: SHA-256 hash of the file to print
	 * itemId: item id (serial number)
	 */
	function useLicenseRegisterItem(uint256 licenseId, uint256 fileHash, uint256 itemId) public {
		Item storage item = itemMap[itemId];
		if (item.licenseId != 0) {
			// item already registered
			LicenseStoreFailure(10);
			return;
		}

		if (0 == _useLicense(licenseId, fileHash, 1)) {
			registerItem(licenseId, itemId);
		}
	}

	/*
	 * Pass an item, i.e. register a step in the manufactoring process.
	 * This is a transcational method.
     *
     * itemId: item id (serial number)
	 * pass: manufacturing pass
	 * fhash: SHA-256 hash of an optional file that is associated with the pass (processing logs)
	 * fkey: file key of the optional file
	 */
	function passItem(uint256 itemId, uint64 pass, uint256 fhash, bytes32 fkey) public {
		Item storage item = itemMap[itemId];
		License storage lic = licenseMap[item.licenseId];
		if (msg.sender != lic.to) {
			// only the licensee may pass
			LicenseStoreFailure(11);
			return;
		}
		item.pass.push(pass);
		item.fileHashes.push(fhash);
		item.fileKeys.push(fkey);
		itemMap[itemId] = item;
		ItemPass(itemId, item.licenseId, pass, fhash);
	}	

	/*
	 * Get the item for a given item id.
	 * This is a constant method.
	 * 
	 * id: item id
	 * returns: (item.licenseId, item.pass, item.fileHashes, item.fileKeys)
	 */
	function getItem(uint256 id) public constant returns(uint256, uint64[], uint256[], bytes32[]) {
		Item storage item = itemMap[id];
		return (item.licenseId, item.pass, item.fileHashes, item.fileKeys); 
	}

	/*
	 * Get the items that where registered (printed) with a given license.
	 * This is a constant method.
	 *
	 * licenseId: license id
	 * returns: list of item ids
	 */
	function getItemsOfLicense(uint256 licenseId) public constant returns (uint256[]) {
		License storage lic = licenseMap[licenseId];
		return lic.items;
	}
}