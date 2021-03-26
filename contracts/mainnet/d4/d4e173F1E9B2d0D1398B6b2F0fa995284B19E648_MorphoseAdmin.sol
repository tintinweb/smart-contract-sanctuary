/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// File: contracts/Morph.sol

pragma solidity ^0.8.0;

interface Morph {
    function poseidon(bytes32[2] memory) external pure returns (bytes32);
}

// File: contracts/MerkleTree.sol

pragma solidity ^0.8.0;


uint256 constant MERKLE_DEPTH = 20;
uint256 constant MERKLE_LEAVES = 1 << MERKLE_DEPTH;

library MerkleTree {
    struct Data {
        Morph hasher;
        mapping(bytes32 => bool) roots;
        mapping(uint256 => bytes32) tree;
        uint256 numLeaves;
    }

    function insert(Data storage self, bytes32 value)
        internal
        returns (uint256 index)
    {
        require(self.numLeaves < MERKLE_LEAVES, "Slots exhausted");

        index = self.numLeaves;
        self.numLeaves++;

        uint256 node = MERKLE_LEAVES + index;
        self.tree[node] = value;

        while (node > 1) {
            node /= 2;
            self.tree[node] = self.hasher.poseidon(
                [self.tree[node * 2], self.tree[node * 2 + 1]]
            );
        }

        self.roots[self.tree[1]] = true;
    }

    function getPath(Data storage self, uint256 index)
        internal
        view
        returns (bytes32[MERKLE_DEPTH] memory hashes)
    {
        require(index < self.numLeaves, "Index out of bounds");

        uint256 node = MERKLE_LEAVES + index;

        for (uint256 i = 0; i < MERKLE_DEPTH; i++) {
            hashes[i] = self.tree[node ^ 1];
            node /= 2;
        }
    }
}

// File: contracts/MembershipVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
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
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
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
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
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
contract MembershipVerifier {
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
        vk.alfa1 = Pairing.G1Point(19999268883299812380118267745389058698359487558742858385672801683947009174841,10979465955338708482481933698167832325746603808865456750985292287877353355870);
        vk.beta2 = Pairing.G2Point([6068181524513427278587143754114992710203920567465128023830932235519822136628,16579293707019070536109697385456617347080855615194695274360466897444993251], [10091094195423517525628188919723607870162196765642914096795805721764659872311,13723776030631949818632750387918069001653144993639245536406298986026264197577]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(1079420831454985419248774125551839104961637639291459667533218182143041371810,17039110079959747649145914288243287982936033625997476751651169264994325890340);
        vk.IC[1] = Pairing.G1Point(12511859808514735597224780617509045821499483439843284007557068056972330496480,997227388947331052357481800682863872352525852736840780855125186785416544744);
        vk.IC[2] = Pairing.G1Point(14054648376065458965574031677607130893156944233741248968416170960442389869982,6837841949371117241092620520200022176087379095803818691557939890882667007650);
        vk.IC[3] = Pairing.G1Point(1172112811221215404787133472473218088776994768730531545732108558323402657475,5798126020275162237488557905091686019669976137618701955940067805955670887872);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/SafeMath.sol

pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
    assert(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

// File: contracts/Morphose.sol

pragma solidity ^0.8.0;




uint256 constant BN128_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

contract Morphose  {
    using MerkleTree for MerkleTree.Data;

    struct WithdrawProof {
        address payable recipent;
        bytes32 merkleRoot;
        bytes32 unitNullifier;
        bytes32[8] proof;
    }

    MembershipVerifier internal verifier;
    MerkleTree.Data internal merkleTree;
    mapping(bytes32 => bool) public withdrawn;
    uint256 public denomination;
    uint256 public currentUnits;
    uint256 public anonymitySet;

    event Deposit(bytes32 note, uint256 index, uint256 units);
    event Withdrawal(bytes32 unitNullifier);

    constructor(
        address morphAddr,
        address verifierAddr,
        uint256 denomination_
    ) {
        verifier = MembershipVerifier(verifierAddr);
        merkleTree.hasher = Morph(morphAddr);
        denomination = denomination_;
    }

    function deposit(bytes32 note) public payable {
        require(uint256(note) < BN128_SCALAR_FIELD, "Invalid note");
        require(msg.value >= denomination, "Not enough funds sent");
        require(
            msg.value % denomination == 0,
            "Value needs to be exact multiple of denomination"
        );

        uint256 units = msg.value / denomination;
        bytes32 leaf = merkleTree.hasher.poseidon([note, bytes32(units)]);
        uint256 index = merkleTree.insert(leaf);
        currentUnits += units;
        anonymitySet++;
        emit Deposit(note, index, units);
    }

    function withdraw(WithdrawProof calldata args) public {
        require(merkleTree.roots[args.merkleRoot], "Invalid merkle tree root");
        require(
            !withdrawn[args.unitNullifier],
            "Deposit has been already withdrawn"
        );

        require(
            verifyMembershipProof(
                args.proof,
                args.merkleRoot,
                args.unitNullifier,
                getContextHash(args.recipent, msg.sender)
            ),
            "Invalid deposit proof"
        );

        withdrawn[args.unitNullifier] = true;
        currentUnits--;

        if (currentUnits == 0) {
            anonymitySet = 0;
        }

        args.recipent.transfer(denomination - onePercent(denomination));
        payable(0x3e4Ff40a827d4Ede5336Fd49fBCbfe02c6530375).transfer(onePercent(denomination));//%1 to treasury
        emit Withdrawal(args.unitNullifier);
    }

    function getMerklePath(uint256 index)
        public
        view
        returns (bytes32[MERKLE_DEPTH] memory)
    {
        return merkleTree.getPath(index);
    }

    function getContextHash(
        address recipent,
        address relayer
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(recipent, relayer)) >> 3;
    }

    function onePercent(uint256 _value) public view returns (uint256)  {
        uint256 roundValue = SafeMath.ceil(_value, 100);
        uint256 onePercent = SafeMath.div(SafeMath.mul(roundValue, 100), 10000);
        return onePercent;
    }

    function maxSlots() public pure returns (uint256) {
        return MERKLE_LEAVES;
    }

    function usedSlots() public view returns (uint256) {
        return merkleTree.numLeaves;
    }

    function verifyMembershipProof(
        bytes32[8] memory proof,
        bytes32 merkleRoot,
        bytes32 unitNullifier,
        bytes32 context
    ) internal view returns (bool) {
        uint256[2] memory a = [uint256(proof[0]), uint256(proof[1])];
        uint256[2][2] memory b =
            [
                [uint256(proof[2]), uint256(proof[3])],
                [uint256(proof[4]), uint256(proof[5])]
            ];
        uint256[2] memory c = [uint256(proof[6]), uint256(proof[7])];
        uint256[3] memory input =
            [uint256(merkleRoot), uint256(unitNullifier), uint256(context)];
        return verifier.verifyProof(a, b, c, input);
    }
}

// File: contracts/MorphoseAdmin.sol

pragma solidity ^0.8.0;


contract MorphoseAdmin {
    struct Entry {
        uint256 index;
        address addr;
    }

    address public owner = msg.sender;
    address public morph;
    address public verifier;

    uint256[] internal denominations;
    mapping(uint256 => Entry) internal morphoses;

    event MorphoseDeployed(uint256 denomination, address addr);
    event MorphoseRemoved(uint256 denomination, address addr);

    constructor(address morph_, address verifier_) {
        morph = morph_;
        verifier = verifier_;
    }

    function transferOwner(address _owner) public restricted {
        owner = _owner;
    }

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function createMorphose(uint256 denomination) public restricted {
        Morphose newMorphose = new Morphose(morph, verifier, denomination);
        Entry storage entry = morphoses[denomination];

        if (entry.addr == address(0)) {
            entry.index = denominations.length;
            denominations.push(denomination);
        }

        entry.addr = address(newMorphose);
        emit MorphoseDeployed(denomination, address(newMorphose));
    }

    function getDenominations() public view returns (uint256[] memory) {
        return denominations;
    }

    function getMorphose(uint256 denomination) public view returns (address) {
        return morphoses[denomination].addr;
    }
}