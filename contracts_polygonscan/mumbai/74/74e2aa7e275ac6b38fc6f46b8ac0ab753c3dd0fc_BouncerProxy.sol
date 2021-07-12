/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.24;

contract BouncerProxy {
  //whitelist the deployer so they can whitelist others
  constructor() public {
     whitelist[msg.sender] = true;
  }
  mapping(address => uint) public nonce;
  mapping(address => bool) public whitelist;
  function updateWhitelist(address _account, bool _value) public returns(bool) {
   require(whitelist[msg.sender],"BouncerProxy::updateWhitelist Account Not Whitelisted");
   whitelist[_account] = _value;
   emit UpdateWhitelist(_account,_value);
   return true;
  }
  event UpdateWhitelist(address _account, bool _value);
  function () public payable { emit Received(msg.sender, msg.value); }
  event Received (address indexed sender, uint value);

  function getHash(address destination, bytes data) public view returns(bytes32){
    return keccak256(abi.encodePacked(address(this), destination, data));
  }
  function getEncoded(address signer, address destination, bytes data) public view returns(bytes){
    return abi.encodePacked(address(this), signer, destination, data,nonce[signer]);
  }

  function forward(bytes sig, address destination,bytes data) public {
      bytes32 _hash = getHash(destination, data);
      require(executeCall(destination, data));
      emit Forwarded(recover(_hash,sig));
  }
  // when some frontends see that a tx is made from a bouncerproxy, they may want to parse through these events to find out who the signer was etc
  event Forwarded (address indexed signer);

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
  function executeCall(address to, bytes data) internal returns (bool success) {
    assembly {
       success := call(gas, to, 0, add(data, 0x20), mload(data), 0, 0)
    }
  }

  //borrowed from OpenZeppelin's ESDA stuff:
  //https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
  function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

}