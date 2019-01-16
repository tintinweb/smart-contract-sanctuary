/*

 * source       https://github.com/MCROEngineering/zoom/
 * @package     ZoomDev
 * @author      Micky Socaci <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="177a7e747c6e577978607b7e6172396578">[email&#160;protected]</a>>
 * @license     MIT
 
*/

pragma solidity 0.4.25;


contract ItemEntity {

    string private name;
    address private asset;

    constructor(string _name, address _addr) public {
        name = _name;
        asset = _addr;
    }

    function getName() public view returns (string) {
        return name;
    }

    function getAsset() public view returns (address) {
        return asset;
    }

    function getUint8() public pure returns (uint8) {
        return 2**8-1;
    }

    function getUint16() public pure returns (uint16) {
        return 2**16-1;
    }

    function getUint32() public pure returns (uint32) {
        return 2**32-1;
    }
    
    function getUint64() public pure returns (uint64) {
        return 2**64-1;
    }
    
    function getUint128() public pure returns (uint128) {
        return 2**128-1;
    }

    function getUint256() public pure returns (uint256) {
        return 2**256-1;
    }

    function getString8() public pure returns (string) {
        return "12345678";
    }

    function getString16() public pure returns (string) {
        return "1234567812345678";
    }

    function getString32() public pure returns (string) {
        return "12345678123456781234567812345678";
    }

    function getString64() public pure returns (string) {
        return "1234567812345678123456781234567812345678123456781234567812345678";
    }

    function getAddress() public pure returns (address) {
        return 0x0000000000000000000000000000000000000001;
    }

    function getBoolTrue() public pure returns (bool) {
        return true;
    }

    function getBoolFalse() public pure returns (bool) {
        return false;
    }

    function getBytes8() public pure returns (bytes8) {
        return 0x0102030405060708;
    }

    function getBytes16() public pure returns (bytes16) {
        return 0x01020304050607080102030405060708;
    }

    function getBytes32() public pure returns (bytes32) {
        return 0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20;
    }

    function getBytes() public pure returns (bytes memory) {
        bytes memory outputBuffer = new bytes(1);
        assembly {

            let size := 64
            mstore( outputBuffer, size )
            
            for { let n := 0 } lt(n, div(size, 32) ) { n := add(n, 1) } {
                mstore( add ( add (outputBuffer, 32), mul( n, 32) ), 11 )
            }

            // move free memory pointer 
            mstore(0x40, msize()) 

        }
        return outputBuffer;
    }

    function multipleOne( uint8 numVar, bool boolVar, string memory stringVar, bytes8 bytesVar ) public pure returns ( string memory ) {
        numVar = 0;
        boolVar = false;
        bytesVar = "";
        return stringVar;
    }

    function multipleTwo( string memory one, string memory two, string memory three ) public pure returns ( string memory ) {
        two = "";
        three = "";
        return one;
    }
}

contract ListContract {

    address public managerAddress;

    struct Item {
        string name;
        address itemAddress;
        bool    status;
        uint256 index;
    }

    mapping ( uint256 => Item ) public items;
    uint256 public itemNum = 0;

    event EventNewChildItem(string _name, address _address, uint256 _index);

    constructor() public {
        managerAddress = msg.sender;
    }

    function addDummyRecords( uint8 addItems ) external {

        uint256 start = itemNum + 1;
        uint256 max = start + addItems;

        for (uint256 i = start; i < max; i++) {
            ItemEntity newItem = new ItemEntity(appendUintToString("Item Name ", i), addAddress(uint8(i)));
            addItem(newItem.getName(), address(newItem));
        }
    }

    function addItem(string _name, address _address) public {
        require(msg.sender == managerAddress, "Sender must be manager address");

        Item storage child = items[++itemNum];
        child.name = _name;
        child.itemAddress = _address;
        child.status = true;
        child.index = itemNum;

        emit EventNewChildItem(_name, _address, itemNum);
    }

    function getChildStatus( uint256 _childId ) public view returns (bool) {
        Item memory child = items[_childId];
        return child.status;
    }

    // update so that this checks the child status, and only delists IF funding has not started yet.
    function delistChild( uint256 _childId ) public {
        require(items[_childId].status == true && msg.sender == managerAddress, "Item needs to have status true");

        Item storage child = items[_childId];
        child.status = false;
    }

    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        uint w = v;
        while (w != 0) {
            uint remainder = w % 10;
            w = w / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        return string(s);
    }

    function appendUintToString(string inStr, uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        uint w = v;
        while (w != 0) {
            uint remainder = w % 10;
            w = w / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        return string(s);
    }

    function addAddress(uint8 i) internal pure returns (address) {

        bytes memory addrBytes = new bytes(20);
        assembly {
            for { let n := 0 } lt(n, 19 ) { n := add(n, 1) } {
                mstore8( add( add( addrBytes, 32), n), 0x00 )
            }
            mstore8( add( add( addrBytes, 32), 19), i )
        } 
        
        return bytesToAddr(addrBytes);
    }
    
    function bytesToAddr (bytes b) internal pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint256 c = uint256(b[i]);
            uint256 toInc = c * (16 ** ((b.length - i-1) * 2));
            result += toInc;
        }
        return address(result);
    }

}