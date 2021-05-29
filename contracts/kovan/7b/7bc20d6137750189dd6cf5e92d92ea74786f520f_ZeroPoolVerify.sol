/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// File: contracts/lib/IERC20.sol

pragma solidity >=0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/lib/AbstractERC20.sol

pragma solidity >=0.6.0;


library AbstractERC20 {

    function abstractReceive(IERC20 token, address from, uint256 amount) internal returns(uint256) {
        if (token == IERC20(0)) {
            require(msg.sender == from);
            require(msg.value == amount);
            return amount;
        } else {
            uint256 balance = abstractBalanceOf(token, address(this));
            token.transferFrom(from, address(this), amount);
            uint256 cmp_amount = abstractBalanceOf(token, address(this)) - balance;
            require(cmp_amount != 0);
            return cmp_amount;
        }
    }

    function abstractTransfer(IERC20 token, address to, uint256 amount) internal returns(uint256) {
        if (token == IERC20(0)) {
            payable(to).transfer(amount);
            return amount;
        } else {
            uint256 balance = abstractBalanceOf(token, address(this));
            token.transfer(to, amount);
            uint256 cmp_amount = balance - abstractBalanceOf(token, address(this));
            require(cmp_amount != 0);
            return cmp_amount;
        }
    }

    function abstractBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

// File: contracts/lib/MerkleProof.sol

pragma solidity >=0.6.0;

library MerkleProof {
    function keccak256MerkleProof(
        bytes32[8] memory proof,
        uint256 path,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 root = leaf;
        for (uint256 i = 0; i < 8; i++) {
            root = (path >> i) & 1 == 0
                ? keccak256(abi.encode(leaf, proof[i]))
                : keccak256(abi.encode(proof[i], leaf));
        }
        return root;
    }

    //compute merkle tree for up to 256 leaves
    function keccak256MerkleTree(bytes32[] memory buff)
        internal
        pure
        returns (bytes32)
    {
        uint256 buffsz = buff.length;
        bytes32 last_tx = buff[buffsz - 1];
        for (uint8 level = 1; level < 8; level++) {
            bool buffparity = (buffsz & 1 == 0);
            buffsz = (buffsz >> 1) + (buffsz & 1);

            for (uint256 i = 0; i < buffsz - 1; i++) {
                buff[i] = keccak256(abi.encode(buff[2 * i], buff[2 * i + 1]));
            }
            buff[buffsz - 1] = buffparity
                ? keccak256(
                    abi.encode(buff[2 * buffsz - 2], buff[2 * buffsz - 1])
                )
                : keccak256(abi.encode(buff[2 * buffsz - 2], last_tx));
            last_tx = keccak256(abi.encode(last_tx, last_tx));
        }
        return buff[0];
    }
}

// File: contracts/lib/Groth16Verifier.sol

pragma solidity >=0.5.2;


library Groth16Verifier {
  uint constant q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  struct G1Point {
    uint X;
    uint Y;
  }
  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint[2] X;
    uint[2] Y;
  }

  /// @return the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    G1Point memory t;
    uint[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    /* solium-disable-next-line */
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, t, 0x60)
      // Use "invalid" to make gas estimation work
      switch success case 0 { invalid() }
    }
    require(success);
    return t;
  }

  /// @return the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory) {
    if(s==0) return G1Point(0,0);
    if(s==1) return p;
    G1Point memory t;
    uint[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    /* solium-disable-next-line */
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, t, 0x60)
      // Use "invalid" to make gas estimation work
      switch success case 0 { invalid() }
    }
    require (success);
    return t;
  }


  function verify(uint[] memory vk, uint[8] memory proof, uint[] memory input) internal view returns (bool) {
    uint nsignals = (vk.length-16)/2;
    require((nsignals>0) && (input.length == nsignals) && (proof.length == 8) && (vk.length == 16 + 2*nsignals));

    for(uint i=0; i<input.length; i++)
      require(input[i]<r, "r compare fail");


    uint[] memory p_input = new uint[](24);

    p_input[0] = proof[0];
    p_input[1] = q-(proof[1]%q);  //proof.A negation
    p_input[2] = proof[2];
    p_input[3] = proof[3];
    p_input[4] = proof[4];
    p_input[5] = proof[5];

    // alpha1 computation
    p_input[6] = vk[0];     //vk.alfa1 == G1Point(vk[0], vk[1])
    p_input[7] = vk[1];


    p_input[8] = vk[2];
    p_input[9] = vk[3];
    p_input[10] = vk[4];
    p_input[11] = vk[5];

    //vk_x computation
    G1Point memory t = G1Point(vk[14], vk[15]);  //vk.IC[0] == G1Point(vk[14], vk[15])
    for(uint j = 0; j < nsignals; j++)
      t = addition(t, scalar_mul(G1Point(vk[16+2*j], vk[17+2*j]), input[j]));  //vk.IC[j + 1] == G1Point(vk[16+2*j], vk[17+2*j])

    p_input[12] = t.X;
    p_input[13] = t.Y;

    p_input[14] = vk[6];
    p_input[15] = vk[7];
    p_input[16] = vk[8];
    p_input[17] = vk[9];

    //C computation
    p_input[18] = proof[6];   //proof.C == G1Point(proof[6], proof[7])
    p_input[19] = proof[7];

    p_input[20] = vk[10];
    p_input[21] = vk[11];
    p_input[22] = vk[12];
    p_input[23] = vk[13];


    uint[1] memory out;
    bool success;
    // solium-disable-next-line 
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(p_input, 0x20), 768, out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success case 0 { invalid() }
    }

    require(success);
    return out[0] != 0;
  }

}

// File: contracts/lib/UnstructuredStorage.sol

pragma solidity >=0.6.0;


contract UnstructuredStorage {
    function set_uint256(bytes32 pos, uint256 value) internal {
        // solium-disable-next-line
        assembly {
            sstore(pos, value)
        }
    }

    function get_uint256(bytes32 pos) internal view returns(uint256 value) {
        // solium-disable-next-line
        assembly {
            value:=sload(pos)
        }
    }

    function set_address(bytes32 pos, address value) internal {
        // solium-disable-next-line
        assembly {
            sstore(pos, value)
        }
    }

    function get_address(bytes32 pos) internal view returns(address value) {
        // solium-disable-next-line
        assembly {
            value:=sload(pos)
        }
    }


    function set_bool(bytes32 pos, bool value) internal {
        // solium-disable-next-line
        assembly {
            sstore(pos, value)
        }
    }

    function get_bool(bytes32 pos) internal view returns(bool value) {
        // solium-disable-next-line
        assembly {
            value:=sload(pos)
        }
    }

    function set_bytes32(bytes32 pos, bytes32 value) internal {
        // solium-disable-next-line
        assembly {
            sstore(pos, value)
        }
    }

    function get_bytes32(bytes32 pos) internal view returns(bytes32 value) {
        // solium-disable-next-line
        assembly {
            value:=sload(pos)
        }
    }


    function set_uint256(bytes32 pos, uint256 offset, uint256 value) internal {
        // solium-disable-next-line
        assembly {
            sstore(add(pos, offset), value)
        }
    }

    function get_uint256(bytes32 pos, uint256 offset) internal view returns(uint256 value) {
        // solium-disable-next-line
        assembly {
            value:=sload(add(pos, offset))
        }
    }

    function set_uint256_list(bytes32 pos, uint256[] memory list) internal {
        uint256 sz = list.length;
        set_uint256(pos, sz);
        for(uint256 i = 0; i<sz; i++) {
            set_uint256(pos, i+1, list[i]);
        }
    }

    function get_uint256_list(bytes32 pos) internal view returns (uint256[] memory list) {
        uint256 sz = get_uint256(pos);
        list = new uint256[](sz);
        for(uint256 i = 0; i < sz; i++) {
            list[i] = get_uint256(pos, i+1);
        }
    }
}

// File: contracts/OptimisticRollup.sol

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;






contract OptimisticRollup is UnstructuredStorage {
    struct Message {
        uint256[4] data;
    }

    struct TxExternalFields {
        address owner;
        Message[2] message;
    }

    struct Proof {
        uint256[8] data;
    }

    struct VK {
        uint256[] data;
    }

    struct Tx {
        uint256[2] nullifier;
        uint256[2] utxo;
        IERC20 token;
        uint256 delta;
        TxExternalFields ext;
        Proof proof;
    }

    struct BlockItem {
        Tx ctx;
        uint256 new_root;
        uint256 deposit_blocknumber;
    }
    struct BlockItemNote {
        bytes32[8] proof;
        uint256 id;
        BlockItem item;
    }

    struct UTXO {
        address owner;
        IERC20 token;
        uint256 amount;
    }

    struct PayNote {
        UTXO utxo;
        uint256 blocknumber;
        uint256 txhash;
    }

    bytes32 constant PTR_ROLLUP_BLOCK = 0xd790c52c075936677813beed5aa36e1fce5549c1b511bc0277a6ae4213ee93d8; // zeropool.instance.rollup_block
    bytes32 constant PTR_DEPOSIT_STATE = 0xc9bc9b91da46ecf8158f48c23ddba2c34e9b3dffbc3fcfd2362158d58383f80b; //zeropool.instance.deposit_state
    bytes32 constant PTR_WITHDRAW_STATE = 0x7ad39ce31882298a63a0da3c9e2d38db2b34986c4be4550da17577edc0078639; //zeropool.instance.withdraw_state

    bytes32 constant PTR_ROLLUP_TX_NUM = 0xeeb5c14c43ac322ae6567adef70b1c44e69fe064f5d4a67d8c5f0323c138f65e; //zeropool.instance.rollup_tx_num
    bytes32 constant PTR_ALIVE = 0x58feb0c2bb14ff08ed56817b2d673cf3457ba1799ad05b4e8739e57359eaecc8; //zeropool.instance.alive
    bytes32 constant PTR_TX_VK = 0x08cff3e7425cd7b0e33f669dbfb21a086687d7980e87676bf3641c97139fcfd3; //zeropool.instance.tx_vk
    bytes32 constant PTR_TREE_UPDATE_VK = 0xf0f9fc4bf95155a0eed7d21afd3dfd94fade350663e7e1beccf42b5109244d86; //zeropool.instance.tree_update_vk
    bytes32 constant PTR_VERSION = 0x0bf0574ec126ccd99fc2670d59004335a5c88189b4dc4c4736ba2c1eced3519c; //zeropool.instance.version
    bytes32 constant PTR_RELAYER = 0xa6c0702dad889760bc0a910159487cf57ece87c3aff39b866b8eaec3ef42f09b; //zeropool.instance.relayer

    function get_rollup_block(uint256 x) internal view returns(bytes32 value) {
        bytes32 pos = keccak256(abi.encodePacked(PTR_ROLLUP_BLOCK, x));
        value = get_bytes32(pos);
    }

    function set_rollup_block(uint256 x, bytes32 value) internal {
        bytes32 pos = keccak256(abi.encodePacked(PTR_ROLLUP_BLOCK, x));
        set_bytes32(pos, value);
    }

    function get_deposit_state(bytes32 x) internal view returns(uint256 value) {
        bytes32 pos = keccak256(abi.encodePacked(PTR_DEPOSIT_STATE, x));
        value = get_uint256(pos);
    }

    function set_deposit_state(bytes32 x, uint256 value) internal {
        bytes32 pos = keccak256(abi.encodePacked(PTR_DEPOSIT_STATE, x));
        set_uint256(pos, value);
    }



    function get_withdraw_state(bytes32 x) internal view returns(uint256 value) {
        bytes32 pos = keccak256(abi.encodePacked(PTR_WITHDRAW_STATE, x));
        value = get_uint256(pos);
    }

    function set_withdraw_state(bytes32 x, uint256 value) internal {
        bytes32 pos = keccak256(abi.encodePacked(PTR_WITHDRAW_STATE, x));
        set_uint256(pos, value);
    }



    function get_rollup_tx_num() internal view returns(uint256 value) {
        value = get_uint256(PTR_ROLLUP_TX_NUM);
    }

    function set_rollup_tx_num(uint256 value) internal {
        set_uint256(PTR_ROLLUP_TX_NUM, value);
    }

    function get_alive() internal view returns(bool value) {
        value = get_bool(PTR_ALIVE);
    }

    function set_alive(bool x) internal {
        set_bool(PTR_ALIVE, x);
    }

    function get_tx_vk() internal view virtual returns(VK memory vk) {
        vk.data = get_uint256_list(PTR_TX_VK);
    }

    function set_tx_vk(VK memory vk) internal {
        set_uint256_list(PTR_TX_VK, vk.data);
    }

    function get_tree_update_vk() internal view virtual returns(VK memory vk) {
        vk.data = get_uint256_list(PTR_TREE_UPDATE_VK);
    }

    function set_tree_update_vk(VK memory vk) internal {
        set_uint256_list(PTR_TREE_UPDATE_VK, vk.data);
    }

    function get_version() internal view returns(uint256 value) {
        value = get_uint256(PTR_VERSION);
    }

    function set_version(uint256 value) internal {
        set_uint256(PTR_VERSION, value);
    }

    function get_relayer() internal view returns(address value) {
        value = get_address(PTR_RELAYER);
    }

    function set_relayer(address value) internal {
        set_address(PTR_RELAYER, value);
    }


    modifier onlyInitialized(uint256 version) {
        require(get_version() == version, "contract should be initialized");
        _;
    }

    modifier onlyUninitialized(uint256 version) {
        require(get_version() < version, "contract should be uninitialized");
        _;
    }

    modifier onlyRelayer() {
        require(msg.sender == get_relayer(), "This is relayer-only action");
        _;
    }

    modifier onlyAlive() {
        require(get_alive(), "Contract stopped");
        _;
    }

    function blockItemHash(BlockItem memory item)
        internal
        pure
        returns (bytes32 itemhash, bytes32 txhash)
    {
        txhash = keccak256(abi.encode(item.ctx));
        itemhash = keccak256(
            abi.encode(txhash, item.new_root, item.deposit_blocknumber)
        );
    }

    function groth16verify(
        VK memory vk,
        Proof memory proof,
        uint256[] memory inputs
    ) internal view returns (bool) {
        return Groth16Verifier.verify(vk.data, proof.data, inputs);
    }

}

// File: contracts/Verifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
//
pragma solidity >=0.6.0;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r  the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(16461201391116648893130744726782803036718499744064442697375174438685124886915,2457344066654894327735138139250972017404297629697906209168949279059558144362);
        vk.beta2 = Pairing.G2Point([567139989021991995252008170019725379566035982861909379744360171496029558444,3579984852314404341215876139806429345483733724019672123034499131563870700228], [5905148880663633547641026089494826907729813608824941938949648756343559136159,458135785322412138165099624646499450335782192760525409320707335840823819350]);
        vk.gamma2 = Pairing.G2Point([7084554711286031675321986313585444393620564903258062792927865824099175448286,5386057252313684807057561936974421481315637234461963803767175529954884758621], [9507390962357734150263668796755608186142578858627899324527607875724359373814,1258445054063121028259878701826766198272208632367019830913431700998247454819]);
        vk.delta2 = Pairing.G2Point([3707828972548553138872693738423331971243147650600791475971790869175003538145,9475294979560122155279190009229159190231879895895016676474597710374967100715], [18735731591433152463686807309927628362347127596379224985236644382200048507219,2461773015177161274244023750758467861937268052236169852677206384352012689002]);
        vk.IC = new Pairing.G1Point[](8);
        vk.IC[0] = Pairing.G1Point(12851550691103316179959326341146375868443785963086810132255654205467728747943,10182679905697758584587246885634785924574271098654597404387179355880031794172);
        vk.IC[1] = Pairing.G1Point(18223001143863199630181489321278511176382116687968172774258387078128042643388,19073151241819631997729650943557476299140720511992027569286992355969606643474);
        vk.IC[2] = Pairing.G1Point(17949406801949337923855866423653288946042084722485724783669645089817117445740,2707786970369155019737771510342855623687925041357295993112533418901590892494);
        vk.IC[3] = Pairing.G1Point(5371445401237234847827897344282475924520902093217865704960971608489041588344,4460411734726955633815315121095846796058129532589002211692143881005915849548);
        vk.IC[4] = Pairing.G1Point(3320426679163945321404985742700827929766910446739900170778678837895511328151,13456398837250155927209183963147617020945514116439133824181071658322347156854);
        vk.IC[5] = Pairing.G1Point(10042503184246899720653341974704018433789069889614246001828471235852223109367,9910017717836678193812129988621249778279314670108331034627636597864216592677);
        vk.IC[6] = Pairing.G1Point(15380968925461101418710161095986607209466469178864083643861523650403780102312,21619776648143318908824860812625161164809758090279715081682632886950683197277);
        vk.IC[7] = Pairing.G1Point(19379068384770705680447447710546037383770053891574486081398569557386460977298,17434292131992640768169401825137280457456028531121186504574539030141973695971);

    }
    function verify(
        uint256[] memory input,
        Proof memory proof,
        VerifyingKey memory vk
    ) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[7] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof, verifyingKey()) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/IERC20Receiver.sol

pragma solidity >=0.6.0;

interface IERC20Receiver {
    function onTokenBridged(
        address token,
        uint256 value,
        bytes calldata data
    ) external;
}

// File: contracts/ZeroPoolVerify.sol

pragma solidity >=0.6.0;






contract ZeroPoolVerify is OptimisticRollup, IERC20Receiver {
    using AbstractERC20 for IERC20;

    uint256 constant DEPOSIT_EXISTS = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant DEPOSIT_EXPIRES_BLOCKS = 2;
    uint256 constant CHALLENGE_EXPIRES_BLOCKS = 10;
    uint256 constant BN254_ORDER = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant MAX_AMOUNT = 1766847064778384329583297500742918515827483896875618958121606201292619776;
    bytes32 constant PTR_BRIDGE = 0xfb40206b8ee843d30431702cf95a39a70f885c42fd32a111c58d352821cb8463; //omnibridge

    uint256 constant VERSION = 1;

    event Deposit();
    event DepositCancel();
    event NewBlockPack();
    event Withdraw();

    modifier onlyBridge {
        require(msg.sender == get_bridge(), "only bridge can call this function");
        _;
    }

    function rollup_block(uint x) external view returns(bytes32) {
        return get_rollup_block(x);
    }

    function deposit_state(bytes32 x) external view returns(uint256) {
        return get_deposit_state(x);
    }

    function withdraw_state(bytes32 x) external view returns(uint256) {
        return get_withdraw_state(x);
    }

    function rollup_tx_num() external view returns(uint256) {
        return get_rollup_tx_num();
    }

    function alive() external view returns(bool) {
        return get_alive();
    }

    function tx_vk() external view returns(VK memory) {
        return get_tx_vk();
    }

    function tree_update_vk() external view returns(VK memory) {
        return get_tree_update_vk();
    }

    function relayer() external view returns(address) {
        return get_relayer();
    }

    function initialized() external view returns(bool) {
        return get_version() < VERSION;
    }

    function version() external pure returns(uint256) {
        return VERSION;
    }

    function get_bridge() internal view returns(address value) {
        value = get_address(PTR_BRIDGE);
    }

    function set_bridge(address _bridge) internal {
        set_address(PTR_BRIDGE, _bridge);
    }
    
    function init(address relayer, address bridge) external onlyUninitialized(VERSION) {
        set_alive(true);
        set_relayer(relayer);
        set_version(VERSION);
        set_bridge(bridge);
    }

    function checkProof(Tx memory ctx) internal view returns (bool) {
        uint256[7] memory _inputs;

        _inputs[0] = ctx.nullifier[0];
        _inputs[1] = ctx.nullifier[1];
        _inputs[2] = ctx.utxo[0];
        _inputs[3] = ctx.utxo[1];
        _inputs[4] = uint256((uint160(address(ctx.token))));
        _inputs[5] = ctx.delta;
        _inputs[6] = uint256(keccak256(abi.encode(ctx.ext))) % BN254_ORDER;

        uint256[2] memory _a;
        uint256[2][2] memory _b;
        uint256[2] memory _c;

        _a[0] = ctx.proof.data[0];
        _a[1] = ctx.proof.data[1];
        _b[0][0] = ctx.proof.data[2];
        _b[0][1] = ctx.proof.data[3];
        _b[1][0] = ctx.proof.data[4];
        _b[1][1] = ctx.proof.data[5];
        _c[0] = ctx.proof.data[6];
        _c[1] = ctx.proof.data[7];

        return Verifier.verifyProof(_a, _b, _c, _inputs);
    }

    function publishBlock(
        uint256 protocol_version,
        BlockItem[] memory items,
        uint256 rollup_cur_block_num
    ) public payable onlyAlive returns (bool) {
        uint256 cur_rollup_tx_num = get_rollup_tx_num();

        require(rollup_cur_block_num == cur_rollup_tx_num >> 8, "wrong block number");
        require(protocol_version == get_version(), "wrong protocol version");

        uint256 nitems = items.length;
        require(nitems > 0 && nitems <= 256, "wrong number of items");
        for (uint256 i = 0; i < nitems; i++) {
            BlockItem memory item = items[i];

            require(checkProof(item.ctx), "proof verification failed");

            if (item.ctx.delta == 0) {
                require(item.deposit_blocknumber == 0, "deposit_blocknumber should be zero in transfer case");
                require(item.ctx.token == IERC20(address(0)), "token should be zero in transfer case");
                require(item.ctx.ext.owner == address(0), "owner should be zero in tranfer case");
            } else if (item.ctx.delta < MAX_AMOUNT) {
                uint256 amount = item.ctx.delta;
                if (msg.sender != get_bridge()) {
                    item.ctx.token.abstractReceive(item.ctx.ext.owner, amount);
                }
                emit Deposit();
            } else if (
                item.ctx.delta > BN254_ORDER - MAX_AMOUNT &&
                item.ctx.delta < BN254_ORDER
            ) {
                require(item.deposit_blocknumber == 0, "deposit blocknumber should be zero");
                uint256 amount = BN254_ORDER - item.ctx.delta;
                item.ctx.token.abstractTransfer(item.ctx.ext.owner, amount);
                emit Withdraw();
            } else revert("wrong behavior");
        }

        emit NewBlockPack();
        return true;
    }

    function stopRollup(uint256 lastvalid) internal returns (bool) {
        set_alive(false);
        if (get_rollup_tx_num() > lastvalid) set_rollup_tx_num(lastvalid);
    }

    function onTokenBridged(address _token, uint256 _value, bytes calldata _data) external override onlyBridge {
        // TODO check that _value equals delta from _data
        address(this).call(_data);
    }
}