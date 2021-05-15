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


contract YZDataInterface{
  bytes32 public data_hash;
  uint256 public price;
  address payable public bank_account;
  function is_program_hash_available(bytes32 program_hash) public view returns(bool) ;
  function program_price(bytes32 program_hash) public view returns(uint256);
}

contract YZDataRequest {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  struct YZRequest{
    address payable from;
    bytes pkey4v;
    bytes secret;
    bytes input;
    bytes forward_sig;
    bytes32 program_hash;
    uint token_amount;
    uint gas_price;
    uint block_number;
    bool settled;
    bool exists;
  }
  mapping (bytes32 => YZRequest) request_infos;

  YZDataInterface data;
  YZVerifierInterface verify_proxy;
  uint256 public total_deposit;

  constructor(address _data, address _verify_proxy) public{
    data = YZDataInterface(_data);
    verify_proxy = YZVerifierInterface(_verify_proxy);
    total_deposit = 0;
  }

  event RequestData(bytes32 request_hash, bytes secret, bytes input, bytes forward_sig, bytes32 program_hash, uint gas_price, bytes pkey);
  function request_data(bytes memory secret,
                        bytes memory input,
                        bytes memory forward_sig,
                        bytes32 program_hash, uint gas_price,
                        bytes memory pkey) public payable returns(bytes32 request_hash){

    //!Ignore the check for now
    require(pkey.length != 0, "not a registered user");
    require(data.is_program_hash_available(program_hash), "invalid program");

    request_hash = keccak256(abi.encode(msg.sender, pkey, secret, input, forward_sig, program_hash, gas_price));
    require(request_infos[request_hash].exists == false, "already exist");
    require(msg.value >= data.price() + data.program_price(program_hash), "not enough budget");
    total_deposit += msg.value;

    request_infos[request_hash].from = msg.sender;
    request_infos[request_hash].pkey4v = pkey;
    request_infos[request_hash].secret = secret;
    request_infos[request_hash].input = input;
    request_infos[request_hash].forward_sig = forward_sig;
    request_infos[request_hash].program_hash = program_hash;
    request_infos[request_hash].token_amount = msg.value;
    request_infos[request_hash].gas_price = gas_price;
    request_infos[request_hash].block_number = block.number;
    request_infos[request_hash].settled = false;
    request_infos[request_hash].exists = true;

    emit RequestData(request_hash, secret, input, forward_sig, program_hash, gas_price, pkey);
    return request_hash;
  }


  function get_request_info(bytes32 hash) public view returns(address from,
                                                              bytes memory pkey4v,
                                                              bytes memory secret,
                                                              bytes memory input,
                                                              bytes memory forward_sig,
                                                              bytes32 program_hash,
                                                              uint token_amount,
                                                              uint gas_price,
                                                              uint block_number,
                                                              bool settled){
    require(request_infos[hash].exists, "request not exist");
    YZRequest storage m = request_infos[hash];
    from = m.from;
    pkey4v = m.pkey4v;
    secret = m.secret;
    input = m.input;
    forward_sig = m.forward_sig;
    program_hash = m.program_hash;
    token_amount = m.token_amount;
    gas_price = m.gas_price;
    block_number = m.block_number;
    settled = m.settled;
  }

  event RefundRequest(bytes32 request_hash, uint256 old_amount, uint256 new_amount);
  function refund_request(bytes32 request_hash) public payable{
    require(request_infos[request_hash].exists, "request not exist");
    require(request_infos[request_hash].settled, "already settled");
    require(request_infos[request_hash].from == msg.sender, "only request owner can refund");

    uint256 old = request_infos[request_hash].token_amount;
    request_infos[request_hash].token_amount = request_infos[request_hash].token_amount.safeAdd(msg.value);

    total_deposit += msg.value;
    emit RefundRequest(request_hash, old, request_infos[request_hash].token_amount);
  }

  event SubmitResult(bytes32 request_hash, bytes32 data, uint cost_gas, bytes result, bytes sig, uint256 cost_token, uint256 return_token);
  event SResultInsufficientFund(bytes32 request_hash, uint256 expect_fund, uint256 actual_fund);
  function submit_result(bytes32 request_hash, uint cost, bytes memory result, bytes memory sig) public returns(bool){
    require(request_infos[request_hash].exists, "request not exist");
    require(!request_infos[request_hash].settled, "already settled");

    YZRequest storage r = request_infos[request_hash];
    bytes32 vhash = keccak256(abi.encodePacked(r.input, data.data_hash(), uint64(cost), result));
    bool v = verify_proxy.verify_signature(vhash.toEthSignedMessageHash(), sig, r.pkey4v);
    require(v, "invalid data");

    uint amount = cost.safeMul(request_infos[request_hash].gas_price);
    amount = amount.safeAdd(data.price()).safeAdd(data.program_price(r.program_hash));

    //emit event instead of revert, so users can refund
    if(amount > request_infos[request_hash].token_amount){
      emit SResultInsufficientFund(request_hash, amount, request_infos[request_hash].token_amount);
      return false;
    }

    r.settled = true;
    uint rest = r.token_amount.safeSub(amount);
    total_deposit = total_deposit.safeSub(amount);
    (bool succ, ) = data.bank_account().call.value(amount)("");
    require(succ, "invalid eth transfer");

    //TODO pay program author

    if(rest > 0){
      total_deposit = total_deposit.safeSub(rest);
      (succ, ) = r.from.call.value(rest)("");
      require(succ, "invalid eth transfer");
    }

    emit SubmitResult(request_hash, data.data_hash(), cost, result, sig, amount, rest);
    return true;
  }

  event RevokeRequest(bytes32 request_hash);
  function revoke_request(bytes32 request_hash) public{
    YZRequest storage r = request_infos[request_hash];
    require(msg.sender == r.from, "not owner of this request");
    require(r.settled == false, "alread settled");

    //require(block.number - r.block_number >= revoke_period, "not long enough for revoke");

    //TODO: charge fee for revoke
    r.settled = true;
    total_deposit = total_deposit.safeSub(r.token_amount);
    (bool succ, ) = r.from.call.value(r.token_amount)("");
    require(succ, "invalid eth transfer");
    emit RevokeRequest(request_hash);
  }
}

contract YZDataRequestFactory{
  event NewYZDataRequest(address addr);
  function createYZDataRequest(address data, address verify_proxy) public returns(address){
    YZDataRequest r = new YZDataRequest(data, verify_proxy);
    emit NewYZDataRequest(address(r));
    return address(r);
  }
}