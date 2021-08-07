/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.5.16;
/**
 Signature Authentication
    The exchange smart contract is able to authenticate the order originator’s (Maker’s) signature using the
    ecrecover function, which takes a hash and a signature of the hash as arguments and returns the public
    key that produced the signature. If the public key returned by ecrecover is equal to the maker address,
    the signature is authentic.
 */

/**
 * Based upon ECDSA library from OpenZeppelin Solidity
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
 */

contract Verification {
  /**
   * @dev Recover signer address from a message by using their signature
   * @param _ethSignedMessageHash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _signature bytes signature, the signature is generated using web3.eth.sign()
   */
   function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)  public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      
      // Check the signature length
      if (_signature.length != 65) {
        return (address(0));
      }
      
      // Divide the signature in r, s and v variables ecrecover takes the signature parameters, and the only way to get themcurrently is to use assembly.
      assembly {
        r := mload(add(_signature, 32))
        s := mload(add(_signature, 64))
        v := byte(0, mload(add(_signature, 96)))
      }

      return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}