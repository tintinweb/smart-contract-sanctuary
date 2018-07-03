pragma solidity ^0.4.14;

contract DepositVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[3] input
        ) public returns (bool) {}
}
contract TransactionVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) public returns (bool) {}
}
contract WithdrawVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) public returns (bool) {}
}
contract Manager {
  DepositVerifier dv;
  TransactionVerifier tv;
  WithdrawVerifier wv;
  mapping (uint => bool) public invalidators;
  mapping (uint => bool) public commitments;
  mapping (uint => bool) public roots;
  event TransactionEvent(string encrypted_msg);
  event RegisterEvent(uint pk, string enc_pk, address from);
  uint constant depth = 10;
  uint constant max_leaves = 1024;
  uint constant tree_size = 2048;
  uint constant weiPerUnit = 100000000000000000;
  struct Mtree {
    uint current;
    uint[tree_size] tree;
  }
  Mtree public MT;

  function Manager(address _dv, address _tv, address _wv) public {
    dv = DepositVerifier(_dv);
    tv = TransactionVerifier(_tv);
    wv = WithdrawVerifier(_wv);
    MT.current = 0;
  }
  function update_tree() internal returns (bool res) {
    uint i = MT.current + max_leaves;
    uint zero_hash = 0;
    while (i > 1) {
        if (i % 2 == 1)
            MT.tree[i/2] = uint(sha256(MT.tree[i-1], MT.tree[i]));
        else
            MT.tree[i/2] = uint(sha256(MT.tree[i], zero_hash));
        zero_hash = uint(sha256(zero_hash, zero_hash));
        i /= 2;
    }
    return true;
  }

  function register(uint pk, string enc_pk) public returns (bool res) {
    emit RegisterEvent(pk, enc_pk, msg.sender);
    return true;
  }
  function check_invalidator(uint invalidator) view public returns (bool exists) {
    return invalidators[invalidator];
  }
  function get_merkle_proof(uint i) view public returns (uint root, uint[depth] left_path, uint[depth] right_path) {
    i += max_leaves;
    uint curr = MT.current + max_leaves - 1;
    uint d = 0;
    uint zero_hash = 0;
    while (i > 1) {
        if (i % 2 == 1) {
            left_path[d] = MT.tree[i-1];
            right_path[d] = MT.tree[i];
        } else if (curr != i) {
            left_path[d] = MT.tree[i];
            right_path[d] = MT.tree[i+1];
        } else {
            left_path[d] = MT.tree[i];
            right_path[d] = zero_hash;
        }
        d++;
        zero_hash = uint(sha256(zero_hash, zero_hash));
        i /= 2;
        curr /= 2;
    }
    return (MT.tree[1], left_path, right_path);
  }
   function getSha256_UInt(uint input1, uint input2) view public returns (uint hash) {
     return uint(sha256(input1, input2));
  }

  function get_root() view public returns (uint root) {
    return MT.tree[1];
  }
  function get_size() view public returns (uint size) {
    return MT.current;
  }
  function add_commitment(uint commitment) internal returns (bool res) {
    if (MT.current == max_leaves)
      return false;
    MT.tree[max_leaves + MT.current] = commitment;
    update_tree();
    MT.current++;
    return true;
  }

  function deposit_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint commitment,
    uint value
  ) internal returns (bool res) {
    require(!commitments[commitment], &quot;Commitment already used!&quot;);
    require(dv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, [commitment, value / weiPerUnit, 1]), &quot;Deposit proof is wrong!&quot;);
    require(add_commitment(commitment), &quot;Couldn&#39;t add the commitment!&quot;);
    return true;
  }
  function deposit(
      uint[2] a,
      uint[2] a_p,
      uint[2][2] b,
      uint[2] b_p,
      uint[2] c,
      uint[2] c_p,
      uint[2] h,
      uint[2] k,
      uint commitment,
      string encrypted_msg
    ) public payable returns (bool res) {
    require(deposit_internal(a, a_p, b, b_p, c, c_p, h, k, commitment, msg.value), &quot;Deposit is incorrect!&quot;);
    commitments[commitment] = true;
    roots[get_root()] = true;
    emit TransactionEvent(encrypted_msg);
    return true;
  }

  function transaction_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input
  ) internal returns (bool res) {
    require(!invalidators[public_input[0]], &quot;Invalidator already used!&quot;);
    require(roots[public_input[1]], &quot;Root never appeared!&quot;);
    require(!commitments[public_input[2]], &quot;Out commitment already used!&quot;);
    require(!commitments[public_input[3]], &quot;Change commitment already used!&quot;);

    require(tv.verifyTx(a, a_p, b, b_p, c, c_p, h, k,
      [public_input[0], public_input[1], public_input[2], public_input[3], 1]), &quot;Transaction proof is wrong!&quot;);
    require(add_commitment(public_input[2]), &quot;Couldn&#39;t add out commitment!&quot;);
    require(add_commitment(public_input[3]), &quot;Couldn&#39;t add change commitment!&quot;);
    return true;
  }

  function transaction(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input, //invalidator, root, commitment_out, commitment_change
    string encrypted_msg_out,
    string encrypted_msg_change
  ) public returns (bool res) {
    require(transaction_internal(a, a_p, b, b_p, c, c_p, h, k, public_input), &quot;Transaction is incorrect!&quot;);
    invalidators[public_input[0]] = true;
    commitments[public_input[2]] = true;
    commitments[public_input[3]] = true;
    roots[get_root()] = true;
    emit TransactionEvent(encrypted_msg_out);
    emit TransactionEvent(encrypted_msg_change);
    return true;
  }
  function withdraw_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input
  ) internal returns (bool res) {
    require(!invalidators[public_input[0]], &quot;Invalidator already used!&quot;);
    require(roots[public_input[1]], &quot;Root never appeared!&quot;);
    require(!commitments[public_input[2]], &quot;Change commitment already used!&quot;);

    require(wv.verifyTx(a, a_p, b, b_p, c, c_p, h, k,
      [public_input[0], public_input[1], public_input[2], public_input[3] / weiPerUnit, 1]
      ), &quot;Withdraw proof is wrong!&quot;);
    require(add_commitment(public_input[2]), &quot;Couldn&#39;t add change commitment!&quot;);
    return true;
  }

  function withdraw(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input, //invalidator, root, commitment_change, value_out
    string encrypted_msg_change
  ) public returns (bool res) {
    require(withdraw_internal(a, a_p, b, b_p, c, c_p, h, k, public_input), &quot;Withdraw is incorrect!&quot;);
    invalidators[public_input[0]] = true;
    commitments[public_input[2]] = true;
    roots[get_root()] = true;
    msg.sender.transfer(public_input[3]);
    emit TransactionEvent(encrypted_msg_change);
    return true;
  }
}