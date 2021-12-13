/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BetManager is Context, Ownable {
  using ECDSA for bytes32;

  // prize balances
  mapping (address => uint256) public balances;

  uint256 public roundNo = 1;
  uint256 public dimension = 3;
  uint256 public totalCells = dimension * dimension;
  uint256 public price = 1 * 10**16;  // 0.01 ETH

  // bet count
  mapping (address => uint8) public bets;
  address[] public betters;
  uint256 public totalBets = 0;
  uint256 public maxBets = 2 * totalCells - 1;
  uint8 public maxBetsPerAddress = 3;

  bool public stopped = false;
  bool private _processedPrize = false;

  uint256 public serviceFee = 10; // percentage
  uint256 private totalFees = 0;

  address public constant partner1 = 0x620dc94C842817d5d8b8207aa2DdE4f8C8b73415;
  address public constant partner2 = 0xD65F49a69652FBefF31DF87400b26Eb4C3f01B2c;

  uint256 public constant partner1Share = 50;  // partner1 50%
  uint256 public constant partner2Share = 50;  // partner2 50%

  event DimensionUpdated(uint256 _dimension);
  event PriceUpdated(uint256 _price);
  event MaxBetsPerAddressUpdated(uint8 _maxValue);
  event ServiceFeeUpdated(uint256 _newFee);

  event Started(uint256 indexed _roundNo);
  event Stopped(uint256 indexed _roundNo);
  event EmergencyStopped(uint256 indexed _roundNo);
  event Wins(uint256 indexed _roundNo, uint256 _totalWinners);

  modifier onlyStopped() {
    require(stopped == true, "Not stopped yet");
    _;
  }

  modifier onlyStarted() {
    require(stopped == false, "Not started yet");
    _;
  }

  function status() external view  returns (uint256, uint256, uint256, uint8, uint256, bool, uint256, uint256){
    return (dimension, totalCells, maxBets, maxBetsPerAddress, price, stopped, roundNo, totalBets);
  }

  function start() external onlyOwner() onlyStopped() {
    // reset all status before new round
    while(betters.length > 0) {
      bets[betters[betters.length - 1]] = 0;
      betters.pop();
    }
    totalBets = 0;

    roundNo ++;
    stopped = false;
    _processedPrize = false;
    emit Started(roundNo);
  }

  function testEncodePacked(address sender, uint256 order) external pure returns(bytes memory) {
    bytes memory result = abi.encodePacked(sender, order);
    return result;
  }

  function hashReserveInfo(address sender, uint256 order) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, order))
    ));
  }

  function verifyReserveSignature(bytes32 _hash, bytes memory signature) public view returns (bool) {
    return owner() == _hash.recover(signature);
  }

  function bet(uint256 order, bytes memory signature) external payable onlyStarted() {
    require(msg.sender == tx.origin, "Only EOA");
    require(
      verifyReserveSignature(
        hashReserveInfo(msg.sender, order), 
        signature
      ),
      "Invalid request"
    );
    require(order >= totalBets, "Old request");
    require(msg.value >= price, "Not sent enough ETH");
    require(bets[_msgSender()] < maxBetsPerAddress, "Not allowed bulk bets");

    uint256 remaining = msg.value - price;
    if (remaining > 0) {
      (bool success, ) = msg.sender.call{value: remaining}("");
      require(success);
    }

    if (bets[_msgSender()] == 0) {
      betters.push(_msgSender());
    }
    bets[_msgSender()] ++;
    totalBets ++;

    if (totalBets == maxBets) {
      stopped = true;
      emit Stopped(roundNo);
    }
  }

  function emergencyStop() external onlyOwner() onlyStarted() {
    uint8 _betTimes;
    stopped = true;

    // refund all betting amount
    for (uint256 index = 0; index < betters.length; index ++) {
      if (bets[betters[index]] == 0) {
        continue;
      }
      _betTimes = bets[betters[index]];
      bets[betters[index]] = 0;
      _widthdraw(betters[index], price * _betTimes);
    }

    emit EmergencyStopped(roundNo);
  }

  function setPrice(uint256 _price) external onlyOwner() onlyStopped() {
    require(_price > 0, "Price should not be 0");
    price = _price;
    emit PriceUpdated(price);
  }

  function setServiceFee(uint256 _fee) external onlyOwner() onlyStopped() {
    require(_fee > 0 && _fee < 50, "Invalid fee rate");
    serviceFee = _fee;

    emit ServiceFeeUpdated(serviceFee);
  }

  function setDimension(uint256 _dimension) external onlyOwner() onlyStopped() {
    require(_dimension >= 3 && _dimension < 200, "Dimension should be between 3 ~ 200");
    dimension = _dimension;
    totalCells = dimension * dimension;
    maxBets = 2 * totalCells - 1;
    emit DimensionUpdated(dimension);
  }

  function setMaxBetsPerAddress(uint8 _maxBetsPerAddress) external onlyOwner() onlyStopped() {
    require(_maxBetsPerAddress < totalCells >> 1, "Too large limit");
    maxBetsPerAddress = _maxBetsPerAddress;
    emit MaxBetsPerAddressUpdated(maxBetsPerAddress);
  }

  /**
    After game is over, sets the total winners, and based on that, it will deposit winners prize
   */
  function processFunds(uint256 _totalWinners, address[] calldata _winners) external onlyOwner() onlyStopped() {
    require(!_processedPrize, "Already done!");
    require(_totalWinners < totalCells, "Incorrect winners");
    require(_totalWinners == _winners.length, "Winners mismatch");

    uint256 roundBalance = price * maxBets;
    if (_totalWinners > 0) {
      uint256 roundFee = roundBalance * serviceFee / 100;
      uint256 roundPrize = roundBalance - roundFee;
      uint256 unitPrize = roundPrize / _totalWinners;

      for (uint256 i = 0; i < _totalWinners; i++) {
        require(bets[_winners[i]] > 0, "Invalid winner");
        bets[_winners[i]] --;
        balances[_winners[i]] += unitPrize;
      }
      totalFees += roundFee;
    } else {
      totalFees += roundBalance;
    }

    _processedPrize = true;
    emit Wins(roundNo, _totalWinners);
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  /**
    It allows users to withdraw all their winning prize at once.
   */
  function withdraw() external {
    require(balances[_msgSender()] > 0, "No balance yet");
    uint256 _balance = balances[_msgSender()];
    balances[_msgSender()] = 0;
    _widthdraw(_msgSender(), _balance);
  }

  /**
    It allows owners to withdraw all their fees income at once.
   */
  function withdrawFees() external onlyOwner() {
    require(totalFees > 0, "No balance yet");

    uint256 _partner1 = totalFees * partner1Share / 100;
    uint256 _partner2 = totalFees - _partner1;

    _widthdraw(partner1, _partner1);
    _widthdraw(partner2, _partner2);

    totalFees = 0;
  }
}