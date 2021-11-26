/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract PocGenericEthV1 {

    // Declaring a structure
    struct FakeBankAccountStruct {
        uint id;
        string name;
        address[][] accounts;
        uint256[][] balance;
        bool[][] freeze;
    }

    // Enum representing shipping status
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    bool public boo = false;

    uint storedData;
    uint8 u8 = 0;
    uint128 u128 = 0;
    uint256 u256 = 0;

    Status public status = Status.Pending;

    // Mapping from address to uint
    mapping(address => FakeBankAccountStruct) public fakeBankAccountMap;

    // Mapping from address to uint
    mapping(address => uint) public myMap;

    int8 i8 = 0;
    int128 i128 = 0;
    int256 i256 = 0;

    address[] array1Daddress;
    address[][] array2Daddress;
    address[][][][] array4Daddress; //max 4 -> more than this we need go for struct

    uint256[][] array2Duint256;
    uint256[][][][] array4Duint256;

    function setValSD(uint x) public {
        storedData = x;
    }

    // Update status by passing uint into input
    function set(Status _status) public {
        status = _status;
    }

    // Update status by passing uint into input
    function set(bool iboo) public {
        boo = iboo;
    }

    //contract polymorphism strategy
    function set(uint8 iu8, uint128 iu128, uint256 iu256) public {
        u8 = iu8;
        u128 = iu128;
        u256 = iu256;
    }

    function set(uint256 iu256, uint128 iu128, uint8 iu8) public {
        u8 = iu8;
        u128 = iu128;
        u256 = iu256;
    }

    function set(int8 ii8, int128 ii128, int256 ii256) public {
        i8 = ii8;
        i128 = ii128;
        i256 = ii256;
    }

    function set(int256 ii256, int128 ii128, int8 ii8) public {
        i8 = ii8;
        i128 = ii128;
        i256 = ii256;
    }

    function setArray1Daddress(address[] memory iarray1Daddress) public {
        array1Daddress = iarray1Daddress;
    }

    function setArray2Daddress(address[][] memory iarray2Daddress) public {
        array2Daddress = iarray2Daddress;
    }

    function setarray4Daddress(address[][][][] memory iarray4Daddress) public {
        array4Daddress = iarray4Daddress;
    }

    function setArray2Duint256(uint256[][] memory iarray2Duint256) public {
        array2Duint256 = iarray2Duint256;
    }

    function setArray4Duint256(uint256[][][][] memory iarray4Duint256) public {
        array4Duint256 = iarray4Duint256;
    }

    function set_bank_account_details(address _addr, FakeBankAccountStruct memory _fakeBank) public {
        fakeBankAccountMap[_addr] = _fakeBank;
    }

    function set(address _addr, uint _i) public {
        // Update the value at this address
        myMap[_addr] = _i;

        require(
            _i != 0,
            "The position 0 is reserved, operation not allowed"
        );
    }

    function getValSD() public view returns (uint) {
        return storedData;
    }

    function getStatus() public view returns (Status) {
        return status;
    }

    function getBool() public view returns (bool) {
        return boo;
    }

    function getIntegers() public view returns (int8, int128, int256) {
        return (i8, i128, i256);
    }

    function getUIntegers() public view returns (uint8, uint128, uint256) {
        return (u8, u128, u256);
    }

    function getArray1Daddress() public view returns (address[] memory) {
        return array1Daddress;
    }

    function getArray2Daddress() public view returns (address[][] memory) {
        return array2Daddress;
    }

    function getarray4Daddress() public view returns (address[][][][] memory) {
        return array4Daddress;
    }

    function getArray2Duint256() public view returns (uint256[][] memory) {
        return array2Duint256;
    }

    function getArray4Duint256() public view returns (uint256[][][][] memory) {
        return array4Duint256;
    }

    function get(address _addr) public view returns (uint) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return myMap[_addr];
    }

    function get_bank_account_details(address _addr) public view returns (FakeBankAccountStruct memory) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return fakeBankAccountMap[_addr];
    }

    function remove_account_details(address _addr) public {
        // Reset the value to the default value.
        delete fakeBankAccountMap[_addr];
    }

    function remove(address _addr) public {
        // Reset the value to the default value.
        delete myMap[_addr];
    }

}