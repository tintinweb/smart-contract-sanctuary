// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @title IPriceFeed
 * @dev A minimal interface for contracts providing pricing data
 */
interface IPriceFeed {

    /**
    * @dev return the price of a given asset
    * @param symbol that identifies an asset (it's passed as bytes32 for the gas efficiency)
    **/
    function getPrice(bytes32 symbol) external view returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract InlinedPriceAwareAsm  {
  using ECDSA for bytes32;

  uint constant MAX_DELAY = 3 * 60;
  address constant TRUSTED_SIGNER = 0xFE71e9691B9524BC932C23d0EeD5c9CE41161884;

  function getPriceFromMsg(bytes32 symbol) internal view returns(uint256) {
    //The structure of calldata witn n - data items:
    //The data that is signed (symbols, values, timestamp) are inside the {} brackets
    //[origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]


    //1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
    uint8 dataSize; //Number of data entries    
    assembly {
    //Calldataload loads slots of 32 bytes
    //The last 65 bytes are for signature
    //We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
      dataSize := calldataload(sub(calldatasize(), 97))
    }


    // 2. We calculate the size of signable message expressed in bytes
    // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
    uint16 messageLength = dataSize * 64 + 32; //Length of data message in bytes


    // 3. We extract the signableMessage

    //(That's the high level equivalent 2k gas more expensive)
    //bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

    bytes memory signableMessage;
    assembly {
      signableMessage := mload(0x40)
      mstore(signableMessage, messageLength)
    //The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
      calldatacopy(add(signableMessage, 0x20), sub(calldatasize(), add(messageLength, 66)), messageLength)
      mstore(0x40, add(signableMessage, 0x20))
    }


    // 4. We first hash the raw message and then hash it again with the prefix
    // Following the https://github.com/ethereum/eips/issues/191 standard
    bytes32 hash = keccak256(signableMessage);
    bytes32 hashWithPrefix = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    // 5. We extract the off-chain signature from calldata

    //(That's the high level equivalent 2k gas more expensive)
    //bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
    bytes memory signature;
    assembly {
      signature := mload(0x40)
      mstore(signature, 65)
      calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
      mstore(0x40, add(signature, 0x20))
    }

    // 6. We verify the off-chain signature against on-chain hashed data

    address signer = hashWithPrefix.recover(signature);
    require(signer == TRUSTED_SIGNER, "Signer not authorized");

    //7. We extract timestamp from callData

    uint256 dataTimestamp;
    assembly {
    //Calldataload loads slots of 32 bytes
    //The last 65 bytes are for signature + 1 for data size
    //We load the previous 32 bytes
      dataTimestamp := calldataload(sub(calldatasize(), 98))
    }
    require(block.timestamp - dataTimestamp < MAX_DELAY, "Data is too old");

    //Debugging logs (to be removed)

    //    console.log("Len: ", messageLength);
    //    console.logBytes(rawData);
    //    console.logBytes32(hash);
    //    console.logBytes(signature);
    //    console.log("Signer: ", signer);


    //8. We iterate directly through call data to extract the value for a given symbol

    uint256 val;
    uint256 max = dataSize;
    bytes32 currentSymbol;
    uint256 i;
    assembly {
      let start := sub(calldatasize(), add(messageLength, 66))
      for { i := 0 } lt(i, max) { i := add(i, 1) } {
        val := calldataload(add(start, add(32, mul(i, 64))))
        currentSymbol := calldataload(add(start, mul(i, 64)))
        if eq(currentSymbol, symbol) { i := max }
      }
    }

    return val;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../commons/IPriceFeed.sol";

/**
 * @title MockStatePriceProvider
 * @dev It simulates an external contract that provides price information taken from storage.
 * It is a minimal version of other oracle referential data contracts
 * like AggregatorInterface from Chainlink or IStdReference from Band
 * and provides a lower bound for gas cost benchmarks.
 */
contract MockStatePriceProvider is IPriceFeed {
  
  uint256 price = 777;

  /**
  * @dev gets mocked price
  * @param symbol of the price - kept for interface compatibility
  **/
  function getPrice(bytes32 symbol) public override view returns(uint256) {
    return price;
  }


  /**
  * @dev sets new price allowing to update the mocked value
  * @param _price value of a new price
  **/
  function setPrice(uint _price) external {
    price = _price;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../mocks/MockStatePriceProvider.sol";
import "../message-based/InlinedPriceAwareAsm.sol";

/**
 * @title SampleInlinedPriceAwareAsm
 * @dev An example of a contract using message-based way of fetching data from RedStone
 * It has only a few dummy methods used to benchmark gas consumption
 * It extends InlinedPriceAwareAsm which in-lines signer address and maximum delay of price feed
 * to reduce the gas of every invocation (saving is ~4k gas)
 */
contract SampleInlinedPriceAwareAsm is InlinedPriceAwareAsm {

  MockStatePriceProvider mockStatePriceProvider = new MockStatePriceProvider();


  function execute(uint val) public returns(uint256) {
    return getPrice();
  }


  function executeWithPrice(uint val) public returns(uint256) {
    return getPriceFromMsg(bytes32("IBM"));
  }


  function getPrice() internal view returns(uint256) {
    return mockStatePriceProvider.getPrice(bytes32("ETH"));
  }


  function getTime() public view returns(uint256) {
    return block.timestamp;
  }

}

