/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity > 0.6.1 < 0.7.0;
pragma experimental ABIEncoderV2;
abstract contract solcChecker {
/* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */ function f(bytes calldata x) virtual external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ProvableI {

    function cbAddress() external returns (address _cbAddress);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string calldata _datasource) external returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string calldata _datasource, uint _gasLimit)  external returns (uint _dsprice);
    function queryN(uint _timestamp, string calldata _datasource, bytes calldata _argN) external payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
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

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}
/*
End solidity-cborutils
*/
contract usingProvable {

    using CBOR for Buffer.buffer;

    ProvableI provable;
    OracleAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string provable_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) provable_randomDS_args;
    mapping(bytes32 => bool) provable_randomDS_sessionKeysHashVerified;

    modifier provableAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            provable_setNetwork(networkID_auto);
        }
        if (address(provable) != OAR.getAddress()) {
            provable = ProvableI(OAR.getAddress());
        }
        _;
    }

    modifier provable_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        require(proofVerified);
        _;
    }

    function provable_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID; // NOTE: Silence the warning and remain backwards compatible
      return provable_setNetwork();
    }

    function provable_setNetworkName(string memory _network_name) internal {
        provable_network_name = _network_name;
    }

    function provable_getNetworkName() internal view returns (string memory _networkName) {
        return provable_network_name;
    }

    function provable_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OracleAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            provable_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OracleAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            provable_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OracleAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            provable_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OracleAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            provable_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OracleAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            provable_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OracleAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OracleAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OracleAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }
    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    function __callback(bytes32 _myid, string memory _result) virtual public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) virtual public {
      _myid; _result; _proof;
      provable_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function provable_getPrice(string memory _datasource) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource);
    }

    function provable_getPrice(string memory _datasource, uint _gasLimit) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(0, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(_timestamp, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(_timestamp, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(0, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(0, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(_timestamp, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_setProof(byte _proofP) provableAPI internal {
        return provable.setProofType(_proofP);
    }


    function provable_cbAddress() provableAPI internal returns (address _callbackAddress) {
        return provable.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function provable_setCustomGasPrice(uint _gasPrice) provableAPI internal {
        return provable.setCustomGasPrice(_gasPrice);
    }

    function provable_randomDS_getSessionPubKeyHash() provableAPI internal returns (bytes32 _sessionKeyHash) {
        return provable.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function provable_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = provable_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number(), 1)), xor(coinbase(), timestamp())))
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
        bytes32 queryId = provable_query("random", args, _customGasLimit);
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
        provable_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function provable_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        provable_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function provable_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function provable_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function provable_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (provable_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete provable_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = provable_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize(), sub(msize(), fmem))
        }
    }
}
/**
 * Strings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */
library Strings {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

interface IApeBetPool {
    function depositUserETH() external payable;

    function depositETH(address _sender, uint256 amount) external payable;

    function depositBetToken(address _sender, uint256 amount) external;

    function sendRewards(address payable account, uint256 amount) external;
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract ApeBetBookMaker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct SportEvent {
        bytes16 event_id;
        uint256 event_status;
        uint256 winner;
        string name_home;
        string name_away;
        uint256 score_home;
        uint256 score_away;
        int256 moneyline_home;
        int256 moneyline_away;
        int256 moneyline_draw;
        string event_date;
    }

    struct Bet {
        bytes16 eventInfo;
        uint256 bet_winner;
        int256 bet_moneyline;
        uint256 bet_amount;
        uint256 bet_reserved;
        uint256 bet_payout;
        uint256 bet_timestamp;
        bool bet_claimed;
    }

    IApeBetPool private betPool;
    address payable public betPoolAddress;
    uint256 public affiliate_id;
    uint256 public maxPoolPayout;

    mapping(bytes16 => mapping(uint256 => SportEvent)) public events;
    bytes16[] public availableEvents;

    mapping(bytes16 => Bet) public idToBet;
    mapping(bytes16 => mapping(uint256 => mapping(address => bytes16[])))
        public bets;
    mapping(bytes16 => mapping(uint256 => address[])) private bet_addresses;
    mapping(bytes16 => mapping(uint256 => mapping(address => bool))) private bet_addresses_claimed;
    mapping(address => bytes16[]) public userBetData;
    mapping(bytes16 => mapping(uint256 => mapping(uint256 => uint256))) public teamReserved;

    modifier onlyPoolOwner() {
        require(msg.sender == betPoolAddress, "You have no permission");
        _;
    }

    modifier betsValidation(
        bytes16[] memory _bet_event_ids,
        uint256[] memory winners,
        uint256[] memory amounts
    ) {
        // Check if pool has enough eth to give payouts to users
        uint256 maxPayout = 0;
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            maxPayout = maxPayout
                .add(getPayoutEst(_bet_event_ids[i], winners[i], amounts[i]))
                .sub(amounts[i]);

            require(
                events[_bet_event_ids[i]][affiliate_id].event_status == 1,
                "Event is not available."
            );
        }
        require(maxPayout < maxPoolPayout, "Not enough eth to payout your bet");
        _;
    }

    constructor() public {
        affiliate_id = 0;
        maxPoolPayout = 0;
    }

    function changeAffiliate(uint256 _affiliate_id) external onlyOwner {
        affiliate_id = _affiliate_id;
    }

    function getBetId(bytes16 _event_id, address _account)
        internal
        view
        returns (bytes16 betId)
    {
        betId = bytes16(
            keccak256(
                abi.encodePacked(
                    _event_id,
                    affiliate_id,
                    _account,
                    block.timestamp
                )
            )
        );
    }

    function changeBetPool(address payable _betPoolAddress) external onlyOwner {
        betPool = IApeBetPool(_betPoolAddress);
        betPoolAddress = _betPoolAddress;
        maxPoolPayout = address(betPool).balance;
    }

    function getUserBetHistory(address user)
        external
        view
        returns (Bet[] memory userBets, SportEvent[] memory userEvents)
    {
        userBets = new Bet[](userBetData[user].length);
        userEvents = new SportEvent[](userBetData[user].length);
        for (uint256 i = 0; i < userBetData[user].length; i++) {
            userBets[i] = idToBet[userBetData[user][i]];
            userEvents[i] = events[userBets[i].eventInfo][affiliate_id];
        }
        return (userBets, userEvents);
    }

    function getCollectableRewards(address user)
        external
        view
        returns (uint256 totalPayouts)
    {
        totalPayouts = 0;
        for (uint256 i = 0; i < userBetData[user].length; i++) {
            Bet storage bet = idToBet[userBetData[user][i]];
            SportEvent memory ev = events[bet.eventInfo][affiliate_id];

            if (
                ev.event_status == 2 &&
                ev.winner == bet.bet_winner &&
                bet.bet_claimed == false
            ) {
                totalPayouts = totalPayouts.add(
                    bet
                        .bet_amount
                        .mul(convertOddsFormat(bet.bet_moneyline))
                        .div(1e4)
                );
            }
        }
        return totalPayouts;
    }

    function collectRewards() external {
        uint256 totalPayouts = 0;
        for (uint256 i = 0; i < userBetData[msg.sender].length; i++) {
            Bet storage bet = idToBet[userBetData[msg.sender][i]];
            if (
                events[bet.eventInfo][affiliate_id].event_status == 2 &&
                events[bet.eventInfo][affiliate_id].winner == bet.bet_winner
            ) {
                bet.bet_payout = bet
                    .bet_amount
                    .mul(convertOddsFormat(bet.bet_moneyline))
                    .div(1e4);
                bet.bet_claimed = true;
                totalPayouts = totalPayouts.add(bet.bet_payout);
            }
        }

        betPool.sendRewards(msg.sender, totalPayouts);
    }

    // This function is used for converting only American format to European format
    function convertOddsFormat(int256 odds) internal pure returns (uint256) {
        uint256 payout = 0;
        uint256 bet = 0;
        if (odds < 0) {
            payout = uint256(100 - odds);
            bet = uint256(-odds);
        } else {
            payout = uint256(100 + odds);
            bet = 100;
        }

        return payout.mul(1e4).div(bet);
    }

    // for temporary use till chainlink is available to use
    function updateEvents(
        bytes16[] memory _event_ids,
        uint256[] memory _event_statuss,
        uint256[] memory _winners,
        string[] memory _name_homes,
        string[] memory _name_aways,
        uint256[] memory _score_aways,
        uint256[] memory _score_homes,
        int256[] memory _moneyline_homes,
        int256[] memory _moneyline_aways,
        int256[] memory _moneyline_draws,
        string[] memory _dates
    ) external {
        for (uint256 i = 0; i < _event_ids.length; i++) {
            if (events[_event_ids[i]][affiliate_id].event_status == 0) {
                availableEvents.push(_event_ids[i]);
            }
            
            if (events[_event_ids[i]][affiliate_id].event_status == 2) continue;
            
            if (events[_event_ids[i]][affiliate_id].event_status == _event_statuss[i]) {
                events[_event_ids[i]][affiliate_id].moneyline_home = _moneyline_homes[i];
                events[_event_ids[i]][affiliate_id].moneyline_away = _moneyline_aways[i];
            } else {
                events[_event_ids[i]][affiliate_id] = SportEvent({
                    event_id: _event_ids[i],
                    event_status: _event_statuss[i],
                    winner: _winners[i],
                    name_away: _name_aways[i],
                    name_home: _name_homes[i],
                    score_away: _score_aways[i],
                    score_home: _score_homes[i],
                    moneyline_home: _moneyline_homes[i],
                    moneyline_away: _moneyline_aways[i],
                    moneyline_draw: _moneyline_draws[i],
                    event_date: _dates[i]
                });   
            }

            if (events[_event_ids[i]][affiliate_id].event_status == 2) {
                bytes16 event_id = _event_ids[i];
                uint256 paidForEvt = 0;
                for (
                    uint256 j = 0;
                    j < bet_addresses[event_id][affiliate_id].length;
                    j++
                ) {
                    address account = bet_addresses[event_id][affiliate_id][j];
                    for (
                        uint256 k = 0;
                        k < bets[event_id][affiliate_id][account].length;
                        k++
                    ) {
                        if (
                            idToBet[bets[event_id][affiliate_id][account][k]].bet_winner != events[event_id][affiliate_id].winner
                        ) {
                            maxPoolPayout = maxPoolPayout.add(
                                idToBet[
                                    bets[event_id][affiliate_id][account][k]
                                ]
                                    .bet_amount
                            );
                        } else {
                            paidForEvt = paidForEvt.add(idToBet[bets[event_id][affiliate_id][account][k]].bet_reserved.sub(idToBet[bets[event_id][affiliate_id][account][k]].bet_amount));
                        }
                    }
                }
                if (teamReserved[event_id][affiliate_id][1] > teamReserved[event_id][affiliate_id][2]) {
                    maxPoolPayout = maxPoolPayout.add(teamReserved[event_id][affiliate_id][1].sub(paidForEvt));
                } else {
                    maxPoolPayout = maxPoolPayout.add(teamReserved[event_id][affiliate_id][2].sub(paidForEvt));
                }
            }
        }
    }

    function getAvailableEvents()
        external
        view
        returns (SportEvent[] memory evts)
    {
        evts = new SportEvent[](availableEvents.length);
        uint256 idx = 0;
        for (uint256 i = 0; i < availableEvents.length; i++) {
            if (events[availableEvents[i]][affiliate_id].event_status == 1)
                evts[idx++] = events[availableEvents[i]][affiliate_id];
        }
        return evts;
    }

    function getPayoutEst(
        bytes16 _bet_event_id,
        uint256 winner,
        uint256 amount
    ) public view returns (uint256) {
        uint256 maxPayout;

        // winner: 1 (home),  winner: 2(away),   winner: 3(draw)

        SportEvent memory ev = events[_bet_event_id][affiliate_id];
        if (winner == 1) {
            maxPayout = convertOddsFormat(ev.moneyline_home).mul(amount).div(
                1e4
            );
        } else if (winner == 2) {
            maxPayout = convertOddsFormat(ev.moneyline_away).mul(amount).div(
                1e4
            );
        } else {
            maxPayout = convertOddsFormat(ev.moneyline_draw).mul(amount).div(
                1e4
            );
        }
        return maxPayout;
    }

    receive() external payable {}

    function updateMaxPoolPayout(uint256 addAmount, uint256 removeAmount)
        external
        onlyPoolOwner
    {
        if (addAmount > 0) maxPoolPayout = maxPoolPayout.add(addAmount);
        else maxPoolPayout = maxPoolPayout.sub(removeAmount);
    }

    function createBets(
        bytes16[] memory _bet_event_ids,
        uint256[] memory _bet_winners,
        uint256[] memory _bet_amounts
    )
        external
        payable
        nonReentrant
        betsValidation(_bet_event_ids, _bet_winners, _bet_amounts)
    {
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            bytes16 bet_id = getBetId(_bet_event_ids[i], msg.sender);
            uint256 estPayout =
                getPayoutEst(
                    _bet_event_ids[i],
                    _bet_winners[i],
                    _bet_amounts[i]
                );
            bets[_bet_event_ids[i]][affiliate_id][msg.sender].push(bet_id);

            idToBet[bet_id] = Bet({
                eventInfo: _bet_event_ids[i],
                bet_winner: _bet_winners[i],
                bet_amount: _bet_amounts[i],
                bet_timestamp: block.timestamp,
                bet_moneyline: _bet_winners[i] == 1
                    ? events[_bet_event_ids[i]][affiliate_id].moneyline_home
                    : events[_bet_event_ids[i]][affiliate_id].moneyline_away,
                bet_payout: 0,
                bet_reserved: estPayout,
                bet_claimed: false
            });

            if (bet_addresses_claimed[_bet_event_ids[i]][affiliate_id][msg.sender] != true) {
                bet_addresses[_bet_event_ids[i]][affiliate_id].push(msg.sender);
                bet_addresses_claimed[_bet_event_ids[i]][affiliate_id][msg.sender] = true;
            }

            userBetData[msg.sender].push(bet_id);

            uint256 reservedAmount = estPayout.sub(_bet_amounts[i]);
            if (teamReserved[_bet_event_ids[i]][affiliate_id][1] > teamReserved[_bet_event_ids[i]][affiliate_id][2])
                maxPoolPayout = maxPoolPayout.add(teamReserved[_bet_event_ids[i]][affiliate_id][1]);
            else
                maxPoolPayout = maxPoolPayout.add(teamReserved[_bet_event_ids[i]][affiliate_id][2]);
            
            teamReserved[_bet_event_ids[i]][affiliate_id][_bet_winners[i]] = teamReserved[_bet_event_ids[i]][affiliate_id][_bet_winners[i]].add(reservedAmount);

            if (teamReserved[_bet_event_ids[i]][affiliate_id][1] > teamReserved[_bet_event_ids[i]][affiliate_id][2])
                maxPoolPayout = maxPoolPayout.sub(teamReserved[_bet_event_ids[i]][affiliate_id][1]);
            else
                maxPoolPayout = maxPoolPayout.sub(teamReserved[_bet_event_ids[i]][affiliate_id][2]);
            require(maxPoolPayout >= 0, "Exceeded reserved amount.");
        }

        betPool.depositUserETH{value: msg.value}();
    }
}


contract ApeEventFetcher is Ownable, usingProvable {
    using Strings for string;
    mapping (bytes32 => bool) public pendingQueries;
    event LogNewProvableQuery(string description);
    event LogResult(string result);
    ApeBetBookMaker public bookMaker;
    
    string[] parts;
    string[] subParts;

    bytes16[] _event_ids;
    uint256[] _event_statuss;
    uint256[] _winners;
    string[] _name_homes;
    string[] _name_aways;
    uint256[] _score_aways;
    uint256[] _score_homes;
    int256[] _moneyline_homes;
    int256[] _moneyline_aways;
    int256[] _moneyline_draws;
    string[] _dates;
    
    string public ipfs;
    uint256 public userFee = 0.027 ether;
    uint public lastFee = 0;
    uint public lastthis = 0;
    
    uint public CUSTOM_GASPRICE = 20000000000;

    constructor() public {
        provable_setProof(proofType_Android | proofStorage_IPFS);
    }
    
    function updateIPFS(string memory newIPFS) external onlyOwner {
        ipfs = newIPFS;
    }
    
    function updateUserFee(uint256 fee) external onlyOwner {
        userFee = fee;
    }
    
    function changeGasPrice(uint gasPrice) external onlyOwner {
        CUSTOM_GASPRICE = gasPrice;
        provable_setCustomGasPrice(CUSTOM_GASPRICE);
    }
    
    
    function changeBookMaker(address payable addr) external onlyOwner  {
        bookMaker = ApeBetBookMaker(addr);
    }
    
    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
    }
    
    function bytesToBytes16(bytes memory  b, uint offset) private pure returns (bytes16) {
      bytes16 out;
    
      for (uint i = 0; i < 16; i++) {
        out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
    
    function stringToBytes(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
    
    function stringToUint(string memory s) internal pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
    
    function stringToInt(string memory s) internal pure returns (int result) {
        bytes memory b = bytes(s);
        uint i;
        uint num = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                num = num * 10 + (c - 48);
            }
        }
        
        if (b[0] == 0x2d)
            result = (-int(num));
        else
            result = int(num);
    }
    
    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }
    
    receive() external payable {}
    
    function __callback(bytes32 myid, string memory result, bytes memory _proof) public override {
        if (msg.sender != provable_cbAddress()) revert();
        require (pendingQueries[myid] == true);
        
        emit LogResult(result);
        if (address(bookMaker) != 0x0000000000000000000000000000000000000000 && bytes(result).length > 0) {
            parts = result.split("$");
        
            delete _event_ids;
            delete _event_statuss;
            delete _winners;
            delete _name_homes;
            delete _name_aways;
            delete _score_aways;
            delete _score_homes;
            delete _moneyline_homes;
            delete _moneyline_aways;
            delete _moneyline_draws;
            delete _dates;
            
            for (uint i = 0 ; i < parts.length-1 ; i ++) {
                subParts = parts[i].split(";");
                if (subParts.length > 0) {
                    _event_ids.push(bytesToBytes16(stringToBytes(subParts[0]), 0));
                    _event_statuss.push(stringToUint(subParts[1]));
                    _winners.push(stringToUint(subParts[2]));
                    _name_homes.push(subParts[3]);
                    _name_aways.push(subParts[4]);
                    _score_homes.push(stringToUint(subParts[5]));
                    _score_aways.push(stringToUint(subParts[6]));
                    _moneyline_homes.push(stringToInt(subParts[7]));
                    _moneyline_aways.push(stringToInt(subParts[8]));
                    _moneyline_draws.push(0);
                    _dates.push(subParts[9]);
                }
            }
            if (_event_ids.length > 0) {
                bookMaker.updateEvents(
                    _event_ids,
                    _event_statuss,
                    _winners,
                    _name_homes,
                    _name_aways,
                    _score_aways,
                    _score_homes,
                    _moneyline_homes,
                    _moneyline_aways,
                    _moneyline_draws,
                    _dates
                );
            }
        }
        
        delete pendingQueries[myid]; // This effectively marks the query id as processed.
    }

    function request(
        string memory _query,
        string memory _dateStr,
        uint256 gasLimit
    )
        public
        payable
    {
        uint est = provable_getPrice("computation", gasLimit);
        lastFee = est;
        lastthis = address(this).balance;
        if (est > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
            revert();
        } else {
            emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
            bytes32 queryId = provable_query("computation",
                [_query, _dateStr],
                gasLimit
            );
            pendingQueries[queryId] = true;
        }
    }
    
    function requestData(string memory _dateStr, uint256 gasLimit)
        public
        payable
    {
        require(userFee <= msg.value, 'Insufficient user fee');
        request(ipfs,
                _dateStr,
                gasLimit);
    }
}