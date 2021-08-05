/**
 *Submitted for verification at Etherscan.io on 2021-01-05
*/

// File: contracts\openzeppelin\contracts\GSN\Context.sol

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

// File: contracts\openzeppelin\contracts\access\Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        revert("Renouncing ownership is blocked");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: owner is 0x0 address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\lib\Helpers.sol

pragma solidity >=0.6.0 <0.8.0;

library Helpers {
    function genUnencodedIntAddress(
        bytes1 netByte,
        bytes32 pubSpend,
        bytes32 pubView,
        bytes8 pId
    ) internal pure returns (bytes memory) {
        bytes memory preAddr = abi.encodePacked(
            netByte,
            pubSpend,
            pubView,
            pId
        );
        bytes4 preAddrHash = bytes4(
            keccak256(preAddr) &
                0xffffffff00000000000000000000000000000000000000000000000000000000
        );
        return abi.encodePacked(preAddr, preAddrHash);
    }

    function padLeft(
        bytes memory source,
        bytes1 padChar,
        uint8 maxLen
    ) internal pure returns (bytes memory) {
        uint256 sourceLen = source.length;
        if (sourceLen >= maxLen) return source;

        bytes memory res = new bytes(maxLen);
        for (uint256 i = 0; i < maxLen; i++) {
            if (i < sourceLen) res[i] = source[i];
            else res[i] = padChar;
        }

        return res;
    }

    function padRight(
        bytes memory source,
        bytes1 padChar,
        uint8 maxLen
    ) internal pure returns (bytes memory) {
        uint256 sourceLen = source.length;
        if (sourceLen >= maxLen) return source;

        bytes memory res = new bytes(maxLen);
        for (uint256 i = 0; i < maxLen; i++) {
            if (i < maxLen - sourceLen) res[i] = padChar;
            else res[i] = source[i - (maxLen - sourceLen)];
        }

        return res;
    }

    function hashEquals(bytes memory left, bytes memory right)
        internal
        pure
        returns (bool)
    {
        if (left.length != right.length) return false;
        for (uint256 i = 0; i < left.length; i++)
            if (uint8(left[i]) - uint8(right[i]) != 0) return false;
        return true;
    }

    function toBytes(uint256 _i) internal pure returns (bytes memory) {
        if (_i == 0) return "0";

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return bstr;
    }

    function random() internal view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.difficulty)
                    )
                ) % 0xFF
            );
    }

    function random(uint256 height) internal view returns (bytes8) {
        return
            bytes8(
                uint64(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                height
                            )
                        )
                    ) % 0xFFFFFFFFFFFFFFFF
                )
            );
    }
}

// File: contracts\lib\Monero.sol

pragma solidity >=0.6.0 <0.8.0;


library Monero {
    using Helpers for bytes;
    using Helpers for uint256;

    uint8 constant full_block_size = 8;
    uint8 constant full_encoded_block_size = 11;
    bytes constant Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    bytes9 constant encoded_block_sizes = 0x000203050607090a0b;

    function b58_encode(bytes memory data) internal pure returns (bytes memory) {
        uint256 full_block_count = data.length / full_block_size;
        uint256 last_block_size = data.length % full_block_size;

        uint256 res_size = (full_block_count * full_encoded_block_size) +
            uint8(encoded_block_sizes[last_block_size]);

        bytes memory res = new bytes(res_size);

        for (uint256 i = 0; i < res_size; ++i) {
            res[i] = Alphabet[0];
        }

        for (uint256 i = 0; i < full_block_count; i++) {
            res = encodeBlock(
                subarray(
                    data,
                    i * full_block_size,
                    i * full_block_size + full_block_size
                ),
                res,
                i * full_encoded_block_size
            );
        }
        if (last_block_size > 0) {
            res = encodeBlock(
                subarray(
                    data,
                    full_block_count * full_block_size,
                    full_block_count * full_block_size + last_block_size
                ),
                res,
                full_block_count * full_encoded_block_size
            );
        }

        return res;
    }

    function b58_decode(bytes memory data) internal pure returns (bytes memory) {
        require(data.length > 0, "Invalid address length");

        uint256 full_block_count = data.length / full_encoded_block_size;
        uint256 last_block_size = data.length % full_encoded_block_size;

        int256 lbds = indexOf(encoded_block_sizes, uint8(last_block_size));

        require(lbds > 0, "Invalid encoded length");
        uint256 last_block_decoded_size = uint256(lbds);

        uint256 res_size = full_block_count *
            full_block_size +
            last_block_decoded_size;

        bytes memory res = new bytes(res_size);

        for (uint256 i = 0; i < full_block_count; i++) {
            res = decodeBlock(
                subarray(
                    data,
                    i * full_encoded_block_size,
                    i * full_encoded_block_size + full_encoded_block_size
                ),
                res,
                i * full_block_size
            );
        }
        if (last_block_size > 0) {
            res = decodeBlock(
                subarray(
                    data,
                    full_block_count * full_encoded_block_size,
                    full_block_count * full_encoded_block_size + last_block_size
                ),
                res,
                full_block_count * full_block_size
            );
        }

        return res;
    }

    function encodeBlock(
        bytes memory data,
        bytes memory buf,
        uint256 index
    ) private pure returns (bytes memory) {
        require(
            data.length > 1 || data.length <= full_block_size,
            "Invalid block length"
        );

        uint64 num = toUint64(data);

        uint256 i = uint8(encoded_block_sizes[data.length]) - 1;

        while (num > 0) {
            uint256 remainder = num % Alphabet.length;
            num = uint64(num / Alphabet.length);
            buf[index + i] = Alphabet[remainder];
            i--;
        }
        return buf;
    }

    function decodeBlock(
        bytes memory data,
        bytes memory buf,
        uint256 index
    ) private pure returns (bytes memory) {
        require(
            data.length > 1 && data.length <= full_encoded_block_size,
            "Invalid block length"
        );

        int256 res = indexOf(encoded_block_sizes, uint8(data.length));
        require(res > 0, "Invalid encoded length");

        uint256 res_size = uint256(res);
        uint256 res_num = 0;
        uint256 order = 1;

        for (uint256 i = data.length; i > 0; i--) {
            int256 digit = indexOf(Alphabet, uint8(data[i - 1]));
            require(digit >= 0, "Invalid symbol");

            res_num = (order * uint8(digit)) + res_num;
            require(res_num < 2**64, "Overflow1");
            order = order * Alphabet.length;
        }
        if (res_size < full_block_size && 2**(8 * res_size) <= res_num)
            revert("Overflow2 ");

        for (uint256 i = res_size; i > 0; i--) {
            buf[index + i - 1] = bytes1(uint8(res_num % 0x100));
            res_num = res_num / 0x100;
        }
        return buf;
    }

    function validateHex(bytes memory xmrAddress, bytes3 netBytes) internal pure {
        bytes1 _netByteStd = netBytes[0];
        bytes1 _netByteInt = netBytes[1];
        bytes1 _netByteSub = netBytes[2];

        require(
            xmrAddress.length == 69 || xmrAddress.length == 77,
            "Invalid address length"
        );
        require(
            xmrAddress[0] == _netByteStd ||
                xmrAddress[0] == _netByteInt ||
                xmrAddress[0] == _netByteSub,
            "Invalid network byte"
        );
        require(
            (xmrAddress.length == 69 &&
                (xmrAddress[0] == _netByteStd ||
                    xmrAddress[0] == _netByteSub)) ||
                (xmrAddress.length == 77 && xmrAddress[0] == _netByteInt),
            "Invalid address type"
        );

        bytes memory preAddr = slice(xmrAddress, 0, xmrAddress.length - 4);
        bytes memory preHash = slice(xmrAddress, xmrAddress.length - 4, 4);
        bytes memory calcHash = abi.encodePacked(
            bytes4(
                keccak256(preAddr) &
                    0xffffffff00000000000000000000000000000000000000000000000000000000
            )
        );
        require(hashEquals(preHash, calcHash), "Invalid address hash");
    }

    function encodeAddress(
        bytes memory xmrAddress,
        bytes3 netBytes,
        bool validate
    ) internal pure returns (bytes memory) {
        if (validate) validateHex(xmrAddress, netBytes);
        return b58_encode(xmrAddress);
    }

    function decodeAddress(
        bytes memory xmrAddress,
        bytes3 netBytes,
        bool validate
    ) internal pure returns (bytes memory) {
        if (validate) validateHex(xmrAddress, netBytes);
        return b58_encode(xmrAddress);
    }

    function toStringAmount(uint256 amount)
        internal
        pure
        returns (string memory)
    {
        uint256 amt = amount / 1000000000000;
        uint256 rem = amount % 1000000000000;
        string memory amts = string(amt.toBytes());
        string memory rems = string(rem.toBytes().padRight(bytes1("0"), 12));
        return string(abi.encodePacked(amts, ".", rems));
    }

    function slice(
        bytes memory source,
        uint256 start,
        uint256 length
    ) private pure returns (bytes memory) {
        require(source.length >= start + length, "Slice out of bounds");

        bytes memory tmpBytes = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            tmpBytes[i] = source[start + i];
        }
        return tmpBytes;
    }

    function hashEquals(bytes memory left, bytes memory right)
        private
        pure
        returns (bool)
    {
        if (left.length != right.length) return false;
        for (uint256 i = 0; i < left.length; i++)
            if (uint8(left[i]) - uint8(right[i]) != 0) return false;
        return true;
    }

    function toUint64(bytes memory _bytes) private pure returns (uint64) {
        uint64 tempUint;
        uint256 len = _bytes.length;
        uint256 start = 8 - len;
        assembly {
            tempUint := mload(add(add(_bytes, len), start))
        }
        tempUint = tempUint >> (start * 8);
        return tempUint;
    }

    function subarray(
        bytes memory data,
        uint256 begin,
        uint256 end
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(end - begin);
        for (uint256 i = 0; i < end - begin; i++) {
            out[i] = data[i + begin];
        }
        return out;
    }

    function toBytes(bytes32 input) private pure returns (bytes memory) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = input[i];
        }
        return output;
    }

    function equal(bytes memory one, bytes memory two)
        private
        pure
        returns (bool)
    {
        if (!(one.length == two.length)) {
            return false;
        }
        for (uint8 i = 0; i < one.length; i++) {
            if (!(one[i] == two[i])) {
                return false;
            }
        }
        return true;
    }

    function truncate(uint8[] memory array, uint8 length)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint8 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint8 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function toAlphabet(uint8[] memory indices)
        private
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint8 i = 0; i < indices.length; i++) {
            output[i] = Alphabet[indices[i]];
        }
        return output;
    }

    function indexOf(bytes9 array, uint8 v) private pure returns (int256) {
        for (uint256 i = 0; i < 9; i++) {
            if (uint8(array[i]) == v) return int256(i);
        }
        return -1;
    }

    function indexOf(bytes memory array, uint8 v)
        private
        pure
        returns (int256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (uint8(array[i]) == v) return int256(i);
        }
        return -1;
    }

    function random() internal view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.difficulty)
                    )
                ) % 0xFF
            );
    }

    function random(uint256 height) internal view returns (bytes8) {
        return
            bytes8(
                uint64(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                height
                            )
                        )
                    ) % 0xFFFFFFFFFFFFFFFF
                )
            );
    }
}

// File: contracts\IWXMRAddress.sol

pragma solidity >=0.6.0 <0.8.0;

interface IWXMRAddress{
    /**
     * @dev Returns an account or integrated address
     */
    function getAddress() external returns (bytes memory xmrAddress);
    function validateAddress(bytes memory xmrAddress, bool decode) external;
    function b58_encode(bytes memory xmrAddress) external view returns(bytes memory);
    function b58_decode(bytes memory xmrAddress) external view returns(bytes memory);
    function encodeAddress(bytes memory xmrAddress) external view returns(bytes memory);
    function decodeAddress(bytes memory xmrAddress) external view returns(bytes memory);
}

// File: contracts\WXMRAddress.sol

pragma solidity >=0.6.0 <0.8.0;



contract WXMRAddress is Context, Ownable, IWXMRAddress {
    address private _wxmr;

    bytes3 private _netBytes;
    bytes32 private _pubSpend;
    bytes32 private _pubView;
    uint256 private _intHeight;
    bool private _intAddressEnabled = false;

    bytes[] _xmrPool;

    constructor (address wxmr) {
        _wxmr = wxmr;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWxmr() {
        require(_wxmr == _msgSender(), "Ownable: caller is not WXMR");
        _;
    }

    /*
     * @dev Function to set integrated addresses parameters
     */
    function setParameters(
        bytes3 netBytes,
        bytes32 pubSpend,
        bytes32 pubView,
        uint256 initialHeight,
        bool intAddressEnabled
    ) public onlyOwner {
        _netBytes = netBytes;
        _pubSpend = pubSpend;
        _pubView = pubView;

        if (initialHeight > 0)
            _intHeight = initialHeight;

        _intAddressEnabled = intAddressEnabled;
        emit SetParameters(netBytes, pubSpend, pubView, intAddressEnabled);
    }

    /*
     * @dev Function to get xmr addresses
     */
    function getAddress() override public onlyWxmr returns (bytes memory xmrAddress) {
        if (_intAddressEnabled)
            return getXmrIntegratedAddress();
        return getXmrAddress();
    }

    /*
     * @dev Function to validate xmr addresses
     */
    function validateAddress(bytes memory xmrAddress,bool decode) override public view onlyWxmr {
        if (decode)
            xmrAddress = Monero.b58_decode(xmrAddress);
        Monero.validateHex(xmrAddress,_netBytes);
    }
     /*
     * @dev Function to get address from pool
     */
    function getXmrAddress() private returns (bytes memory) {
        require(_xmrPool.length > 0, "No address available");

        bytes memory xmrAddress = _xmrPool[_xmrPool.length - 1];
        _xmrPool.pop();
        emit PoolSize(_xmrPool.length);

        return xmrAddress;
    }

    /*
     * @dev Function to get integrated address
     */
    function getXmrIntegratedAddress() private returns (bytes memory) {
        _intHeight += Helpers.random();
        bytes8 pId = Helpers.random(_intHeight);
        return Helpers.genUnencodedIntAddress(
            _netBytes[1],
            _pubSpend,
            _pubView,
            pId
        );
    }

    /**
     * @dev Function get size of address pool
     *     *
     */
    function getPoolSize() public view onlyOwner returns (uint256){
        return _xmrPool.length;
    }

    /**
     * @dev Function empty address pool
     *     *
     */
    function flushPool() public onlyOwner{
        _xmrPool = new bytes[](0);
    }

    /**
     * @dev Function address to pool
     *     *
     */
    function pushAddress(bytes memory xmrAddress) public onlyOwner{
        _xmrPool.push(xmrAddress);
        emit PoolSize(_xmrPool.length);
    }

    /**
     * @dev Function base58 encode XMR address
     *     *
     */
    function b58_encode(bytes memory xmrAddress) override public pure returns(bytes memory){
        return Monero.b58_encode(xmrAddress);
    }
    
    /**
     * @dev Function base58 decode XMR address
     *     *
     */
    function b58_decode(bytes memory xmrAddress) override public pure returns(bytes memory){
        return Monero.b58_decode(xmrAddress);
    }

    /**
     * @dev Function base58 encode XMR address with hash check
     *     *
     */
    function encodeAddress(bytes memory xmrAddress) override public view returns(bytes memory){
        return Monero.encodeAddress(xmrAddress, _netBytes, true);
    }
    
    /**
     * @dev Function base58 decode XMR address with hash check
     *     *
     */
    function decodeAddress(bytes memory xmrAddress) override public view returns(bytes memory){
        return Monero.decodeAddress(xmrAddress, _netBytes, true);
    }

    event PoolSize(uint256 entries);
     /**
     * @dev Emitted when setting contract parameters
     */
    event SetParameters(
        bytes3 netBytes, 
        bytes32 pubSpend,
        bytes32 pubView, 
        bool intAddressEnabled
    );
}