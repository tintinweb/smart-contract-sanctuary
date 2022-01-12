/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.4.26;



// File: testStorage.sol

contract testStorage {

	uint storeduint1 = 15;
	uint constant constuint = 16;
	uint128 investmentsLimit = 17055;
	uint32 investmentsDeadlineTimeStamp = uint32(now);

	bytes16 string1 = 'test1';
	bytes32 string2 = 'test1236';
	string string3 = 'lets string something';

	mapping (address => uint) uints1;
	mapping (address => DeviceData) structs1;

	uint[] uintarray;
	DeviceData[] deviceDataArray;

	struct DeviceData {
		string deviceBrand;
		string deviceYear;
		string batteryWearLevel;
	}

	function testStorage() {
		address address1 = 0xbccc714d56bc0da0fd33d96d2a87b680dd6d0df6;
		address address2 = 0xaee905fdd3ed851e48d22059575b9f4245a82b04;

		uints1[address1] = 88;
		uints1[address2] = 99;

		var dev1 = DeviceData('deviceBrand', 'deviceYear', 'wearLevel');
		var dev2 = DeviceData('deviceBrand2', 'deviceYear2', 'wearLevel2');

		structs1[address1] = dev1;
		structs1[address2] = dev2;

		uintarray.push(8000);
		uintarray.push(9000);

		deviceDataArray.push(dev1);
		deviceDataArray.push(dev2);
	}
}