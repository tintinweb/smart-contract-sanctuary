/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// File: testStorage.sol

contract testStorage {

	uint public storeduint1 = 15;
	uint constant constuint = 16;
	uint128 public investmentsLimit = 17055;
	uint32 investmentsDeadlineTimeStamp = uint32(block.timestamp);

	bytes16 public string1 = 'test1';
	bytes32 public string2 = 'test1236';

	mapping (address => uint) public uints1;
	mapping (address => DeviceData) public structs1;

	uint[] uintarray;
	DeviceData[] deviceDataArray;

	address address1 = 0xB0aC056995C4904a9cc04A6Cc3a864A9E9A7d3a9;
	address address2 = 0x8b564638825eE7c8893a489D3aa6Bc85E3E6C299;

	struct DeviceData {
		string deviceBrand;
		string deviceYear;
		string batteryWearLevel;
	}

	function testStorage1() public {
		uints1[address1] = 88;
		uints1[address2] = 99;


	}

    function balanceOf1() public view returns (uint) {
        return uints1[address1];
    }

    function balanceOf(address _address) public view returns (uint) {
        return uints1[_address];
    }
}