pragma solidity ^0.4.20;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint capacity) internal constant {
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private constant {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private constant returns(uint) {
        if(a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Appends a byte array to the end of the buffer. Reverts if doing so
     *      would exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, bytes data) internal constant returns(buffer memory) {
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
     * @dev Appends a byte to the end of the buffer. Reverts if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, uint8 data) internal constant {
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
     * @dev Appends a byte to the end of the buffer. Reverts if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal constant returns(buffer memory) {
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

    function shl8(uint8 x, uint8 y) private constant returns (uint8) {
        return x * (2 ** y);
    }

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private constant {
        if(value <= 23) {
            buf.append(uint8(shl8(major, 5) | value));
        } else if(value <= 0xFF) {
            buf.append(uint8(shl8(major, 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.append(uint8(shl8(major, 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.append(uint8(shl8(major, 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8(shl8(major, 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private constant {
        buf.append(uint8(shl8(major, 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal constant {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal constant {
        if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal constant {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal constant {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal constant {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal constant {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal constant {
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
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
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
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
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

    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }

    function oraclize_useCoupon(string code) oraclizeAPI internal {
        oraclize.useCoupon(code);
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
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal returns (address){
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

    function strCompare(string _a, string _b) internal returns (int) {
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

    function indexOf(string _haystack, string _needle) internal returns (int) {
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

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string) {
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

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (uint) {
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

    function uint2str(uint i) internal returns (string){
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
    function stra2cbor(string[] arr) internal constant returns (bytes) {
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeString(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] arr) internal constant returns (bytes) {
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

    function oraclize_getNetworkName() internal returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        if ((_nbytes == 0)||(_nbytes > 32)) throw;
	// Convert from seconds to ledger timer ticks
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
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

        oraclize_randomDS_setCommitment(queryId, sha3(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
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
        if (address(sha3(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(sha3(pubkey)) == signer);
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
        tosign2[0] = 1; //role
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
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) throw;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) throw;

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal returns (bool){
        bool match_ = true;

	if (prefix.length != n_random_bytes) throw;

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
        if (!(sha3(keyhash) == sha3(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, sha3(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == sha3(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
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
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal returns (bytes) {
        uint minLength = length + toOffset;

        if (to.length < minLength) {
            // Buffer too small
            throw; // Should be a better way?
        }

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

}


contract Cryptodraw is usingOraclize {
    address private contractOwner;
    address[] private playerList;

    // Oracle to query WolframAlpha
    string private wolframRandom;
    event newWolframRandom(string wolframRandom);
    
    // Public seed of the previous round
    string private previousSeed;
    bytes32 private previousHash;
    uint private previousHashUint;
    uint private previousWinner;
    
    // Winner variable
    uint private winner;
    // Ticketprice per entry
    uint constant ticketPrice = 0.01 ether;
    // Maximum of players to join
    uint constant maxPlayers = 10;
    // Maximum of players to join
    uint constant Fee = 4;
    // Track the poolround
    uint round = 1;
    //Declare owners address
    address poolOwner = msg.sender;
    // Declare timestamp 
    uint timestamp = now + 2 weeks;

    // Contructor to initiate the conatract
    function Cryptodraw() public {
        contractOwner = msg.sender;
        oraclize_setCustomGasPrice(5000000000 wei);
    }
    
    modifier restricted() {
        require(msg.sender == contractOwner);
        _;
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        wolframRandom = result;
        newWolframRandom(wolframRandom);
        uint ownerFee = address(this).balance / 100 * Fee;
        uint totalPayout = address(this).balance - ownerFee;
        // Pick the winner of the lottery
        winner = calculateHash() % playerList.length;
        // Send reward to the winner
        playerList[winner].transfer(totalPayout);
        // Send reward to the contractOwner
        poolOwner.transfer(ownerFee);
        
        // List the previous seed to verify results 
        previousSeed = wolframRandom;
        previousHash = keccak256(wolframRandom);
        previousHashUint = uint(keccak256(wolframRandom));
        previousWinner = winner;
        
        // Clear the current addresses so pool can restart
        playerList = new address[](0);

        // Set some round specific stuff
        round += 1;      
        timestamp = now + 2 weeks;
    }
    
    function joinLottery() public payable {
        if (playerList.length < maxPlayers) {
            require(msg.value == ticketPrice);
            playerList.push(msg.sender);
        }
        else {
            revert();
        }
    }

    // Calculating hash with a oracilize seed (Wolfram)
    function calculateHash() internal returns (uint) {
        return uint(keccak256(wolframRandom));
    }
    
    function update() payable {
        if (playerList.length == maxPlayers || now > timestamp) {
            if (oraclize_getPrice("URL") > this.balance) {
            // "Oraclize query was NOT sent, please add some ETH to cover for the query fee
            } 
            else {
            // Oraclize can be queried
            oraclize_query("WolframAlpha", "Give me 20 random words", 700000);
            }
        }
        else {
            revert();
        }
    }
    
    function notSameSeed (string a, string b) private view returns (bool) {
       return keccak256(a) != keccak256(b);
   }
    
    function getPreviousSeed() public view returns (string) {
        return previousSeed;
    }
    
    function getHash() public view returns (bytes32) {
        return previousHash;
    }
    
    function getPreviousHashUint() public view returns (uint) {
        return previousHashUint;
    }
    
    function getPlayerLength() public view returns (uint) {
        return playerList.length;
    }
    
    function getPreviousWinner() public view returns (uint) {
        return previousWinner;
    }
    
    
     // Return list of players
    function getPlayers() public view returns (address[]) {
        return playerList;
    }
    
    // Return list of players
    function getTime() public view returns (uint) {
        return timestamp;
    }
    

    //Return max entries
    function getMaxTickets() public view returns (uint) {
        return maxPlayers;
    }
    
        //Return max entries
    function getRound() public view returns (uint) {
        return round;
    }
    
        //Return tickets left in the contract
    function getTicketsLeft() public view returns (uint) {
        return maxPlayers - playerList.length;
    }
    
        //Get total lottery amount
    function getLotteryBalance() public view returns (uint) {
        return address(this).balance;
    }
    
            //Get total lottery amount
    function getTicketPrice() public view returns (uint) {
        return ticketPrice;
    }
    
}