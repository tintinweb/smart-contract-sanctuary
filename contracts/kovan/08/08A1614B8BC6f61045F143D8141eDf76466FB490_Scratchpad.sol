// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

/// @title verifyIPFS
/// @author Martin Lundfall ([email protected])
library verifyIPFS {
  bytes constant private prefix1 = hex"0a";
  bytes constant private prefix2 = hex"080212";
  bytes constant private postfix = hex"18";
  bytes constant private sha256MultiHash = hex"1220";
  bytes constant private ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

  /// @dev generates the corresponding IPFS hash (in base 58) to the given string
  /// @param contentString The content of the IPFS object
  /// @return The IPFS hash in base 58
  function generateHash(string memory contentString) internal pure returns (bytes memory) {
    bytes memory content = bytes(contentString);
    bytes memory len = lengthEncode(content.length);
    bytes memory len2 = lengthEncode(content.length + 4 + 2*len.length);
    return toBase58(concat(sha256MultiHash, toBytes(sha256(abi.encodePacked(prefix1, len2, prefix2, len, content, postfix, len)))));
  }

  /// @dev Compares an IPFS hash with content
  function verifyHash(string memory contentString, string memory hash) internal pure returns (bool) {
    return equal(generateHash(contentString), bytes(hash));
  }
  
  /// @dev Converts hex string to base 58
  function toBase58(bytes memory source) internal pure returns (bytes memory) {
    if (source.length == 0) return new bytes(0);
    uint8[] memory digits = new uint8[](64); //TODO: figure out exactly how much is needed
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i<source.length; ++i) {
      uint carry = uint8(source[i]);
      for (uint256 j = 0; j<digitlength; ++j) {
        carry += uint(digits[j]) * 256;
        digits[j] = uint8(carry % 58);
        carry = carry / 58;
      }
      
      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        digitlength++;
        carry = carry / 58;
      }
    }
    //return digits;
    return toAlphabet(reverse(truncate(digits, digitlength)));
  }

  function lengthEncode(uint256 length) internal pure returns (bytes memory) {
    if (length < 128) {
      return to_binary(length);
    }
    else {
      return concat(to_binary(length % 128 + 128), to_binary(length / 128));
    }
  }

  function toBytes(bytes32 input) internal pure returns (bytes memory) {
    bytes memory output = new bytes(32);
    for (uint8 i = 0; i<32; i++) {
      output[i] = input[i];
    }
    return output;
  }
    
  function equal(bytes memory one, bytes memory two) internal pure returns (bool) {
    if (!(one.length == two.length)) {
      return false;
    }
    for (uint256 i = 0; i<one.length; i++) {
      if (!(one[i] == two[i])) {
	return false;
      }
    }
    return true;
  }

  function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](length);
    for (uint256 i = 0; i<length; i++) {
        output[i] = array[i];
    }
    return output;
  }
  
  function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](input.length);
    for (uint256 i = 0; i<input.length; i++) {
        output[i] = input[input.length-1-i];
    }
    return output;
  }
  
  function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
    bytes memory output = new bytes(indices.length);
    for (uint256 i = 0; i<indices.length; i++) {
        output[i] = ALPHABET[indices[i]];
    }
    return output;
  }

  function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
    bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
    uint i = 0;
    for (i; i < byteArray.length; i++) {
      returnArray[i] = byteArray[i];
    }
    for (i; i < (byteArray.length + byteArray2.length); i++) {
      returnArray[i] = byteArray2[i - byteArray.length];
    }
    return returnArray;
  }
    
  function to_binary(uint256 x) internal pure returns (bytes memory) {
    if (x == 0) {
      return new bytes(0);
    }
    else {
      bytes1 s = bytes1(uint8(x % 256));
      bytes memory r = new bytes(1);
      r[0] = s;
      return concat(to_binary(x / 256), r);
    }
  }
}

contract Scratchpad {

    struct RedirectMap {
        uint16 from;
        uint16 to;
    }
    struct abc {
        bytes16 a;
        bytes16 b;
    }
    uint16[] public array;
    uint16 public x;
    uint256[31] internal _a1;
    uint16[31] internal _a2;
    mapping(uint256 => mapping (uint16 => uint16)) public temp_sparse_array;
    mapping(uint256 => uint16[]) public draws;
    mapping(uint16 => uint16) public sparse_array;
    // the min onchain cost(via event) would be as at 2021/8/2(non EIP1559 transaction)
    // 23K @ 2000 USD/ETH @ 10GWei = 0.46 USD
    event RequestDataWithSender(address indexed from, uint256 request);
    event RequestData(uint256 request);
    event RequestData8(uint256 request);
    //event RandomPick(uint256, uint16[] result, uint16[] draw, uint16[] s);
    event RandomResult(uint256);
    event RandomPick(uint256, uint16[] result);
    event RedirectedMap(uint256, RedirectMap[] result);
    event RandomPick24(uint256, uint24[] result);

    // gas 22495 - london fork, probably the cheapest to store uint256 value on chain via event
    function signal256(uint256 val) public {
        emit RequestData(val);
    }
    // gas 22934 - london fork, slightly higher but allows searching from address
    function signal256WithSender(uint256 val) public {
        emit RequestDataWithSender(msg.sender, val);
    }

    // gas 22551 - london fork
    // prove that uint256 is the optimal size for single value param in event, don't try to save there
    function signal8(uint8 val) public {
        emit RequestData8(val);
    }
    function arrayParam(uint16[] memory a) public {
        emit RandomResult(a.length - a.length);
    }
    function allocArray1000() public {
        array = new uint16[](1000);
    }
    function allocArray2000() public {
        array = new uint16[](2000);
    }
    function assignArray(uint256 val, uint256 idx) public {
        array[idx] = uint16(val);
    }
    function insertMap(uint256 val, uint256 idx) public {
        sparse_array[uint16(idx)] = uint16(val);
    }

    function randomPick(uint16 pool, uint16 pick) public returns(uint16[] memory) {
        uint256 i;
        uint256 rand256 = uint256(keccak256(abi.encode(blockhash(block.number-1))));
        mapping(uint16 => uint16) storage picked = temp_sparse_array[rand256];
        uint16[] memory results = new uint16[](pick);
        // uint16[] memory x = new uint16[](pick);
        // uint16[] memory y = new uint16[](pick);

        for (i = 0; i < pick; i++) {
            uint16 mod = uint16(pool - i);
            uint16 slot = uint16((rand256 >> i) % (mod));
            slot = slot == 0 ? mod : slot;
            results[i] = picked[slot] != 0 ? picked[slot] : slot;
            picked[slot] = picked[mod] != 0 ? picked[mod] : mod;
        }
        
        emit RandomPick(rand256, results);
        //emit RandomPick(rand256, results, x, y);
        return results;
    }
    // function arrayRandomPick(uint16[] memory pool, uint16 pick) public returns(uint16[] memory) {
    //     uint256 i;
    //     uint256 poolSize = pool.length;
    //     uint256 rand256 = uint256(keccak256(abi.encode(blockhash(block.number-1))));
    //     uint16[] memory results = new uint16[](pick);

    //     for (i = 0; i < pick; i++) {
    //         uint16 mod = uint16(poolSize - i);
    //         uint16 slot = uint16((rand256 >> i) % (mod));
    //         slot = slot == 0 ? mod : slot;
    //         results[i] = pool[slot-1] != 0 ? pool[slot-1] : slot;
    //         pool[slot-1] = pool[mod-1] != 0 ? pool[mod-1] : mod;
    //     }
        
    //     emit RandomPick(rand256, results);
    //     //emit RandomPick(rand256, results, x, y);
    //     return results;
    // }
    function randomPickBulk(uint16 poolSize, uint16 pick, uint16[] memory alreadyDrawn) public {
        uint256 rand256 = uint256(keccak256(abi.encode(blockhash(block.number-1))));

        uint16[] memory results = arrayRandomPick(rand256, poolSize, pick, alreadyDrawn);
        draws[rand256] = results;
        //emit RandomResult(rand256);
        emit RandomPick(rand256, results);
    }
    function arrayRandomPick(uint256 rand256, uint16 poolSize, uint16 pick, uint16[] memory alreadyDrawn) public pure returns(uint16[] memory) {
        uint256 i;
        uint256 r = rand256;
        uint16[] memory pool = new uint16[](poolSize);
        uint16[] memory results = new uint16[](pick);
        RedirectMap[] memory usedSlot = fRedirectMap(alreadyDrawn, poolSize);
        for (i =0; i < usedSlot.length; i++) {
            pool[usedSlot[i].to] = usedSlot[i].from;
        }
        poolSize -= uint16(alreadyDrawn.length);        
        for (i = 0; i < alreadyDrawn.length; i++) {
            uint16 drawn = alreadyDrawn[i];
            if (drawn <= poolSize)
                pool[drawn] = poolSize + uint16(i);
        }
        for (i = 0; i < pick; i++) {
            uint16 mod = uint16(poolSize - i);
            uint16 slot = uint16(r % (mod));
            slot = slot == 0 ? mod : slot;
            results[i] = pool[slot-1] != 0 ? pool[slot-1] : slot;
            pool[slot-1] = pool[mod-1] != 0 ? pool[mod-1] : mod;
            if (i % 128 == 127) {
                r = uint256(keccak256(abi.encode(r)));
            }
            else {
                r >>= 1;
            }
        }
        return results;
    }
    function redirectMap(uint16[] memory alreadyDrawn, uint16 base) public {
        RedirectMap[] memory result = fRedirectMap(alreadyDrawn, base);
        emit RedirectedMap(0,result);
    }
    function fRedirectMap(uint16[] memory alreadyDrawn, uint16 base) public pure returns(RedirectMap[] memory) {
        uint256 i;
        uint256 replace = 0;
        uint256 len = alreadyDrawn.length;
        uint256 n = len;
        RedirectMap[] memory result = new RedirectMap[](len);
        for (i = 0; i < alreadyDrawn.length; i++) {
            if (alreadyDrawn[n - 1] != base - i) {
                result[len - 1 - i] = RedirectMap(uint16(base - i), alreadyDrawn[replace]);
                replace += 1;
            }
            else {
                result[len - 1 - i] = RedirectMap(uint16(base - i), 0);
                n -= 1;
            }
        }
        return result;
    }
    function min(uint256 bits) public pure returns(int256) {
        return 0 - int256(2**(bits-1));
    }
    function max(uint256 bits) public pure returns(int256) {
        return int256(2**bits-1);
    }
    
    function sort(uint16[] memory data) public {
        fQuickSort(data, 0, int(data.length - 1));
        emit RandomPick(0, data);
    }

    function shuffle(uint256 rand256, uint16 size) public {
        fShuffle(rand256, size);
        emit RandomResult(rand256);
    }
    function fShuffle(uint256 rand256, uint16 size) public pure returns(uint16[] memory) {
        uint256 i;
        uint16 j;
        uint16[] memory result = new uint16[](size);
        uint256 r = rand256;
        // for(i = 0; i < size; i++) {
        //     result[i] = uint16(i+1);
        // }

        for (i = size - 1; i > 0; i--) {
            j = uint16(r % (i+1));
            if (result[i] == 0) result[i] = uint16(i+1);
            if (result[j] == 0) result[j] = j+1;
            uint16 z = result[j];
            result[j] = result[i];
            result[i] = z;
            if ((size - i) % 128 == 0) {
                r = uint256(keccak256(abi.encode(r)));
            }
            else {
                r >>= 1;
            }
        }
        return result;
    }

    function fQuickSort(uint16[] memory arr, int left, int right) public pure returns(uint16[] memory) {
        int i = left;
        int j = right;
        if(i==j) return arr;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            fQuickSort(arr, left, j);
        if (i < right)
            fQuickSort(arr, i, right);

        return arr;
    }

    function getRandomResult(uint256 round) public view returns(uint16[] memory) {
        return draws[round];
    }

    function getETH1WithdrawAddress(bytes32 withdrawal_credential) public pure returns(bytes1, address) {
        // bytes1 prefix;
        // bytes12 filler;
        // address eth1Address; 
        bytes memory xx = abi.encodePacked(withdrawal_credential);
        bytes1 prefix = xx[0];
        xx[0] = 0;
        (address eth1Address) = abi.decode(xx, (address));
        return (prefix, eth1Address);
    }

    function a1() public {
        uint i;
        for (i = 0; i < _a1.length; i++) {
            _a1[i] = 1;
            _a2[i] = 1;
        }
    }
    function abiDecodeTest(
        bytes memory _data
    )
        public
        pure
        returns(
            bytes4 sig,
            bytes32 label,
            address account,
            bytes32 pubkeyA,
            bytes32 pubkeyB
        )
    {
        assembly {
            sig := mload(add(_data, 32))
            label := mload(add(_data, 36))
            account := mload(add(_data, 68))
            pubkeyA := mload(add(_data, 100))
            pubkeyB := mload(add(_data, 132))
        }
    }
    function getBlockNumber() public view returns (uint256, uint256) {
        return (block.number, block.timestamp);
    }
    function bytesUp(bytes memory data) public pure returns(bytes4) {
        return bytes4(data[0]);
    }
    function bytesDown(bytes4 data) public pure returns(bytes1) {
        return bytes1(data);
    }
    function subString(string calldata s, uint start) public view returns(string memory) {
        return string(this._slice(bytes(s), start));
    }
    function _slice(bytes calldata data, uint start) public pure returns(bytes memory) {
        return data[start:];
    }

    function muldiv(uint256 a, uint256 b, uint256 c) public pure returns(uint256) {
        return (a*b/c);
    }
    function addminus(uint256 a, uint256 b, uint256 c) public pure returns(uint256) {
        return (a + b - c);
    }

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @dev convert string decimal to uint256(scaled)
    /// @param _a base10 string with optional decimal point like 1.234
    /// @param _b decimal points to take, so parseInt("1.234",2) would give 123
    /// @return _parsedInt result scaled to decimal, i.e 1.23 -> 123
    /// borrowed from https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function parseInt(string calldata _a, uint _b) public pure returns (uint _parsedInt) {
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

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("hex string only allows [0-9,A-F,a-f]");
    }

    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0,"hex string must be padded and with 0x prefix, so \"0\" should be \"0x00\""); // length must be even
        uint256 start = ss[0] == "0" && ss[1] == "x" ? 2 : 0;
        bytes memory r = new bytes((ss.length - start)/2);
        for (uint i=start; i<ss.length/2; ++i) {
            r[i-start] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }

    function addressToString(address _address) public pure returns(string memory) {
        bytes memory _bytes = abi.encodePacked(bytes20(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

    function stringToAddress(string memory _address) public pure returns(address addr) {
        bytes memory _bytes = fromHex(_address);
        require(_bytes.length == 20, "invalid address format");
        assembly {
            addr := mload(add(_bytes,20))
        } 
    }

    function toAddress(bytes memory _bytes, uint256 _start) public pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function slice(bytes memory _bytes, uint _start, uint _length) private pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length),"_bytes size must >= _start + _length");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}