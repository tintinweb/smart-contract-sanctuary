/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}
pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

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
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
pragma solidity >=0.4.21 <0.6.0;

contract YZVerifierInterface{
  function verify_pkey(bytes memory pkey, bytes memory pkey_sig) public returns(bool);
  function verify_signature(bytes32 hash, bytes memory sig, bytes memory pkey) public view returns (bool);
}



contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
}

contract YZData is Ownable{
  using SafeMath for uint256;

  bytes32 public data_hash;
  string public data_name;
  string public data_description;
  bytes public data_sample;
  string public env_info; //os, sgx sdk, cpu, compiler
  uint256 public price;
  bytes32 public format_lib_hash;
  bytes public pkey;

  address payable public bank_account;

  uint public total_deposit;

  address public program_proxy;
  address public request_proxy;

  constructor(bytes32 _hash,
              string memory _name,
              string memory _desc,
              bytes memory _sample,
              string memory _env_info,
              uint _price,
              address _program_proxy,
              bytes memory _pkey) public{
    data_hash = _hash;
    data_name = _name;
    data_description = _desc;
    data_sample = _sample;
    env_info = _env_info;
    price = _price;
    pkey = _pkey;

    program_proxy = _program_proxy;
    total_deposit = 0;
  }

  function is_program_hash_available(bytes32 program_hash) public view returns(bool) {
    return ProgramProxyInterface(program_proxy).is_program_hash_available(program_hash);
  }

  function program_price(bytes32 program_hash) public view returns(uint256){
    return ProgramProxyInterface(program_proxy).program_price(program_hash);
  }

  event ChangeRequestProxy(address _old, address _new);
  function change_request_proxy(address _addr) public onlyOwner{
    address old = request_proxy;
    request_proxy = _addr;
    emit ChangeRequestProxy(old, request_proxy);
  }

  event ChangeProgramProxy(address _old, address _new);
  function change_program_proxy(address _addr) public onlyOwner {
    address old = program_proxy;
    program_proxy = _addr;
    emit ChangeProgramProxy(old, program_proxy);
  }
}

contract YZDataRequestFactoryInterface{
  function createYZDataRequest(address data, address verify_addr) public returns(address);
}

contract YZDataFactory is Ownable{
  using ECDSA for bytes32;

  event NewYZData(address addr);
  YZDataRequestFactoryInterface public request_factory;
  YZVerifierInterface public verifier_proxy;
  address public verify_addr;
  bool public paused;

  constructor(address _request_factory, address _verifier_addr) public{
    request_factory = YZDataRequestFactoryInterface(_request_factory);
    verify_addr = _verifier_addr;
    verifier_proxy = YZVerifierInterface(_verifier_addr);
    paused = false;
  }

  function pause(bool _paused) public onlyOwner{
    paused = _paused;
  }

  function createYZData(bytes32 _hash,
                        string memory _name,
                        string memory _desc,
                        bytes memory _sample,
                        string memory _env_info,
                        uint _price,
                        address _program_proxy,
                        bytes memory _pkey,
                        bytes memory _pkey_sig,
                        bytes memory _hash_sig) public returns(address){
    require(!paused, "already paused to use");

    bytes32 vhash = keccak256(abi.encodePacked(_hash));
    bool v = verifier_proxy.verify_signature(vhash.toEthSignedMessageHash(), _hash_sig, _pkey);
    require(v, "invalid hash signature");

    require(verifier_proxy.verify_pkey(_pkey, _pkey_sig), "invalid pkey");
    YZData y = new YZData(_hash, _name, _desc, _sample, _env_info, _price, _program_proxy, _pkey);

    address req = request_factory.createYZDataRequest(address(y), verify_addr);
    y.change_request_proxy(req);
    y.transferOwnership(msg.sender);
    emit NewYZData(address(y));
    return address(y);
  }
}