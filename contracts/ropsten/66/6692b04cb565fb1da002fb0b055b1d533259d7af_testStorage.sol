pragma solidity ^0.4.0;

contract testStorage {

	uint storeduint1 = 15;
	uint constant constuint = 16;
	uint128 investmentsLimit = 17055;
	uint32 investmentsDeadlineTimeStamp = uint32(now);

	bytes16 string1 = &#39;test1&#39;;
	bytes32 string2 = &#39;test1236&#39;;
	string string3 = &#39;lets string something&#39;;

	mapping (address => uint) uints1;
	mapping (address => DeviceData) structs1;

	uint[] uintarray;
	DeviceData[] deviceDataArray;

	struct DeviceData {
		string deviceBrand;
		string deviceYear;
		string batteryWearLevel;
	}

	function set() public {
		address address1 = 0xEC7d08f5a982B213A8BAf73B9e89df30656F5880;
		address address2 = 0x6e14b4305FBcaE514feb798f5885c65C3C97F22b;

		uints1[address1] = 88;
		uints1[address2] = 99;

		structs1[address1] = DeviceData(&#39;deviceBrand&#39;, &#39;deviceYear&#39;, &#39;wearLevel&#39;);
		structs1[address2] = DeviceData(&#39;deviceBrand&#39;, &#39;deviceYear&#39;, &#39;wearLevel&#39;);

		uintarray.push(8000);
		uintarray.push(9000);

		deviceDataArray.push( DeviceData(&#39;deviceBrand&#39;, &#39;deviceYear&#39;, &#39;wearLevel&#39;));
		deviceDataArray.push( DeviceData(&#39;deviceBrand&#39;, &#39;deviceYear&#39;, &#39;wearLevel&#39;));
	}

}