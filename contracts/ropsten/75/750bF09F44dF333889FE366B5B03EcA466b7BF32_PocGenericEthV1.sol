/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.8.7;

contract PocGenericEthV1 {
    // Enum representing shipping status
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    Status public status = Status.Pending;

    bool public boo = false;

    uint storedData;
    uint8 public u8 = 0;
    uint128 public u128 = 0;
    uint256 public u256 = 0;

    address[] public listAddr;

    // Mapping from address to uint
    mapping(address => uint) public myMap;

    int8 public i8 = 0;
    int128 public i128 = 0;
    int256 public i256 = 0;

    function setValSD(uint x) public {
        storedData = x;
    }

    function getValSD() public view returns (uint) {
        return storedData;
    }

    function setListAddr(address[] memory inputListAddr) public {
        listAddr = inputListAddr;
    }

    function set(address _addr, uint _i) public {
        // Update the value at this address
        myMap[_addr] = _i;

        require(
            _i != 0,
            "The position 0 is reserved, operation not allowed"
        );
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
    function set(uint8 iu8, uint128 iu128, uint32 iu256) public {
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

    function get(address _addr) public view returns (uint) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return myMap[_addr];
    }

    function getListAddr() public view returns (address[] memory) {
        return listAddr;
    }

    function remove(address _addr) public {
        // Reset the value to the default value.
        delete myMap[_addr];
    }

}