// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../seriality/Seriality.sol";

/**
 * @title Standard implementation of ERC1643 Document management
 */
contract BatchDocuments is Ownable, Seriality {
    struct Document {
        uint32 docIndex; // Store the document name indexes
        uint64 lastModified; // Timestamp at which document details was last modified
        string data; // data of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(string => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(string => uint32) internal _docIndexes;
    // Array use to store all the document name present in the contracts
    string[] internal _docNames;

    constructor() public Ownable() {}

    // Document Events
    event DocumentRemoved(string indexed _name, string _data);
    event DocumentUpdated(string indexed _name, string _data);

    /**
     * @notice Used to attach a new document to the contract, or update the data or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _data Off-chain data of the document from where it is accessible to investors/advisors to read.
     */
    function _setDocument(string calldata _name, string calldata _data)
        external
        onlyOwner
    {
        require(bytes(_name).length > 0, "Zero name is not allowed");
        require(bytes(_data).length > 0, "Should not be a empty data");
        // Document storage document = _documents[_name];
        if (_documents[_name].lastModified == uint64(0)) {
            _docNames.push(_name);
            _documents[_name].docIndex = uint32(_docNames.length);
        }
        _documents[_name] = Document(
            _documents[_name].docIndex,
            uint64(block.timestamp),
            _data
        );
        emit DocumentUpdated(_name, _data);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */

    function _removeDocument(string calldata _name) external onlyOwner {
        require(
            _documents[_name].lastModified != uint64(0),
            "Document should exist"
        );
        uint32 index = _documents[_name].docIndex - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _documents[_docNames[index]].docIndex = index + 1;
        }
        _docNames.pop();
        emit DocumentRemoved(_name, _documents[_name].data);
        delete _documents[_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`string`).
     * @param _name Name of the document
     * @return string The data associated with the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256)
    {
        return (
            _documents[_name].data,
            uint256(_documents[_name].lastModified)
        );
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return string List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes memory) {
        uint startindex = 0;
        uint endindex = _docNames.length;
        require(endindex >= startindex);

        if (endindex > (_docNames.length - 1)) {
            endindex = _docNames.length - 1;
        }

        uint offset = 64 * ((endindex - startindex) + 1);

        bytes memory buffer = new bytes(offset);
        string memory out1 = new string(32);

        for (uint i = startindex; i <= endindex; i++) {
            out1 = _docNames[i];

            stringToBytes(offset, bytes(out1), buffer);
            offset -= sizeOfString(out1);
        }
        return buffer;
    }

    /**
     * @notice Used to retrieve the total documents in the smart contract.
     * @return uint256 Count of the document names present in the contract.
     */
    function getDocumentCount() external view returns (uint256) {
        return _docNames.length;
    }

    /**
     * @notice Used to retrieve the document name from index in the smart contract.
     * @return string Name of the document name.
     */
    function getDocumentName(uint256 _index)
        external
        view
        returns (string memory)
    {
        require(_index < _docNames.length, "Index out of bounds");
        return _docNames[_index];
    }
}

pragma solidity >=0.5.0;

/**
 * @title BytesToTypes
 * @dev The BytesToTypes contract converts the memory byte arrays to the standard solidity types
 * @author [email protected]
 */

contract BytesToTypes {
    function bytesToAddress(uint _offst, bytes memory _input)
        internal
        pure
        returns (address _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToBool(uint _offst, bytes memory _input)
        internal
        pure
        returns (bool _output)
    {
        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x == 0 ? _output = false : _output = true;
    }

    function getStringSize(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint size)
    {
        assembly {
            size := mload(add(_input, _offst))
            let chunk_count := add(div(size, 32), 1) // chunk_count = size/32 + 1

            if gt(mod(size, 32), 0) {
                // if size%32 > 0
                chunk_count := add(chunk_count, 1)
            }

            size := mul(chunk_count, 32) // first 32 bytes reseves for size in strings
        }
    }

    function bytesToString(
        uint _offst,
        bytes memory _input,
        bytes memory _output
    ) internal pure {
        uint size = 32;
        assembly {
            let chunk_count

            size := mload(add(_input, _offst))
            chunk_count := add(div(size, 32), 1) // chunk_count = size/32 + 1

            if gt(mod(size, 32), 0) {
                chunk_count := add(chunk_count, 1) // chunk_count++
            }

            for {
                let index := 0
            } lt(index, chunk_count) {
                index := add(index, 1)
            } {
                mstore(add(_output, mul(index, 32)), mload(add(_input, _offst)))
                _offst := sub(_offst, 32) // _offst -= 32
            }
        }
    }

    function bytesToBytes32(
        uint _offst,
        bytes memory _input,
        bytes32 _output
    ) internal pure {
        assembly {
            mstore(_output, add(_input, _offst))
            mstore(add(_output, 32), add(add(_input, _offst), 32))
        }
    }

    function bytesToInt8(uint _offst, bytes memory _input)
        internal
        pure
        returns (int8 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt16(uint _offst, bytes memory _input)
        internal
        pure
        returns (int16 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt24(uint _offst, bytes memory _input)
        internal
        pure
        returns (int24 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt32(uint _offst, bytes memory _input)
        internal
        pure
        returns (int32 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt40(uint _offst, bytes memory _input)
        internal
        pure
        returns (int40 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt48(uint _offst, bytes memory _input)
        internal
        pure
        returns (int48 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt56(uint _offst, bytes memory _input)
        internal
        pure
        returns (int56 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt64(uint _offst, bytes memory _input)
        internal
        pure
        returns (int64 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt72(uint _offst, bytes memory _input)
        internal
        pure
        returns (int72 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt80(uint _offst, bytes memory _input)
        internal
        pure
        returns (int80 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt88(uint _offst, bytes memory _input)
        internal
        pure
        returns (int88 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt96(uint _offst, bytes memory _input)
        internal
        pure
        returns (int96 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt104(uint _offst, bytes memory _input)
        internal
        pure
        returns (int104 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt112(uint _offst, bytes memory _input)
        internal
        pure
        returns (int112 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt120(uint _offst, bytes memory _input)
        internal
        pure
        returns (int120 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt128(uint _offst, bytes memory _input)
        internal
        pure
        returns (int128 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt136(uint _offst, bytes memory _input)
        internal
        pure
        returns (int136 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt144(uint _offst, bytes memory _input)
        internal
        pure
        returns (int144 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt152(uint _offst, bytes memory _input)
        internal
        pure
        returns (int152 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt160(uint _offst, bytes memory _input)
        internal
        pure
        returns (int160 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt168(uint _offst, bytes memory _input)
        internal
        pure
        returns (int168 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt176(uint _offst, bytes memory _input)
        internal
        pure
        returns (int176 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt184(uint _offst, bytes memory _input)
        internal
        pure
        returns (int184 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt192(uint _offst, bytes memory _input)
        internal
        pure
        returns (int192 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt200(uint _offst, bytes memory _input)
        internal
        pure
        returns (int200 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt208(uint _offst, bytes memory _input)
        internal
        pure
        returns (int208 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt216(uint _offst, bytes memory _input)
        internal
        pure
        returns (int216 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt224(uint _offst, bytes memory _input)
        internal
        pure
        returns (int224 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt232(uint _offst, bytes memory _input)
        internal
        pure
        returns (int232 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt240(uint _offst, bytes memory _input)
        internal
        pure
        returns (int240 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt248(uint _offst, bytes memory _input)
        internal
        pure
        returns (int248 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt256(uint _offst, bytes memory _input)
        internal
        pure
        returns (int256 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint8(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint8 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint16(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint16 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint24(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint24 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint32(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint32 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint40(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint40 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint48(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint48 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint56(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint56 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint64(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint64 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint72(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint72 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint80(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint80 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint88(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint88 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint96(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint96 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint104(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint104 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint112(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint112 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint120(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint120 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint128(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint128 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint136(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint136 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint144(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint144 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint152(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint152 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint160(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint160 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint168(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint168 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint176(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint176 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint184(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint184 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint192(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint192 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint200(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint200 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint208(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint208 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint216(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint216 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint224(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint224 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint232(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint232 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint240(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint240 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint248(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint248 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint256 _output)
    {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
}

pragma solidity >=0.5.0;

/**
 * @title Seriality
 * @dev The Seriality contract is the main interface for serializing data using the TypeToBytes, BytesToType and SizeOf
 * @author [email protected]
 */

import "./BytesToTypes.sol";
import "./TypesToBytes.sol";
import "./SizeOf.sol";

contract Seriality is BytesToTypes, TypesToBytes, SizeOf {
    constructor() public {}
}

pragma solidity >=0.5.0;

/**
 * @title SizeOf
 * @dev The SizeOf return the size of the solidity types in byte
 * @author [email protected]
 */

contract SizeOf {
    function sizeOfString(string memory _in)
        internal
        pure
        returns (uint _size)
    {
        _size = bytes(_in).length / 32;
        if (bytes(_in).length % 32 != 0) _size++;

        _size++; // first 32 bytes is reserved for the size of the string
        _size *= 32;
    }

    function sizeOfInt(uint16 _postfix) internal pure returns (uint size) {
        assembly {
            switch _postfix
                case 8 {
                    size := 1
                }
                case 16 {
                    size := 2
                }
                case 24 {
                    size := 3
                }
                case 32 {
                    size := 4
                }
                case 40 {
                    size := 5
                }
                case 48 {
                    size := 6
                }
                case 56 {
                    size := 7
                }
                case 64 {
                    size := 8
                }
                case 72 {
                    size := 9
                }
                case 80 {
                    size := 10
                }
                case 88 {
                    size := 11
                }
                case 96 {
                    size := 12
                }
                case 104 {
                    size := 13
                }
                case 112 {
                    size := 14
                }
                case 120 {
                    size := 15
                }
                case 128 {
                    size := 16
                }
                case 136 {
                    size := 17
                }
                case 144 {
                    size := 18
                }
                case 152 {
                    size := 19
                }
                case 160 {
                    size := 20
                }
                case 168 {
                    size := 21
                }
                case 176 {
                    size := 22
                }
                case 184 {
                    size := 23
                }
                case 192 {
                    size := 24
                }
                case 200 {
                    size := 25
                }
                case 208 {
                    size := 26
                }
                case 216 {
                    size := 27
                }
                case 224 {
                    size := 28
                }
                case 232 {
                    size := 29
                }
                case 240 {
                    size := 30
                }
                case 248 {
                    size := 31
                }
                case 256 {
                    size := 32
                }
                default {
                    size := 32
                }
        }
    }

    function sizeOfUint(uint16 _postfix) internal pure returns (uint size) {
        return sizeOfInt(_postfix);
    }

    function sizeOfAddress() internal pure returns (uint8) {
        return 20;
    }

    function sizeOfBool() internal pure returns (uint8) {
        return 1;
    }
}

pragma solidity >=0.5.0;

/**
 * @title TypesToBytes
 * @dev The TypesToBytes contract converts the standard solidity types to the byte array
 * @author [email protected]
 */

contract TypesToBytes {
    function addressToBytes(
        uint _offst,
        address _input,
        bytes memory _output
    ) internal pure {
        assembly {
            mstore(add(_output, _offst), _input)
        }
    }

    function bytes32ToBytes(
        uint _offst,
        bytes32 _input,
        bytes memory _output
    ) internal pure {
        assembly {
            mstore(add(_output, _offst), _input)
            mstore(add(add(_output, _offst), 32), add(_input, 32))
        }
    }

    function boolToBytes(
        uint _offst,
        bool _input,
        bytes memory _output
    ) internal pure {
        uint8 x = _input == false ? 0 : 1;
        assembly {
            mstore(add(_output, _offst), x)
        }
    }

    function stringToBytes(
        uint _offst,
        bytes memory _input,
        bytes memory _output
    ) internal pure {
        uint256 stack_size = _input.length / 32;
        if (_input.length % 32 > 0) stack_size++;

        assembly {
            stack_size := add(stack_size, 1) //adding because of 32 first bytes memory as the length
            for {
                let index := 0
            } lt(index, stack_size) {
                index := add(index, 1)
            } {
                mstore(add(_output, _offst), mload(add(_input, mul(index, 32))))
                _offst := sub(_offst, 32)
            }
        }
    }

    function intToBytes(
        uint _offst,
        int _input,
        bytes memory _output
    ) internal pure {
        assembly {
            mstore(add(_output, _offst), _input)
        }
    }

    function uintToBytes(
        uint _offst,
        uint _input,
        bytes memory _output
    ) internal pure {
        assembly {
            mstore(add(_output, _offst), _input)
        }
    }
}

