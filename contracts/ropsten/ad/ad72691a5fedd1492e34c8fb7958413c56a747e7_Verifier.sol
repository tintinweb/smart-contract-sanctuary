// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.4.14;
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
    function P1() pure internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
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
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
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
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
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
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
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
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    bytes32 shaHash = 0x0;
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x2b411b59d5d023ef95d1ae4be5cde43484bf2b649cd02c63d1197547b99001e9, 0x23fe43daf9c39c93f38ed86c6ea57cc5d5e442f45227705f5a7c295a4a18c5f], [0x1158e594b11811cdd959b7696b2d0869c7c964e6f81957a566d4d9a906acf743, 0x1f2eb4fd5ee9bd268502b78df823cbf39582ab29ed2eac86bbe07749825967ad]);
		vk.B = Pairing.G1Point(0xdb22e6e9efe6d2579eaa5d5cafda432fdd2ad6f81c6447774456e6ffe18eada, 0x70f7c17d266c4d28f12e432d940c1a0988d4ca8724fea5fcdb7cab455c7e015);
		vk.C = Pairing.G2Point([0x8fe6b6a624dbdf880e2cfe5546b94d1ab579f7e9190ab2134eb7e44ecc3d715, 0x86b859fa896c7b261dde672e4e520253b3335995d8b2a48bc5770bda15ed4c7], [0x2843c40e8c2e74acf7b30438dcea03bd8844e894714560110d9d27eb049dbe52, 0x29a543e5783ffe71900a2f78b836a5ce8d3337b646c56b9203d57fdac83cbc48]);
		vk.gamma = Pairing.G2Point([0x28da8d8621271b1d68f79543b5504dcd88ce4ee6bc3e3c3346e05ae6bb80bd5f, 0x35c6ca7cc4bfd7ab894a204e2c21c2337f9333b6b1f2fb347f9926e9b8dfd9d], [0xc98d6b8d4c0795094a626de6e0b86d7e9ac73ed66620770a7a343c030ce40ea, 0x1a25151ac766e70f61f0fc0b294e45290988c22da69ca2dfa164da7fd654d08]);
		vk.gammaBeta1 = Pairing.G1Point(0x23060ee2cff8c1061fcf1f8ed4836bd9fa0601df0b8e885b4da564c28bad64ff, 0xd4e047984415a8403bae914d6e3fc0f73b8c068661a2e0ed19e95fa4f89137c);
		vk.gammaBeta2 = Pairing.G2Point([0x459dcfec97f3a0d47b979deac466375f98b8a719b4171d12dacbc62c326d2ba, 0x2f44e0ee3c5ad3f3ff5c0d0484b920ba36104f249c30e3a29b048a1d4583760d], [0x20ed592783ea3f17738fadbeb737b01ec91b4734190772b11cf3c36cd5a23d7c, 0x7f1eb73fbf460e31eed5c3508fe5360a319ed496e401e0fe3ffca78918fd84d]);
		vk.Z = Pairing.G2Point([0x675ad4e19ebcb3f6a149bc0e9aff17f1903050645e695d655f254818cb712d2, 0x15f0f87505905446bc726789391052eb90a80bb477bef7cf1637db689f2a575d], [0x1b1ad96e1c3a956ea2d49dfa23c70c5560632abbcad355a608650c56863897a2, 0x26bf3e2c48a086b27b02f9ff8acb9a91700327d6d9a69b7b47b0a327351306e8]);
		vk.IC = new Pairing.G1Point[](5);
		vk.IC[0] = Pairing.G1Point(0x14a133c5669f7342aad25ab64cf57bb688b573700a9e36d0997c9e3984b2673b, 0x2634c6ff0b6f491945e03b46279158e54bf02edfbd5b8e32146ca49fe426499e);
		vk.IC[1] = Pairing.G1Point(0x53987ce7172770651e1423eddc50d5337b8b869df94b6887e41293f71cc35a2, 0x4760a4872c3aec5659fe4e515be8b0795deb244d2c5d4e5495a2d997b40fa51);
		vk.IC[2] = Pairing.G1Point(0x1c396802b8fef9c2b055fbaad9bb146e9e9e568315ac1bfaf74f08e0636f2fba, 0xa752b3b9795c8bd71c19912bea6522b8b4b6f04b8470bfc1b24ca3ef6767c7a);
		vk.IC[3] = Pairing.G1Point(0x304e9f363ffd44ff526831a2d3578051be017962006d437fdd068f9640ad1c56, 0x74ae022c431b7ad35daa393ee15378e2d6e75ca6b3ca354997faadeff5b3ab5);
		vk.IC[4] = Pairing.G1Point(0x13d7d9806b9243575d4ce13f34d7d87b64c19f0a6bdf84f06246ca97e7d6196b, 0xe3a5f096fdf58f5c794505c200c03d4f96e83401e902ba1741c769a7680b9f3);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string s);
    event Failed(uint);
    event Input(uint[]);
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
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length+1);
        inputValues[0] = uint(shaHash);
        for(uint i = 1; i < inputValues.length; i++){
            inputValues[i] = input[i-1];
        }
        emit Input(inputValues);
        uint result = verify(inputValues, proof);
        if (result == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            emit Failed(result);
            return false;
        }
    }
    
    event PreHash(bytes);
    function addOrder(bytes32 order) public {
        bytes memory h = abi.encodePacked(shaHash, order);
        emit PreHash(h);
        shaHash = sha256(h);
    }
    
    function reset() public {
        shaHash = 0x0;
    }
    function read() public view returns (bytes32) {
        return shaHash;
    }
}