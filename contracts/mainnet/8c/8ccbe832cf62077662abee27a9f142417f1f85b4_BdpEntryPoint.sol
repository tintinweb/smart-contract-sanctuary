pragma solidity ^0.4.19;

// File: contracts/BdpBaseData.sol

contract BdpBaseData {

	address public ownerAddress;

	address public managerAddress;

	address[16] public contracts;

	bool public paused = false;

	bool public setupCompleted = false;

	bytes8 public version;

}

// File: contracts/libraries/BdpContracts.sol

library BdpContracts {

	function getBdpEntryPoint(address[16] _contracts) pure internal returns (address) {
		return _contracts[0];
	}

	function getBdpController(address[16] _contracts) pure internal returns (address) {
		return _contracts[1];
	}

	function getBdpControllerHelper(address[16] _contracts) pure internal returns (address) {
		return _contracts[3];
	}

	function getBdpDataStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[4];
	}

	function getBdpImageStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[5];
	}

	function getBdpOwnershipStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[6];
	}

	function getBdpPriceStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[7];
	}

}

// File: contracts/BdpEntryPoint.sol

contract BdpEntryPoint is BdpBaseData {

	function () payable public {
		address _impl = BdpContracts.getBdpController(contracts);
		require(_impl != address(0));
		bytes memory data = msg.data;

		assembly {
			let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
			let size := returndatasize
			let ptr := mload(0x40)
			returndatacopy(ptr, 0, size)
			switch result
			case 0 { revert(ptr, size) }
			default { return(ptr, size) }
		}
	}

	function BdpEntryPoint(address[16] _contracts, bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		contracts = _contracts;
		setupCompleted = true;
		version = _version;
	}

}