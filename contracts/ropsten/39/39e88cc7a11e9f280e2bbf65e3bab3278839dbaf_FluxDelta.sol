pragma solidity 0.4.18;

/**
 * For convenience, you can delete all of the code between the <ORACLIZE_API>
 * and </ORACLIZE_API> tags as etherscan cannot use the import callback, you
 * can then just uncomment the line below and compile it via Remix.
 */
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// This api is currently targeted at 0.4.18, please import oraclizeAPI_pre0.4.sol or oraclizeAPI_0.4 where necessary

pragma solidity >=0.4.18;// Incompatible compiler version... please select one stated within pragma solidity or use different oraclizeAPI version

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
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
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

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
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

        // verify if sessionPubkeyHash was verified already, if not.. let&#39;s do it!
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
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
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
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
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
// </ORACLIZE_API>


/*===========================================================================================*
*********************************** https://p4d.io/ropsten ***********************************
*============================================================================================*
*                                                             
*     ,-.----.           ,--,              
*     \    /  \        ,--.&#39;|    ,---,     
*     |   :    \    ,--,  | :  .&#39;  .&#39; `\          ____                            __      
*     |   |  .\ :,---.&#39;|  : &#39;,---.&#39;     \        / __ \________  ________  ____  / /______
*     .   :  |: |;   : |  | ;|   |  .`\  |      / /_/ / ___/ _ \/ ___/ _ \/ __ \/ __/ ___/
*     |   |   \ :|   | : _&#39; |:   : |  &#39;  |     / ____/ /  /  __(__  )  __/ / / / /_(__  ) 
*     |   : .   /:   : |.&#39;  ||   &#39; &#39;  ;  :    /_/   /_/___\\\_/____/\_\\/_\_/_/\__/____/  
*     ;   | |`-&#39; |   &#39; &#39;  ; :&#39;   | ;  .  |            /_  __/___      \ \/ /___  __  __   
*     |   | ;    \   \  .&#39;. ||   | :  |  &#39;             / / / __ \      \  / __ \/ / / /   
*     :   &#39; |     `---`:  | &#39;&#39;   : | /  ;             / / / /_/ /      / / /_/ / /_/ /    
*     :   : :          &#39;  ; ||   | &#39;` ,/             /_/  \____/      /_/\____/\__,_/     
*     |   | :          |  : ;;   :  .&#39;     
*     `---&#39;.|          &#39;  ,/ |   ,.&#39;       
*       `---`          &#39;--&#39;  &#39;---&#39;         
* 
*                        _______ _             _____        _           
*                       (_______) |           (____ \      | |_         
*                        _____  | |_   _ _   _ _   \ \ ____| | |_  ____ 
*                       |  ___) | | | | ( \ / ) |   | / _  ) |  _)/ _  |
*                       | |     | | |_| |) X (| |__/ ( (/ /| | |_( ( | |
*                       |_|     |_|\____(_/ \_)_____/ \____)_|\___)_||_|
* 
*                                           ____
*                                          /\   \
*                                         /  \   \
*                                        /    \   \
*                                       /      \   \
*                                      /   /\   \   \
*                                     /   /  \   \   \
*                                    /   /    \   \   \
*                                   /   /    / \   \   \
*                                  /   /    /   \   \   \
*                                 /   /    /---------&#39;   \
*                                /   /    /_______________\
*                                \  /                     /
*                                 \/_____________________/
*                   _       ___            _                  _       ___       
*                  /_\     / __\___  _ __ | |_ _ __ __ _  ___| |_    / __\_   _ 
*                 //_\\   / /  / _ \| &#39;_ \| __| &#39;__/ _` |/ __| __|  /__\// | | |
*                /  _  \ / /__| (_) | | | | |_| | | (_| | (__| |_  / \/  \ |_| |
*                \_/ \_/ \____/\___/|_| |_|\__|_|  \__,_|\___|\__| \_____/\__, |
*                                   ╔═╗╔═╗╦      ╔╦╗╔═╗╦  ╦               |___/ 
*                                   ╚═╗║ ║║       ║║║╣ ╚╗╔╝
*                                   ╚═╝╚═╝╩═╝────═╩╝╚═╝ ╚╝ 
*                                      0x736f6c5f646576
*                                      ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
*                                                
*/


// P3D interface
interface P3D {
    function sell(uint256) external;
    function myTokens() external view returns(uint256);
    function myDividends(bool) external view returns(uint256);
    function withdraw() external;
}

// P4D interface
interface P4D {
    function buy(address) external payable returns(uint256);
    function sell(uint256) external;
    function transfer(address, uint256) external returns(bool);
    function myTokens() external view returns(uint256);
    function myStoredDividends() external view returns(uint256);
    function mySubdividends() external view returns(uint256);
    function withdraw(bool) external;
    function withdrawSubdivs(bool) external;
    function P3D_address() external view returns(address);
    function setCanAcceptTokens(address) external;
}

/**
 * An inheritable contract structure that connects to the P4D exchange
 * This will then point to the P3D exchange as well as providing the tokenCallback() function
 */
contract usingP4D {

    P4D internal tokenContract;
    P3D internal _P3D;

    function usingP4D(address _P4D_address) public {
        tokenContract = P4D(_P4D_address);
        _P3D = P3D(tokenContract.P3D_address());
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    function tokenCallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


/**
 * This is the coin-pair contract, the main FluxDelta contract will create a new coin-pair
 * contract every time a pairing is added to the network. The FluxDelta contract is be able
 * to manage the coin-pair in respect to setting its UI visibility as well as the coin-pairs
 * callback gas price in case the network gets congested.
 * Each coin-pair contract is self-managing and has its own P4D, P3D and ETH balances. In
 * order to keep affording to pay for Oraclize calls, it will always maintain a certain 
 * amount of ETH and should it drop beneath a certain threshold, it will sell some of the
 * P3D that it holds. If it has a surplus of ETH, it will use the excess to purchase more
 * P4D that will go towards the global withdrawable pot.
 * A user can invest into a coin-pair via the P4D exchange contract using the transferAndCall()
 * function and they can withdraw their P4D shares via the main FluxDelta contract using the
 * withdrawFromCoinPair() function.
 */
contract CoinPair is usingP4D, usingOraclize {

    using SafeMath for uint256;

    struct OraclizeMap {
        address _sender;
        bool _isNextShort;
        uint256 _sentValue;
    }
    mapping(bytes32 => OraclizeMap) private _oraclizeCallbackMap;

    event RequestSubmitted(bytes32 id);

    uint256 constant private _devOwnerCut = 1; // 1% of deposits are used as dev fees
    uint256 constant private _minDeposit = 100e18; // we need to cover Oraclize at a bare minimum
    uint256 constant private _sellThreshold = 0.1 ether; // if the balance drops below this, sell P4D
    uint256 constant private _buyThreshold = 0.2 ether; // if the balance goes above this, buy P4D
    int256 constant private _baseSharesPerRequest = 1e18; // 1% * 100e18

    address private _dev; // main developer; will receive 0.5% of P4D deposits
    address private _owner; // a nominated owner; they will also receive 0.5% of the depost
    address private _creator; // the parent FluxDelta contract

    uint256 private _devBalance = 0;
    uint256 private _ownerBalance = 0;
    uint256 private _processingP4D = 0;

    bytes32 public fSym;
    bytes32 public tSym;
    uint256 constant public baseCost = 100e18; // 100 P4D tokens
    uint256 public shares;
    mapping(address => uint256) public sharesOf;
    mapping(address => uint256) public scalarOf;
    mapping(address => bool) public isShorting;
    mapping(address => uint256) public lastPriceOf;
    mapping(address => uint256) public lastPriceTimeOf;
    bool public isVisible;

    /**
     * Modifier for restricting a call to just the FluxDelta contract
     */
    modifier onlyCreator {
        require(msg.sender == _creator);
        _;
    }

    /**
     * Coin-pair constructor;
     * _fSym: From symbol (eg ETH)
     * _tSym: To symbol (eg USD)
     * _ownerAddress: Nominated owner, will receive 0.5% of all deposits
     * _devAddress: FluxDelta dev, will also receive 0.5% of all deposits
     * _P4D_address: P4D exchange address reference
     */
    function CoinPair(string _fSym, string _tSym, address _ownerAddress, address _devAddress, address _P4D_address) public payable usingP4D(_P4D_address) {
        require (msg.value >= _sellThreshold);

        require(_ownerAddress != _devAddress && _ownerAddress != msg.sender && _devAddress != msg.sender);

        _creator = msg.sender;
        fSym = _stringToBytes32(_fSym);
        tSym = _stringToBytes32(_tSym);
        shares = 0;
        _owner = _ownerAddress;
        _dev = _devAddress;
        isVisible = true;

        changeOraclizeGasPrice(16e9); // 16 Gwei for all callbacks
    }

    /**
     * Main point of interaction within a coin-pair, the P4D contract will call this function
     * after a customer has sent P4D using the transferAndCall() function to this address.
     * This function sets up all of the required information in order to make a call to the
     * internet via Oraclize, this will fetch the current price of the coin-pair without needing
     * to worry about a user tampering with the data.
     * Oraclize is a paid service and requires ETH to use, this contract must pay a fee for the
     * internet call itself as well as the gas cost to cover the __callback() function below.
     */
    function tokenCallback(address _from, uint256 _value, bytes _data) external onlyTokenContract returns (bool) {
        require(_value >= _minDeposit);

        require(!_isContract(_from));
        require(_from != _dev && _from != _owner && _from != _creator);

        uint256 fees = _value.mul(_devOwnerCut).div(100); // 1%
        _devBalance = _devBalance.add(fees.div(2)); // 0.5%
        _ownerBalance = _ownerBalance.add(fees.div(2)); // 0.5%

        _processingP4D = _processingP4D.add(_value);

        /////////////////////////////////////////////////////////////////////////////////
        //  
        // The block of code below is responsible for using all of the P4D and P3D
        // dividends in order to both maintain and afford to pay for Oraclize calls
        // as well as purchasing more P4D to put towards the global pot should there
        // be an excess of ETH
        //
        // first withdraw all ETH subdividends from the P4D contract
        if (tokenContract.mySubdividends() > 0) {
            tokenContract.withdrawSubdivs(true);
        }

        // if this contracts ETH balance is less than the threshold, sell a minimum
        // P4D deposit (100 P4D) then sell 1/4 of all the held P3D in this contract
        //
        // if this contracts ETH balance is more than the buying threshold, use this
        // excess ETH to purchase more P4D to put in the global withdrawable pot
        if (address(this).balance < _sellThreshold) {
            tokenContract.sell(_minDeposit);
            tokenContract.withdraw(true);
            _P3D.sell(_P3D.myTokens().div(4)); // sell 1/4 of all P3D held by the contract
        } else if (address(this).balance > _buyThreshold) {
            uint256 diff = address(this).balance.sub(_buyThreshold);
            tokenContract.buy.value(diff)(_owner); // use the owner as a ref
        }
        
        // if there&#39;s any stored P3D dividends, withdraw and hold them
        if (tokenContract.myStoredDividends() > 0) {
            tokenContract.withdraw(true);
        }

        // finally, check if there&#39;s any ETH divs to withdraw from the P3D contract
        if (_P3D.myDividends(true) > 0) {
            _P3D.withdraw();
        }

        /////////////////////////////////////////////////////////////////////////////////

        uint256 gasLimit = 220000;
        if (lastPriceOf[_from] != 0) {
            gasLimit = 160000;
            require(_value.mul(1e18).div(baseCost) == scalarOf[_from]); // check if they sent the right amount
        }

        // parse the URL data for Oraclize
        string memory tSymString = strConcat("&tsyms=", _bytes32ToString(tSym), ").", _bytes32ToString(tSym));
        bytes32 queryId = oraclize_query("URL", strConcat("json(https://min-api.cryptocompare.com/data/price?fsym=", _bytes32ToString(fSym), tSymString), gasLimit);

        uint256 intData = _bytesToUint(_data);
        OraclizeMap memory map = OraclizeMap({
            _sender: _from,
            _isNextShort: intData != 0,
            _sentValue: _value
        });
        _oraclizeCallbackMap[queryId] = map;

        RequestSubmitted(queryId);

        return true;
    }

    /**
     * Oraclize callback function for returning data
     */
    function __callback(bytes32 myid, string result) public {
        require(msg.sender == oraclize_cbAddress());
        _handleCallback(myid, result);
    }

    /**
     * Internally handled callback, this function is responsible for updating the shares gained/lost
     * of a user once they&#39;ve invested in a coin-pair. If you have already invested in the coin-pair
     * before, this will compare your last locked in price to the current price and provide you shares
     * based on the gain/loss of the coin-pair (as well as being multiplied by your staked P4D amount).
     */
    function _handleCallback(bytes32 _id, string _result) internal {
        OraclizeMap memory mappedInfo = _oraclizeCallbackMap[_id];
        address receiver = mappedInfo._sender;
        require(receiver != address(0x0));

        int256 latestPrice = int256(parseInt(_result, 18)); // 18 decimal places
        if (latestPrice > 0) {

            int256 lastPrice = int256(lastPriceOf[receiver]);
            if (lastPrice == 0) { // we are starting from the beginning

                lastPriceTimeOf[receiver] = now;
                lastPriceOf[receiver] = uint256(latestPrice);
                scalarOf[receiver] = mappedInfo._sentValue.mul(1e18).div(baseCost);
                sharesOf[receiver] = uint256(_baseSharesPerRequest) * scalarOf[receiver] / 1e18;
                isShorting[receiver] = mappedInfo._isNextShort;
                shares = shares.add(uint256(_baseSharesPerRequest) * scalarOf[receiver] / 1e18);

            } else { // they already have a price recorded so find the gain/loss

                if (mappedInfo._sentValue.mul(1e18).div(baseCost) == scalarOf[receiver]) {
                    int256 delta = _baseSharesPerRequest + ((isShorting[receiver] ? int256(-1) : int256(1)) * ((100e18 * (latestPrice - lastPrice)) / lastPrice)); // in terms of % (18 decimals) + base gain (+1%)
                    delta = delta * int256(scalarOf[receiver]) / int256(1e18);
                    int256 currentShares = int256(sharesOf[receiver]);
                    if (currentShares + delta > _baseSharesPerRequest * int256(scalarOf[receiver]) / int256(1e18)) {
                        sharesOf[receiver] = uint256(currentShares + delta);
                    } else {
                        sharesOf[receiver] = uint256(_baseSharesPerRequest) * scalarOf[receiver] / 1e18;
                    }

                    lastPriceTimeOf[receiver] = now;
                    lastPriceOf[receiver] = uint256(latestPrice);
                    isShorting[receiver] = mappedInfo._isNextShort;
                    shares = uint256(int256(shares) + int256(sharesOf[receiver]) - currentShares);
                } else { // something strange has happened so refund the P4D
                    require(tokenContract.transfer(receiver, mappedInfo._sentValue));
                }
            }
        } else { // price returned an error so refund the P4D
            require(tokenContract.transfer(receiver, mappedInfo._sentValue));
        }

        _processingP4D = _processingP4D.sub(mappedInfo._sentValue);
        delete _oraclizeCallbackMap[_id];
    }

    /**
     * Should there be any problems with Oraclize such as a callback running out of gas or
     * reverting, you are able to refund the P4D you sent to the contract. This will only
     * work if the __callback() function has not been successful.
     */
    function requestRefund(bytes32 _id) external {
        OraclizeMap memory mappedInfo = _oraclizeCallbackMap[_id];
        address receiver = mappedInfo._sender;
        require(msg.sender == receiver);

        uint256 refundable = mappedInfo._sentValue;
        _processingP4D = _processingP4D.sub(refundable);
        delete _oraclizeCallbackMap[_id];

        require(tokenContract.transfer(receiver, refundable));
    }

    /**
     * Liquidate your shares to P4D
     */
    function withdraw(address _user) external onlyCreator {
        uint256 withdrawableP4D = getWithdrawableOf(_user);
        if (withdrawableP4D > 0) {
            if (_user == _dev) {
                _devBalance = 0;
            } else if (_user == _owner) {
                _ownerBalance = 0;
            } else {
                shares = shares.sub(sharesOf[_user]);
                sharesOf[_user] = 0;
                scalarOf[_user] = 0;
                lastPriceOf[_user] = 0;
                lastPriceTimeOf[_user] = 0;
            }

            require(tokenContract.transfer(_user, withdrawableP4D));

        } else if (sharesOf[_user] == 0) { // they are restarting
            scalarOf[_user] = 0;
            lastPriceOf[_user] = 0;
            lastPriceTimeOf[_user] = 0;
        }
    }

    /**
     * Change the UI visibility of the coin-pair
     * Although a coin-pair may be hidden, a customer can still interact with it without restrictions
     */
    function setVisibility(bool _isVisible) external onlyCreator {
        isVisible = _isVisible;
    }

    /**
     * Ability to change the gas price for callbacks in case the network becomes congested
     */
    function changeOraclizeGasPrice(uint256 _gasPrice) public onlyCreator {
        oraclize_setCustomGasPrice(_gasPrice);
    }

    /**
     * Retrieve the total withdrawable P4D pot
     */
    function getTotalPot() public view returns (uint256) {
        return tokenContract.myTokens().sub(_devBalance).sub(_ownerBalance).sub(_processingP4D.mul(uint256(100).sub(_devOwnerCut)).div(100));
    }

    /**
     * Retrieve the total withdrawable P4D of an individual customer
     */
    function getWithdrawableOf(address _user) public view returns (uint256) {
        if (_user == _dev) {
            return _devBalance;
        } else if (_user == _owner) {
            return _ownerBalance;
        } else {
            return (shares == 0 ? 0 : getTotalPot().mul(sharesOf[_user]).div(shares));
        }
    }

    /**
     * Utility function to convert strings into fixed length byte arrays
     */
    function _stringToBytes32(string memory _s) internal pure returns (bytes32 result) {
        bytes memory tmpEmptyStringTest = bytes(_s);
        if (tmpEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly { result := mload(add(_s, 32)) }
    }

    /**
     * Utility function to make bytes32 data readable
     */
    function _bytes32ToString(bytes32 _b) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 i = 0; i < 32; i++) {
            byte char = byte(bytes32(uint(_b) * 2 ** (8 * i)));
            if (char != 0) {
                bytesString[charCount++] = char;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * Utility function to convert bytes into an integer
     */
    function _bytesToUint(bytes _b) internal pure returns (uint256 result) {
        result = 0;
        for (uint i = 0; i < _b.length; i++) {
            result += uint(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }
    }

    /**
     * Utility function to check if an address is a contract
     */
    function _isContract(address _a) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_a) }
        return size > 0;
    }

    /**
     * Payable function for receiving dividends from the P4D and P3D contracts
     */   
    function () public payable {
        require(msg.sender == address(tokenContract) || msg.sender == address(_P3D) || msg.sender == _dev || msg.sender == _owner);
        // only accept ETH payments from P4D and P3D (subdividends and dividends) as well
        // as allowing the owner or dev to top up this contracts balance
        //
        // all ETH sent through this function will be used in the tokenCallback() function
        // in order to buy more P4D (if there&#39;s excess) and pay for Oraclize calls
    }
}


/**
 * This is the core FluxDelta contract, it is primarily a contract factory that
 * is able to create any number of coin-pair sub-contracts. On top of this, it is
 * also used as an efficient way to return all of the data needed for the front-end.
 */
contract FluxDelta is usingP4D {

    using SafeMath for uint256;

    CoinPair[] private _coinPairs;

    address private _owner;

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    /**
     * Application entry point
     */
    function FluxDelta(address _P4D_address) public usingP4D(_P4D_address) {
        _owner = msg.sender;
    }

    /**
     * Coin-pair creation function, this function will also allow this newly created pair to receive P4D
     * tokens via the setCanAcceptTokens() function. This means that the FluxDetla contract will be
     * granted administrator permissions in the P4D contract although this is the only method it uses.
     */   
    function createCoinPair(string _fromSym, string _toSym, address _ownerAddress) external payable onlyOwner {
        CoinPair newCoinPair = (new CoinPair).value(msg.value)(_fromSym, _toSym, _ownerAddress, _owner, address(tokenContract));
        _coinPairs.push(newCoinPair);

        tokenContract.setCanAcceptTokens(address(newCoinPair));
    }

    /**
     * Liquidates your shares to P4D from a certain coin-pair
     */
    function withdrawFromCoinPair(uint256 _index) external {
        require(_index < getTotalCoinPairs());
        CoinPair coinPair = _coinPairs[_index];
        coinPair.withdraw(msg.sender);
    }

    /**
     * Ability to toggle the UI visibility of a coin-pair
     * This will not prevent a coin-pair from being able to invest or withdraw
     */
    function setCoinPairVisibility(uint256 _index, bool _isVisible) external onlyOwner {
        require(_index < getTotalCoinPairs());
        CoinPair coinPair = _coinPairs[_index];
        coinPair.setVisibility(_isVisible);
    }

    /**
     * Ability to change the callback gas price in case the network gets congested
     */
    function setCoinPairOraclizeGasPrice(uint256 _index, uint256 _gasPrice) public onlyOwner {
        require(_index < getTotalCoinPairs());
        CoinPair coinPair = _coinPairs[_index];
        coinPair.changeOraclizeGasPrice(_gasPrice);
    }

    /**
     * Utility function to bulk set the callback gas price
     */
    function setAllOraclizeGasPrices(uint256 _gasPrice) external onlyOwner {
        for (uint256 i = 0; i < getTotalCoinPairs(); i++) {
            setCoinPairOraclizeGasPrice(i, _gasPrice);
        }
    }

    /**
     * Retreive the total coin-pairs created by FluxDelta
     */
    function getTotalCoinPairs() public view returns (uint256) {
        return _coinPairs.length;
    }

    /**
     * Retreive the total visible coin-pairs
     */
    function getTotalVisibleCoinPairs() internal view returns (uint256 count) {
        count = 0;
        for (uint256 i = 0; i < _coinPairs.length; i++) {
            if (_coinPairs[i].isVisible()) {
                count++;
            }
        }
    }

    /**
     * Utility function for returning all of the core information of the coin-pairs
     */
    function getAllCoinPairs(bool _onlyVisible) public view returns (uint256[] indexes, address[] addresses, bytes32[] fromSyms, bytes32[] toSyms, uint256[] totalShares, uint256[] totalPots) {
        uint256 length = (_onlyVisible ? getTotalVisibleCoinPairs() : getTotalCoinPairs());

        indexes = new uint256[](length);
        addresses = new address[](length);
        fromSyms = new bytes32[](length);
        toSyms = new bytes32[](length);
        totalShares = new uint256[](length);
        totalPots = new uint256[](length);

        uint256 index = 0;
        for (uint256 i = 0; i < getTotalCoinPairs(); i++) {
            CoinPair coinPair = _coinPairs[i];
            if (coinPair.isVisible() || !_onlyVisible) {
                indexes[index] = i;
                addresses[index] = address(coinPair);
                fromSyms[index] = coinPair.fSym();
                toSyms[index] = coinPair.tSym();
                totalShares[index] = coinPair.shares();
                totalPots[index] = coinPair.getTotalPot();

                index++;
            }
        }
    }

    /**
     * Utility function for returning all of the shares information of the coin-pairs of a certain user
     */
    function getAllSharesInfoOf(address _user, bool _onlyVisible) public view returns (uint256[] indexes, uint256[] userShares, uint256[] lastPrices, uint256[] lastPriceTimes, uint256[] withdrawables) {
        uint256 length = (_onlyVisible ? getTotalVisibleCoinPairs() : getTotalCoinPairs());

        indexes = new uint256[](length);
        userShares = new uint256[](length);
        lastPrices = new uint256[](length);
        lastPriceTimes = new uint256[](length);
        withdrawables = new uint256[](length);

        uint256 index = 0;
        for (uint256 i = 0; i < getTotalCoinPairs(); i++) {
            CoinPair coinPair = _coinPairs[i];
            if (coinPair.isVisible() || !_onlyVisible) {
                indexes[index] = i;
                userShares[index] = coinPair.sharesOf(_user);
                lastPrices[index] = coinPair.lastPriceOf(_user);
                lastPriceTimes[index] = coinPair.lastPriceTimeOf(_user);
                withdrawables[index] = coinPair.getWithdrawableOf(_user);

                index++;
            }
        }
    }

    /**
     * Utility function for returning all of the cost information of the coin-pairs of a certain user
     */
    function getAllCostsInfoOf(address _user, bool _onlyVisible) public view returns (uint256[] indexes, uint256[] baseCosts, uint256[] myScalars, uint256[] myCosts, bool[] isShorting) {
        uint256 length = (_onlyVisible ? getTotalVisibleCoinPairs() : getTotalCoinPairs());

        indexes = new uint256[](length);
        baseCosts = new uint256[](length);
        myScalars = new uint256[](length);
        myCosts = new uint256[](length);
        isShorting = new bool[](length);

        uint256 index = 0;
        for (uint256 i = 0; i < getTotalCoinPairs(); i++) {
            CoinPair coinPair = _coinPairs[i];
            if (coinPair.isVisible() || !_onlyVisible) {
                indexes[index] = i;
                baseCosts[index] = coinPair.baseCost();
                myScalars[index] = coinPair.scalarOf(_user);
                myCosts[index] = coinPair.baseCost().mul(coinPair.scalarOf(_user)).div(1e18);
                isShorting[index] = coinPair.isShorting(_user);

                index++;
            }
        }
    }

    /**
     * Because this contract inherits usingP4D it must implement this method
     * Returning false will not allow this contract to receive P4D (only child
     * coin-pair contracts are allowed to receive P4D)
     */
    function tokenCallback(address, uint256, bytes) external returns (bool) { return false; }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b != 0);
    return _a % _b;
  }
}

/*===========================================================================================*
*********************************** https://p4d.io/ropsten ***********************************
*===========================================================================================*/