/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.4.19;


contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils
MIT License
Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if(a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Appends a byte array to the end of the buffer. Resizes if doing so
     *      would exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, bytes data) internal pure returns(buffer memory) {
        if(data.length + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, data.length) * 2);
        }

        uint dest;
        uint src;
        uint len = data.length;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + buffer length + sizeof(buffer length)
            dest := add(add(bufptr, buflen), 32)
            // Update buffer length
            mstore(bufptr, add(buflen, mload(data)))
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, uint8 data) internal pure {
        if(buf.buf.length + 1 > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length)
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, data)
            // Update buffer length
            mstore(bufptr, add(buflen, 1))
        }
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        if(len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length) + len
            let dest := add(add(bufptr, buflen), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length
            mstore(bufptr, add(buflen, len))
        }
        return buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if(value <= 23) {
            buf.append(uint8((major << 5) | value));
        } else if(value <= 0xFF) {
            buf.append(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.append(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.append(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.append(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/*
End solidity-cborutils
 */

contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Android = 0x40;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
      return oraclize_setNetwork();
      networkID; // silence the warning and remain backwards compatible
    }
    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) public {
      return;
      myid; result; proof; // Silence compiler warnings
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    using CBOR for Buffer.buffer;
    function stra2cbor(string[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeString(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeBytes(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
        // Convert from seconds to ledger timer ticks
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            // the following variables can be relaxed
            // check relaxed random contract under ethereum-examples repo
            // for an idea on how to override and replace comit hash vars
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }

        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);

        bytes memory delay_bytes8_left = new bytes(8);

        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }

        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = byte(1); //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;

        require(prefix.length == n_random_bytes);

        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if 'result' is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;


        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

        // verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

        // Buffer too small
        require(to.length >= minLength); // Should be a better way?

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity's ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don't update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can't access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }

}
interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/erc/erc165/ERC165.sol

contract ERC165 is IERC165 {
  /// @dev You must not set element 0xffffffff to true
  mapping (bytes4 => bool) internal supportedInterfaces;

  function ERC165() internal {
    supportedInterfaces[0x01ffc9a7] = true; // ERC-165
  }

  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}

// File: contracts/erc/erc721/IERC721Base.sol

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface IERC721Base /* is IERC165  */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Find the owner of an NFT
  /// @param _tokenId The identifier for an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param _data Additional data with no specified format, sent in call to `_to`
  // solium-disable-next-line arg-overflow
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to []
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  /// @notice Set or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(address _approved, uint256 _tokenId) external payable;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all your asset.
  /// @dev Emits the ApprovalForAll event
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address);

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts/erc/erc721/IERC721Enumerable.sol

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
interface IERC721Enumerable /* is IERC721Base */ {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256);

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

// File: contracts/erc/erc721/IERC721TokenReceiver.sol

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface IERC721TokenReceiver {
  /// @notice Handle the receipt of an NFT
  /// @dev The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. This function MUST use 50,000 gas or less. Return of other
  ///  than the magic value MUST result in the transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _from The sending address
  /// @param _tokenId The NFT identifier which is being transfered
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns (bytes4);
}

// File: contracts/core/dependency/AxieManager.sol

interface AxieSpawningManager {
	function isSpawningAllowed(uint256 _genes, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _axieId, uint256 _genes) external returns (bool);
}

interface AxieRetirementManager {
  function isRetirementAllowed(uint256 _axieId, bool _rip) external returns (bool);
}

interface AxieMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _axieId) external returns (bool);
}

interface AxieGeneManager {
  function isEvolvementAllowed(uint256 _axieId, uint256 _newGenes) external returns (bool);
}

// File: contracts/core/dependency/AxieDependency.sol

contract AxieDependency {

  address public whitelistSetterAddress;

  AxieSpawningManager public spawningManager;
  AxieRetirementManager public retirementManager;
  AxieMarketplaceManager public marketplaceManager;
  AxieGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedGeneScientist;

  function AxieDependency() internal {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _genes, address _owner) {
    require(
      spawningManager == address(0) ||
        spawningManager.isSpawningAllowed(_genes, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _axieId, uint256 _genes) {
    require(
      spawningManager == address(0) ||
        spawningManager.isRebirthAllowed(_axieId, _genes)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _axieId, bool _rip) {
    require(
      retirementManager == address(0) ||
        retirementManager.isRetirementAllowed(_axieId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _axieId) {
    require(
      marketplaceManager == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _axieId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _axieId, uint256 _newGenes) {
    require(
      geneManager == address(0) ||
        geneManager.isEvolvementAllowed(_axieId, _newGenes)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

  /*
   * @dev Setting the whitelist setter address to `address(0)` would be a irreversible process.
   *  This is to lock changes to Axie's contracts after their development is done.
   */
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = AxieSpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = AxieRetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = AxieMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = AxieGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}

// File: contracts/core/AxieAccessControl.sol

contract AxieAccessControl {

  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  function AxieAccessControl() internal {
    ceoAddress = msg.sender;
  }

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      // solium-disable operator-whitespace
      msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == cooAddress
      // solium-enable operator-whitespace
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    cooAddress = _newCOO;
  }

  function withdrawBalance() external onlyCFO {
    cfoAddress.transfer(this.balance);
  }
}

// File: contracts/core/lifecycle/AxiePausable.sol

contract AxiePausable is AxieAccessControl {

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}

// File: zeppelin/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/core/erc721/AxieERC721BaseEnumerable.sol

contract AxieERC721BaseEnumerable is ERC165, IERC721Base, IERC721Enumerable, AxieDependency, AxiePausable {
  using SafeMath for uint256;

  // @dev Total amount of tokens.
  uint256 private _totalTokens;

  // @dev Mapping from token index to ID.
  mapping (uint256 => uint256) private _overallTokenId;

  // @dev Mapping from token ID to index.
  mapping (uint256 => uint256) private _overallTokenIndex;

  // @dev Mapping from token ID to owner.
  mapping (uint256 => address) private _tokenOwner;

  // @dev For a given owner and a given operator, store whether
  //  the operator is allowed to manage tokens on behalf of the owner.
  mapping (address => mapping (address => bool)) private _tokenOperator;

  // @dev Mapping from token ID to approved address.
  mapping (uint256 => address) private _tokenApproval;

  // @dev Mapping from owner to list of owned token IDs.
  mapping (address => uint256[]) private _ownedTokens;

  // @dev Mapping from token ID to index in the owned token list.
  mapping (uint256 => uint256) private _ownedTokenIndex;

  function AxieERC721BaseEnumerable() internal {
    supportedInterfaces[0x6466353c] = true; // ERC-721 Base
    supportedInterfaces[0x780e9d63] = true; // ERC-721 Enumerable
  }

  // solium-disable function-order

  modifier mustBeValidToken(uint256 _tokenId) {
    require(_tokenOwner[_tokenId] != address(0));
    _;
  }

  function _isTokenOwner(address _ownerToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenOwner[_tokenId] == _ownerToCheck;
  }

  function _isTokenOperator(address _operatorToCheck, uint256 _tokenId) private view returns (bool) {
    return whitelistedMarketplace[_operatorToCheck] ||
      _tokenOperator[_tokenOwner[_tokenId]][_operatorToCheck];
  }

  function _isApproved(address _approvedToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenApproval[_tokenId] == _approvedToCheck;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenOwnerOrOperator(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId) || _isTokenOperator(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenAuthorized(uint256 _tokenId) {
    require(
      // solium-disable operator-whitespace
      _isTokenOwner(msg.sender, _tokenId) ||
        _isTokenOperator(msg.sender, _tokenId) ||
        _isApproved(msg.sender, _tokenId)
      // solium-enable operator-whitespace
    );
    _;
  }

  // ERC-721 Base

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokens[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenOwner[_tokenId];
  }

  function _addTokenTo(address _to, uint256 _tokenId) private {
    require(_to != address(0));

    _tokenOwner[_tokenId] = _to;

    uint256 length = _ownedTokens[_to].length;
    _ownedTokens[_to].push(_tokenId);
    _ownedTokenIndex[_tokenId] = length;
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));

    _addTokenTo(_to, _tokenId);

    _overallTokenId[_totalTokens] = _tokenId;
    _overallTokenIndex[_tokenId] = _totalTokens;
    _totalTokens = _totalTokens.add(1);

    Transfer(address(0), _to, _tokenId);
  }

  function _removeTokenFrom(address _from, uint256 _tokenId) private {
    require(_from != address(0));

    uint256 _tokenIndex = _ownedTokenIndex[_tokenId];
    uint256 _lastTokenIndex = _ownedTokens[_from].length.sub(1);
    uint256 _lastTokenId = _ownedTokens[_from][_lastTokenIndex];

    _tokenOwner[_tokenId] = address(0);

    // Insert the last token into the position previously occupied by the removed token.
    _ownedTokens[_from][_tokenIndex] = _lastTokenId;
    _ownedTokenIndex[_lastTokenId] = _tokenIndex;

    // Resize the array.
    delete _ownedTokens[_from][_lastTokenIndex];
    _ownedTokens[_from].length--;

    // Remove the array if no more tokens are owned to prevent pollution.
    if (_ownedTokens[_from].length == 0) {
      delete _ownedTokens[_from];
    }

    // Update the index of the removed token.
    delete _ownedTokenIndex[_tokenId];
  }

  function _burn(uint256 _tokenId) internal {
    address _from = _tokenOwner[_tokenId];

    require(_from != address(0));

    _removeTokenFrom(_from, _tokenId);
    _totalTokens = _totalTokens.sub(1);

    uint256 _tokenIndex = _overallTokenIndex[_tokenId];
    uint256 _lastTokenId = _overallTokenId[_totalTokens];

    delete _overallTokenIndex[_tokenId];
    delete _overallTokenId[_totalTokens];
    _overallTokenId[_tokenIndex] = _lastTokenId;
    _overallTokenIndex[_lastTokenId] = _tokenIndex;

    Transfer(_from, address(0), _tokenId);
  }

  function _isContract(address _address) private view returns (bool) {
    uint _size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data,
    bool _check
  )
    internal
    mustBeValidToken(_tokenId)
    onlyTokenAuthorized(_tokenId)
    whenTransferAllowed(_from, _to, _tokenId)
  {
    require(_isTokenOwner(_from, _tokenId));
    require(_to != address(0));
    require(_to != _from);

    _removeTokenFrom(_from, _tokenId);

    delete _tokenApproval[_tokenId];
    Approval(_from, address(0), _tokenId);

    _addTokenTo(_to, _tokenId);

    if (_check && _isContract(_to)) {
      IERC721TokenReceiver(_to).onERC721Received.gas(50000)(_from, _tokenId, _data);
    }

    Transfer(_from, _to, _tokenId);
  }

  // solium-disable arg-overflow

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable {
    _transferFrom(_from, _to, _tokenId, _data, true);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _transferFrom(_from, _to, _tokenId, "", true);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _transferFrom(_from, _to, _tokenId, "", false);
  }

  // solium-enable arg-overflow

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    payable
    mustBeValidToken(_tokenId)
    onlyTokenOwnerOrOperator(_tokenId)
    whenNotPaused
  {
    address _owner = _tokenOwner[_tokenId];

    require(_owner != _approved);
    require(_tokenApproval[_tokenId] != _approved);

    _tokenApproval[_tokenId] = _approved;

    Approval(_owner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
    require(_tokenOperator[msg.sender][_operator] != _approved);
    _tokenOperator[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return _tokenOperator[_owner][_operator];
  }

  // ERC-721 Enumerable

  function totalSupply() external view returns (uint256) {
    return _totalTokens;
  }

  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < _totalTokens);
    return _overallTokenId[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId) {
    require(_owner != address(0));
    require(_index < _ownedTokens[_owner].length);
    return _ownedTokens[_owner][_index];
  }
}

// File: contracts/erc/erc721/IERC721Metadata.sol

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface IERC721Metadata /* is IERC721Base */ {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external pure returns (string _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external pure returns (string _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string);
}

// File: contracts/core/erc721/AxieERC721Metadata.sol

contract AxieERC721Metadata is AxieERC721BaseEnumerable, IERC721Metadata {
  string public tokenURIPrefix = "https://axieinfinity.com/erc/721/axies/";
  string public tokenURISuffix = ".json";

  function AxieERC721Metadata() internal {
    supportedInterfaces[0x5b5e139f] = true; // ERC-721 Metadata
  }

  function name() external pure returns (string) {
    return "Axie";
  }

  function symbol() external pure returns (string) {
    return "AXIE";
  }

  function setTokenURIAffixes(string _prefix, string _suffix) external onlyCEO {
    tokenURIPrefix = _prefix;
    tokenURISuffix = _suffix;
  }

  function tokenURI(
    uint256 _tokenId
  )
    external
    view
    mustBeValidToken(_tokenId)
    returns (string)
  {
    bytes memory _tokenURIPrefixBytes = bytes(tokenURIPrefix);
    bytes memory _tokenURISuffixBytes = bytes(tokenURISuffix);
    uint256 _tmpTokenId = _tokenId;
    uint256 _length;

    do {
      _length++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    bytes memory _tokenURIBytes = new bytes(_tokenURIPrefixBytes.length + _length + 5);
    uint256 _i = _tokenURIBytes.length - 6;

    _tmpTokenId = _tokenId;

    do {
      _tokenURIBytes[_i--] = byte(48 + _tmpTokenId % 10);
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    for (_i = 0; _i < _tokenURIPrefixBytes.length; _i++) {
      _tokenURIBytes[_i] = _tokenURIPrefixBytes[_i];
    }

    for (_i = 0; _i < _tokenURISuffixBytes.length; _i++) {
      _tokenURIBytes[_tokenURIBytes.length + _i - 5] = _tokenURISuffixBytes[_i];
    }

    return string(_tokenURIBytes);
  }
}

// File: contracts/core/erc721/AxieERC721.sol

// solium-disable-next-line no-empty-blocks
contract AxieERC721 is AxieERC721BaseEnumerable, AxieERC721Metadata {
}

// File: contracts/core/AxieCore.sol

// solium-disable-next-line no-empty-blocks
contract AxieCore is AxieERC721 {
  struct Axie {
    uint256 genes;
    uint256 bornAt;
  }

  Axie[] axies;

  event AxieSpawned(uint256 indexed _axieId, address indexed _owner, uint256 _genes);
  event AxieRebirthed(uint256 indexed _axieId, uint256 _genes);
  event AxieRetired(uint256 indexed _axieId);
  event AxieEvolved(uint256 indexed _axieId, uint256 _oldGenes, uint256 _newGenes);

  function AxieCore() public {
    axies.push(Axie(0, now)); // The void Axie
    _spawnAxie(0, msg.sender); // Will be Puff
    _spawnAxie(0, msg.sender); // Will be Kotaro
    _spawnAxie(0, msg.sender); // Will be Ginger
    _spawnAxie(0, msg.sender); // Will be Stella
  }

  function getAxie(
    uint256 _axieId
  )
    external
    view
    mustBeValidToken(_axieId)
    returns (uint256 /* _genes */, uint256 /* _bornAt */)
  {
    Axie storage _axie = axies[_axieId];
    return (_axie.genes, _axie.bornAt);
  }

  function spawnAxie(
    uint256 _genes,
    address _owner
  )
    external
    onlySpawner
    whenSpawningAllowed(_genes, _owner)
    returns (uint256)
  {
    return _spawnAxie(_genes, _owner);
  }

  function rebirthAxie(
    uint256 _axieId,
    uint256 _genes
  )
    external
    onlySpawner
    mustBeValidToken(_axieId)
    whenRebirthAllowed(_axieId, _genes)
  {
    Axie storage _axie = axies[_axieId];
    _axie.genes = _genes;
    _axie.bornAt = now;
    AxieRebirthed(_axieId, _genes);
  }

  function retireAxie(
    uint256 _axieId,
    bool _rip
  )
    external
    onlyByeSayer
    whenRetirementAllowed(_axieId, _rip)
  {
    _burn(_axieId);

    if (_rip) {
      delete axies[_axieId];
    }

    AxieRetired(_axieId);
  }

  function evolveAxie(
    uint256 _axieId,
    uint256 _newGenes
  )
    external
    onlyGeneScientist
    mustBeValidToken(_axieId)
    whenEvolvementAllowed(_axieId, _newGenes)
  {
    uint256 _oldGenes = axies[_axieId].genes;
    axies[_axieId].genes = _newGenes;
    AxieEvolved(_axieId, _oldGenes, _newGenes);
  }

  function _spawnAxie(uint256 _genes, address _owner) private returns (uint256 _axieId) {
    Axie memory _axie = Axie(_genes, now);
    _axieId = axies.push(_axie) - 1;
    _mint(_owner, _axieId);
    AxieSpawned(_axieId, _owner, _genes);
  }
}
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



// File: zeppelin/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

// File: contracts/presale/AxiePresale.sol

contract AxiePresale is HasNoEther, Pausable {
  using SafeMath for uint256;

  // No Axies can be adopted after this end date: Friday, March 16, 2018 11:59:59 PM GMT.
  uint256 constant public PRESALE_END_TIMESTAMP = 1521244799;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_AQUATIC = 2;
  uint8 constant public CLASS_PLANT = 4;

  uint256 constant public INITIAL_PRICE_INCREMENT = 1600 szabo; // 0.0016 Ether
  uint256 constant public INITIAL_PRICE = INITIAL_PRICE_INCREMENT;
  uint256 constant public REF_CREDITS_PER_AXIE = 5;

  mapping (uint8 => uint256) public currentPrices;
  mapping (uint8 => uint256) public priceIncrements;

  mapping (uint8 => uint256) public totalAxiesAdopted;
  mapping (address => mapping (uint8 => uint256)) public axiesAdopted;

  mapping (address => uint256) public referralCredits;
  mapping (address => uint256) public axiesRewarded;
  uint256 public totalAxiesRewarded;

  event AxiesAdopted(
    address indexed adopter,
    uint8 indexed clazz,
    uint256 quantity,
    address indexed referrer
  );

  event AxiesRewarded(address indexed receiver, uint256 quantity);

  event AdoptedAxiesRedeemed(address indexed receiver, uint8 indexed clazz, uint256 quantity);
  event RewardedAxiesRedeemed(address indexed receiver, uint256 quantity);

  function AxiePresale() public {
    priceIncrements[CLASS_BEAST] = priceIncrements[CLASS_AQUATIC] = //
      priceIncrements[CLASS_PLANT] = INITIAL_PRICE_INCREMENT;

    currentPrices[CLASS_BEAST] = currentPrices[CLASS_AQUATIC] = //
      currentPrices[CLASS_PLANT] = INITIAL_PRICE;
  }

  function axiesPrice(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    view
    returns (uint256 totalPrice)
  {
    uint256 price;

    (price,,) = _axiesPrice(CLASS_BEAST, beastQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_AQUATIC, aquaticQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_PLANT, plantQuantity);
    totalPrice = totalPrice.add(price);
  }

  function adoptAxies(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity,
    address referrer
  )
    public
    payable
    whenNotPaused
  {
    require(now <= PRESALE_END_TIMESTAMP);

    require(beastQuantity <= 3);
    require(aquaticQuantity <= 3);
    require(plantQuantity <= 3);

    address adopter = msg.sender;
    address actualReferrer = 0x0;

    // An adopter cannot be his/her own referrer.
    if (referrer != adopter) {
      actualReferrer = referrer;
    }

    uint256 value = msg.value;
    uint256 price;

    if (beastQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_BEAST,
        beastQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (aquaticQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_AQUATIC,
        aquaticQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (plantQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_PLANT,
        plantQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    msg.sender.transfer(value);

    // The current referral is ignored if the referrer's address is 0x0.
    if (actualReferrer != 0x0) {
      uint256 numCredit = referralCredits[actualReferrer]
        .add(beastQuantity)
        .add(aquaticQuantity)
        .add(plantQuantity);

      uint256 numReward = numCredit / REF_CREDITS_PER_AXIE;

      if (numReward > 0) {
        referralCredits[actualReferrer] = numCredit % REF_CREDITS_PER_AXIE;
        axiesRewarded[actualReferrer] = axiesRewarded[actualReferrer].add(numReward);
        totalAxiesRewarded = totalAxiesRewarded.add(numReward);
        AxiesRewarded(actualReferrer, numReward);
      } else {
        referralCredits[actualReferrer] = numCredit;
      }
    }
  }

  function redeemAdoptedAxies(
    address receiver,
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    onlyOwner
    returns (
      uint256 /* remainingBeastQuantity */,
      uint256 /* remainingAquaticQuantity */,
      uint256 /* remainingPlantQuantity */
    )
  {
    return (
      _redeemAdoptedAxies(receiver, CLASS_BEAST, beastQuantity),
      _redeemAdoptedAxies(receiver, CLASS_AQUATIC, aquaticQuantity),
      _redeemAdoptedAxies(receiver, CLASS_PLANT, plantQuantity)
    );
  }

  function redeemRewardedAxies(
    address receiver,
    uint256 quantity
  )
    public
    onlyOwner
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesRewarded[receiver] = axiesRewarded[receiver].sub(quantity);

    if (quantity > 0) {
      // This requires that rewarded Axies are always included in the total
      // to make sure overflow won't happen.
      totalAxiesRewarded -= quantity;

      RewardedAxiesRedeemed(receiver, quantity);
    }
  }

  /**
   * @dev Calculate price of Axies from the same class.
   * @param clazz The class of Axies.
   * @param quantity Number of Axies to be calculated.
   */
  function _axiesPrice(
    uint8 clazz,
    uint256 quantity
  )
    private
    view
    returns (uint256 totalPrice, uint256 priceIncrement, uint256 currentPrice)
  {
    priceIncrement = priceIncrements[clazz];
    currentPrice = currentPrices[clazz];

    uint256 nextPrice;

    for (uint256 i = 0; i < quantity; i++) {
      totalPrice = totalPrice.add(currentPrice);
      nextPrice = currentPrice.add(priceIncrement);

      if (nextPrice / 100 finney != currentPrice / 100 finney) {
        priceIncrement >>= 1;
      }

      currentPrice = nextPrice;
    }
  }

  /**
   * @dev Adopt some Axies from the same class.
   * @param adopter Address of the adopter.
   * @param clazz The class of adopted Axies.
   * @param quantity Number of Axies to be adopted, this should be positive.
   * @param referrer Address of the referrer.
   */
  function _adoptAxies(
    address adopter,
    uint8 clazz,
    uint256 quantity,
    address referrer
  )
    private
    returns (uint256 totalPrice)
  {
    (totalPrice, priceIncrements[clazz], currentPrices[clazz]) = _axiesPrice(clazz, quantity);

    axiesAdopted[adopter][clazz] = axiesAdopted[adopter][clazz].add(quantity);
    totalAxiesAdopted[clazz] = totalAxiesAdopted[clazz].add(quantity);

    AxiesAdopted(
      adopter,
      clazz,
      quantity,
      referrer
    );
  }

  /**
   * @dev Redeem adopted Axies from the same class.
   * @param receiver Address of the receiver.
   * @param clazz The class of adopted Axies.
   * @param quantity Number of adopted Axies to be redeemed.
   */
  function _redeemAdoptedAxies(
    address receiver,
    uint8 clazz,
    uint256 quantity
  )
    private
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesAdopted[receiver][clazz] = axiesAdopted[receiver][clazz].sub(quantity);

    if (quantity > 0) {
      // This requires that adopted Axies are always included in the total
      // to make sure overflow won't happen.
      totalAxiesAdopted[clazz] -= quantity;

      AdoptedAxiesRedeemed(receiver, clazz, quantity);
    }
  }
}

// File: zeppelin/contracts/ownership/HasNoContracts.sol

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: contracts/presale/AxiePresaleExtended.sol

contract AxiePresaleExtended is HasNoContracts, Pausable {
  using SafeMath for uint256;

  // No Axies can be adopted after this end date: Monday, April 16, 2018 11:59:59 PM GMT.
  uint256 constant public PRESALE_END_TIMESTAMP = 1523923199;

  // The total number of adopted Axies will be capped at 5250,
  // so the number of Axies which have Mystic parts will be capped roughly at 2000.
  uint256 constant public MAX_TOTAL_ADOPTED_AXIES = 5250;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_AQUATIC = 2;
  uint8 constant public CLASS_PLANT = 4;

  // The initial price increment and the initial price are for reference only
  uint256 constant public INITIAL_PRICE_INCREMENT = 1600 szabo; // 0.0016 Ether
  uint256 constant public INITIAL_PRICE = INITIAL_PRICE_INCREMENT;

  uint256 constant public REF_CREDITS_PER_AXIE = 5;

  AxiePresale public presaleContract;
  address public redemptionAddress;

  mapping (uint8 => uint256) public currentPrice;
  mapping (uint8 => uint256) public priceIncrement;

  mapping (uint8 => uint256) private _totalAdoptedAxies;
  mapping (uint8 => uint256) private _totalDeductedAdoptedAxies;
  mapping (address => mapping (uint8 => uint256)) private _numAdoptedAxies;
  mapping (address => mapping (uint8 => uint256)) private _numDeductedAdoptedAxies;

  mapping (address => uint256) private _numRefCredits;
  mapping (address => uint256) private _numDeductedRefCredits;
  uint256 public numBountyCredits;

  uint256 private _totalRewardedAxies;
  uint256 private _totalDeductedRewardedAxies;
  mapping (address => uint256) private _numRewardedAxies;
  mapping (address => uint256) private _numDeductedRewardedAxies;

  event AxiesAdopted(
    address indexed _adopter,
    uint8 indexed _class,
    uint256 _quantity,
    address indexed _referrer
  );

  event AxiesRewarded(address indexed _receiver, uint256 _quantity);

  event AdoptedAxiesRedeemed(address indexed _receiver, uint8 indexed _class, uint256 _quantity);
  event RewardedAxiesRedeemed(address indexed _receiver, uint256 _quantity);

  event RefCreditsMinted(address indexed _receiver, uint256 _numMintedCredits);

  function AxiePresaleExtended() public payable {
    require(msg.value == 0);
    paused = true;
    numBountyCredits = 300;
  }

  function () external payable {
    require(msg.sender == address(presaleContract));
  }

  modifier whenNotInitialized {
    require(presaleContract == address(0));
    _;
  }

  modifier whenInitialized {
    require(presaleContract != address(0));
    _;
  }

  modifier onlyRedemptionAddress {
    require(msg.sender == redemptionAddress);
    _;
  }

  function reclaimEther() external onlyOwner whenInitialized {
    presaleContract.reclaimEther();
    owner.transfer(this.balance);
  }

  /**
   * @dev This must be called only once after the owner of the presale contract
   *  has been updated to this contract.
   */
  function initialize(address _presaleAddress) external onlyOwner whenNotInitialized {
    // Set the presale address.
    presaleContract = AxiePresale(_presaleAddress);

    presaleContract.pause();

    // Restore price increments from the old contract.
    priceIncrement[CLASS_BEAST] = presaleContract.priceIncrements(CLASS_BEAST);
    priceIncrement[CLASS_AQUATIC] = presaleContract.priceIncrements(CLASS_AQUATIC);
    priceIncrement[CLASS_PLANT] = presaleContract.priceIncrements(CLASS_PLANT);

    // Restore current prices from the old contract.
    currentPrice[CLASS_BEAST] = presaleContract.currentPrices(CLASS_BEAST);
    currentPrice[CLASS_AQUATIC] = presaleContract.currentPrices(CLASS_AQUATIC);
    currentPrice[CLASS_PLANT] = presaleContract.currentPrices(CLASS_PLANT);

    paused = false;
  }

  function setRedemptionAddress(address _redemptionAddress) external onlyOwner whenInitialized {
    redemptionAddress = _redemptionAddress;
  }

  function totalAdoptedAxies(
    uint8 _class,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _totalAdoptedAxies[_class]
      .add(presaleContract.totalAxiesAdopted(_class));

    if (_deduction) {
      _number = _number.sub(_totalDeductedAdoptedAxies[_class]);
    }
  }

  function numAdoptedAxies(
    address _owner,
    uint8 _class,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numAdoptedAxies[_owner][_class]
      .add(presaleContract.axiesAdopted(_owner, _class));

    if (_deduction) {
      _number = _number.sub(_numDeductedAdoptedAxies[_owner][_class]);
    }
  }

  function numRefCredits(
    address _owner,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numRefCredits[_owner]
      .add(presaleContract.referralCredits(_owner));

    if (_deduction) {
      _number = _number.sub(_numDeductedRefCredits[_owner]);
    }
  }

  function totalRewardedAxies(
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _totalRewardedAxies
      .add(presaleContract.totalAxiesRewarded());

    if (_deduction) {
      _number = _number.sub(_totalDeductedRewardedAxies);
    }
  }

  function numRewardedAxies(
    address _owner,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numRewardedAxies[_owner]
      .add(presaleContract.axiesRewarded(_owner));

    if (_deduction) {
      _number = _number.sub(_numDeductedRewardedAxies[_owner]);
    }
  }

  function axiesPrice(
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity
  )
    external
    view
    whenInitialized
    returns (uint256 _totalPrice)
  {
    uint256 price;

    (price,,) = _sameClassAxiesPrice(CLASS_BEAST, _beastQuantity);
    _totalPrice = _totalPrice.add(price);

    (price,,) = _sameClassAxiesPrice(CLASS_AQUATIC, _aquaticQuantity);
    _totalPrice = _totalPrice.add(price);

    (price,,) = _sameClassAxiesPrice(CLASS_PLANT, _plantQuantity);
    _totalPrice = _totalPrice.add(price);
  }

  function adoptAxies(
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity,
    address _referrer
  )
    external
    payable
    whenInitialized
    whenNotPaused
  {
    require(now <= PRESALE_END_TIMESTAMP);
    require(_beastQuantity <= 3 && _aquaticQuantity <= 3 && _plantQuantity <= 3);

    uint256 _totalAdopted = this.totalAdoptedAxies(CLASS_BEAST, false)
      .add(this.totalAdoptedAxies(CLASS_AQUATIC, false))
      .add(this.totalAdoptedAxies(CLASS_PLANT, false))
      .add(_beastQuantity)
      .add(_aquaticQuantity)
      .add(_plantQuantity);

    require(_totalAdopted <= MAX_TOTAL_ADOPTED_AXIES);

    address _adopter = msg.sender;
    address _actualReferrer = 0x0;

    // An adopter cannot be his/her own referrer.
    if (_referrer != _adopter) {
      _actualReferrer = _referrer;
    }

    uint256 _value = msg.value;
    uint256 _price;

    if (_beastQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_BEAST,
        _beastQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    if (_aquaticQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_AQUATIC,
        _aquaticQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    if (_plantQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_PLANT,
        _plantQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    msg.sender.transfer(_value);

    // The current referral is ignored if the referrer's address is 0x0.
    if (_actualReferrer != 0x0) {
      _applyRefCredits(
        _actualReferrer,
        _beastQuantity.add(_aquaticQuantity).add(_plantQuantity)
      );
    }
  }

  function mintRefCredits(
    address _receiver,
    uint256 _numMintedCredits
  )
    external
    onlyOwner
    whenInitialized
    returns (uint256)
  {
    require(_receiver != address(0));
    numBountyCredits = numBountyCredits.sub(_numMintedCredits);
    _applyRefCredits(_receiver, _numMintedCredits);
    RefCreditsMinted(_receiver, _numMintedCredits);
    return numBountyCredits;
  }

  function redeemAdoptedAxies(
    address _receiver,
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity
  )
    external
    onlyRedemptionAddress
    whenInitialized
    returns (
      uint256 /* remainingBeastQuantity */,
      uint256 /* remainingAquaticQuantity */,
      uint256 /* remainingPlantQuantity */
    )
  {
    return (
      _redeemSameClassAdoptedAxies(_receiver, CLASS_BEAST, _beastQuantity),
      _redeemSameClassAdoptedAxies(_receiver, CLASS_AQUATIC, _aquaticQuantity),
      _redeemSameClassAdoptedAxies(_receiver, CLASS_PLANT, _plantQuantity)
    );
  }

  function redeemRewardedAxies(
    address _receiver,
    uint256 _quantity
  )
    external
    onlyRedemptionAddress
    whenInitialized
    returns (uint256 _remainingQuantity)
  {
    _remainingQuantity = this.numRewardedAxies(_receiver, true).sub(_quantity);

    if (_quantity > 0) {
      _numDeductedRewardedAxies[_receiver] = _numDeductedRewardedAxies[_receiver].add(_quantity);
      _totalDeductedRewardedAxies = _totalDeductedRewardedAxies.add(_quantity);

      RewardedAxiesRedeemed(_receiver, _quantity);
    }
  }

  /**
   * @notice Calculate price of Axies from the same class.
   * @param _class The class of Axies.
   * @param _quantity Number of Axies to be calculated.
   */
  function _sameClassAxiesPrice(
    uint8 _class,
    uint256 _quantity
  )
    private
    view
    returns (
      uint256 _totalPrice,
      uint256 /* should be _subsequentIncrement */ _currentIncrement,
      uint256 /* should be _subsequentPrice */ _currentPrice
    )
  {
    _currentIncrement = priceIncrement[_class];
    _currentPrice = currentPrice[_class];

    uint256 _nextPrice;

    for (uint256 i = 0; i < _quantity; i++) {
      _totalPrice = _totalPrice.add(_currentPrice);
      _nextPrice = _currentPrice.add(_currentIncrement);

      if (_nextPrice / 100 finney != _currentPrice / 100 finney) {
        _currentIncrement >>= 1;
      }

      _currentPrice = _nextPrice;
    }
  }

  /**
   * @notice Adopt some Axies from the same class.
   * @dev The quantity MUST be positive.
   * @param _adopter Address of the adopter.
   * @param _class The class of adopted Axies.
   * @param _quantity Number of Axies to be adopted.
   * @param _referrer Address of the referrer.
   */
  function _adoptSameClassAxies(
    address _adopter,
    uint8 _class,
    uint256 _quantity,
    address _referrer
  )
    private
    returns (uint256 _totalPrice)
  {
    (_totalPrice, priceIncrement[_class], currentPrice[_class]) = _sameClassAxiesPrice(_class, _quantity);

    _numAdoptedAxies[_adopter][_class] = _numAdoptedAxies[_adopter][_class].add(_quantity);
    _totalAdoptedAxies[_class] = _totalAdoptedAxies[_class].add(_quantity);

    AxiesAdopted(
      _adopter,
      _class,
      _quantity,
      _referrer
    );
  }

  function _applyRefCredits(address _receiver, uint256 _numAppliedCredits) private {
    _numRefCredits[_receiver] = _numRefCredits[_receiver].add(_numAppliedCredits);

    uint256 _numCredits = this.numRefCredits(_receiver, true);
    uint256 _numRewards = _numCredits / REF_CREDITS_PER_AXIE;

    if (_numRewards > 0) {
      _numDeductedRefCredits[_receiver] = _numDeductedRefCredits[_receiver]
        .add(_numRewards.mul(REF_CREDITS_PER_AXIE));

      _numRewardedAxies[_receiver] = _numRewardedAxies[_receiver].add(_numRewards);
      _totalRewardedAxies = _totalRewardedAxies.add(_numRewards);

      AxiesRewarded(_receiver, _numRewards);
    }
  }

  /**
   * @notice Redeem adopted Axies from the same class.
   * @dev Emit the `AdoptedAxiesRedeemed` event if the quantity is positive.
   * @param _receiver The address of the receiver.
   * @param _class The class of adopted Axies.
   * @param _quantity The number of adopted Axies to be redeemed.
   */
  function _redeemSameClassAdoptedAxies(
    address _receiver,
    uint8 _class,
    uint256 _quantity
  )
    private
    returns (uint256 _remainingQuantity)
  {
    _remainingQuantity = this.numAdoptedAxies(_receiver, _class, true).sub(_quantity);

    if (_quantity > 0) {
      _numDeductedAdoptedAxies[_receiver][_class] = _numDeductedAdoptedAxies[_receiver][_class].add(_quantity);
      _totalDeductedAdoptedAxies[_class] = _totalDeductedAdoptedAxies[_class].add(_quantity);

      AdoptedAxiesRedeemed(_receiver, _class, _quantity);
    }
  }
}

contract AxieRedemptionInternal is HasNoContracts, Pausable {
  using SafeMath for uint256;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_BUG = 1;
  uint8 constant public CLASS_BIRD = 2;
  uint8 constant public CLASS_PLANT = 3;
  uint8 constant public CLASS_AQUATIC = 4;
  uint8 constant public CLASS_REPTILE = 5;

  struct Redemption {
    address receiver;
    uint256 clazz;
    uint256 redeemedAt;
  }

  AxieCore public coreContract;
  AxiePresaleExtended public presaleContract;

  mapping (uint256 => Redemption) public redemptionByQueryId;
  mapping (address => mapping (uint256 => uint256[])) public ownedRedemptions;
  mapping (uint256 => uint256) public ownedRedemptionIndex;

  event RedemptionStarted(uint256 indexed _queryId);
  event RedemptionRetried(uint256 indexed _queryId, uint256 indexed _oldQueryId);
  event RedemptionFinished(uint256 indexed _queryId);

  function () external payable {
    require(msg.sender == owner);
  }

  modifier requireDependencyContracts {
    require(coreContract != address(0) && presaleContract != address(0));
    _;
  }

  modifier whenStarted {
    require(now >= _startTimestamp());
    _;
  }

  function reclaimEther(uint256 remaining) external onlyOwner {
    if (this.balance > remaining) {
      owner.transfer(this.balance - remaining);
    }
  }

  function setCoreContract(address _coreAddress) external onlyOwner {
    coreContract = AxieCore(_coreAddress);
  }

  function setPresaleContract(address _presaleAddress) external onlyOwner {
    presaleContract = AxiePresaleExtended(_presaleAddress);
  }

  function numBeingRedeemedAxies(address _receiver, uint256 _class) external view returns (uint256) {
    return ownedRedemptions[_receiver][_class].length;
  }

  function redeemAdoptedAxies(
    uint256 _oldClass
  )
    external
    requireDependencyContracts
    whenStarted
    whenNotPaused
  {
    _redeemAdoptedAxies(msg.sender, _oldClass);
  }

  function redeemPlayersAdoptedAxies(
    address _receiver,
    uint256 _oldClass
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    _redeemAdoptedAxies(_receiver, _oldClass);
  }

  function redeemRewardedAxies()
    external
    requireDependencyContracts
    whenStarted
    whenNotPaused
  {
    _redeemRewardedAxies(msg.sender);
  }

  function redeemPlayersRewardedAxies(
    address _receiver
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    _redeemRewardedAxies(_receiver);
  }

  function retryRedemption(
    uint256 _oldQueryId,
    uint256 _gasLimit
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    Redemption memory _redemption = redemptionByQueryId[_oldQueryId];
    require(_redemption.receiver != address(0));

    uint256 _redemptionIndex = ownedRedemptionIndex[_oldQueryId];
    uint256 _queryId = _sendRandomQuery(_gasLimit);

    redemptionByQueryId[_queryId] = _redemption;
    delete redemptionByQueryId[_oldQueryId];

    ownedRedemptions[_redemption.receiver][_redemption.clazz][_redemptionIndex] = _queryId;
    ownedRedemptionIndex[_queryId] = _redemptionIndex;
    delete ownedRedemptionIndex[_oldQueryId];

    RedemptionRetried(_queryId, _oldQueryId);
  }

  function _startTimestamp() internal returns (uint256);

  function _sendRandomQuery(uint256 _gasLimit) internal returns (uint256);

  function _receiveRandomQuery(
    uint256 _queryId,
    string _result
  )
    internal
    whenStarted
    whenNotPaused
  {
    Redemption memory _redemption = redemptionByQueryId[_queryId];
    require(_redemption.receiver != address(0));

    uint256 _redemptionIndex = ownedRedemptionIndex[_queryId];
    uint256 _lastRedemptionIndex = ownedRedemptions[_redemption.receiver][_redemption.clazz].length.sub(1);
    uint256 _lastRedemptionQueryId = ownedRedemptions[_redemption.receiver][_redemption.clazz][_lastRedemptionIndex];

    uint256 _seed = uint256(keccak256(_result));
    uint256 _genes;

    if (_redemption.clazz != uint256(-1)) {
      _genes = _generateGenes(_redemption.clazz, _seed);
    } else {
      _genes = _generateGenes(_seed);
    }

    ownedRedemptions[_redemption.receiver][_redemption.clazz][_redemptionIndex] = _lastRedemptionQueryId;
    ownedRedemptionIndex[_lastRedemptionQueryId] = _redemptionIndex;

    delete ownedRedemptions[_redemption.receiver][_redemption.clazz][_lastRedemptionIndex];
    ownedRedemptions[_redemption.receiver][_redemption.clazz].length--;

    delete redemptionByQueryId[_queryId];
    delete ownedRedemptionIndex[_queryId];

    // Spawn an Axie with the generated `genes`.
    coreContract.spawnAxie(_genes, _redemption.receiver);

    RedemptionFinished(_queryId);
  }

  function _randomNumber(
    uint256 _upper,
    uint256 _initialSeed
  )
    private
    view
    returns (uint256 _number, uint256 _seed)
  {
    _seed = uint256(
      keccak256(
        _initialSeed,
        block.blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
      )
    );

    _number = _seed % _upper;
  }

  function _randomClass(uint256 _initialSeed) private view returns (uint256 _class, uint256 _seed) {
    // solium-disable-next-line comma-whitespace
    (_class, _seed) = _randomNumber(6 /* CLASS_REPTILE + 1 */, _initialSeed);
  }

  function _generateGenes(uint256 _class, uint256 _initialSeed) private view returns (uint256) {
    // Gene generation logic is removed.
    return 0;
  }

  function _generateGenes(uint256 _initialSeed) private view returns (uint256) {
    uint256 _class;
    uint256 _seed;
    (_class, _seed) = _randomClass(_initialSeed);
    return _generateGenes(_class, _seed);
  }

  function _redeemAxies(address _receiver, uint256 _class) private {
    uint256 _queryId = _sendRandomQuery(300000);

    Redemption memory _redemption = Redemption(
      _receiver,
      _class,
      now
    );

    redemptionByQueryId[_queryId] = _redemption;

    uint256 _length = ownedRedemptions[_receiver][_class].length;
    ownedRedemptions[_receiver][_class].push(_queryId);
    ownedRedemptionIndex[_queryId] = _length;

    RedemptionStarted(_queryId);
  }

  function _redeemAdoptedAxies(address _receiver, uint256 _oldClass) private {
    uint256 _class;

    if (_oldClass == 0) { // Old Beast
      presaleContract.redeemAdoptedAxies(_receiver, 1, 0, 0);
      _class = CLASS_BEAST;
    } else if (_oldClass == 2) { // Old Aquatic
      presaleContract.redeemAdoptedAxies(_receiver, 0, 1, 0);
      _class = CLASS_AQUATIC;
    } else if (_oldClass == 4) { // Old Plant
      presaleContract.redeemAdoptedAxies(_receiver, 0, 0, 1);
      _class = CLASS_PLANT;
    } else {
      revert();
    }

    _redeemAxies(_receiver, _class);
  }

  function _redeemRewardedAxies(address _receiver) private {
    presaleContract.redeemRewardedAxies(_receiver, 1);
    _redeemAxies(_receiver, uint256(-1));
  }
}


contract AxieRedemption is AxieRedemptionInternal, usingOraclize {
  function _startTimestamp() internal returns (uint256) {
    // Wednesday, March 14, 2018 4:00:00 AM.
    return 1521000000;
  }

  function _sendRandomQuery(uint256 _gasLimit) internal returns (uint256) {
    return uint256(oraclize_query("WolframAlpha", "random number between 1 and 2^64", _gasLimit));
  }

  // solium-disable-next-line function-order, mixedcase
  function __callback(bytes32 _queryId, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    _receiveRandomQuery(uint256(_queryId), _result);
  }
}