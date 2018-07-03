// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the &quot;Software&quot;), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
            // Use &quot;invalid&quot; to make gas estimation work
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
            // Use &quot;invalid&quot; to make gas estimation work
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
            // Use &quot;invalid&quot; to make gas estimation work
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
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0xe1903ae683723801835b5f673f33847e2e3662cc2d27c38e43baffb343cb31e, 0x2c122b34b4f96ee2f4eb88ab9c6876f499d5c59e8992c6e217ab8b98f16c5305], [0x2dd36c9dcbc9cc53db7881f5d361a76327f9cfad6664ffd0861a00720272a7b5, 0x1f747eed34525244f0fb5f9e2a5a4e918bad0e50e83fe4b43232ddd44e4fb558]);
        vk.B = Pairing.G1Point(0x174e3cc7838e49f0fc267b0113e539eb4f6dd2a2da8f9c6dfce88a6603c668f6, 0x10dcda56d08dcc2bb6cf05ab40063c2397906f8d3ec78e490061dc8a039c28af);
        vk.C = Pairing.G2Point([0x1629eac493ffd003949bf879ea8729d8020684648cb102ad4b6a404e5e82a860, 0x26508364415b6712330ef4702a0536e93cc9dbee742a9f15359bdac6aedd298e], [0x185e4524a78b0888c1196292c27cb2ff3d6077de92fd0bba07cb5055e9d3297e, 0x14ef91ab27e9360a2367a0b66d88659504e0963089f806e55c99bc6574b23cb0]);
        vk.gamma = Pairing.G2Point([0x7c5ad63bb64e182e0d7a400d5a781e33464aee0e5b87af894759d65843f429, 0x781d8ec8333ff2bf82026f0b6f970d2a0f1a4772e8e370109a98552375bfb9f], [0x290b4316215fa62fd9a81f27fe4f930814b59bbca72568d5950996b13c7b24f8, 0x1269e4f770a8205b340f2ac7e886d83dd5ab461c3f808f3095342444fbd380c6]);
        vk.gammaBeta1 = Pairing.G1Point(0x2f9155b1100cde7e065905924cc6e55b595bb0a5b8f30ff2bbf26170cd072b80, 0x167fa5d644e7cd4795ac902bc162899b1dbc6e069f5a8bfdc5b4cb1b467b402c);
        vk.gammaBeta2 = Pairing.G2Point([0x178d72a35abbd37519859b4569aa23925695bb843bf84c3f60349820d79f6b94, 0x158b749625aa47cdeae1910fd9a59d8710a138dc2229277add981fb4358810e8], [0x2f1fd7e9f901dfd35e8edbc35c2c19324d8a8bade115704b647217e73d4ef698, 0xed05f07299e11342646632184552951507aadcfcbf1ec07bc9a00ad9a47bfec]);
        vk.Z = Pairing.G2Point([0x34df20a9933637ef632d471a28a42341eb639f9801006cd1be7466e875fca24, 0x18191d3de652f8df0ee135ece5f5043d1e05d3b176a71f8c0a8f5b99db46f9fd], [0x20e1534ac450659ce1c9e9457d5584346b54568607959d402d756f93e27c9ccc, 0x155b25278fb19930c104218c3fac7325a58e2d69e4412175dc60b375b8ba8e83]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(0x13a2c587eb71c2a4e965603ff3e86d47cf7025ec3c95542da074046c5b178d41, 0x2559b3f7b25b1713013227c97d53ca3d30a326cb6fd989549616bcc31ff4f4c4);
        vk.IC[1] = Pairing.G1Point(0x1ec0b7c3e05abaf50e43373f4eff0dad03b4912f210a8e14a9be501270e6520c, 0xe2baac24375a7f1109d42f23949f167a89b103da125d9c7e585b9847efe262);
        vk.IC[2] = Pairing.G1Point(0x2bef28ddc6c3f8e46d314c428e9b336e5dc9338ad0d8ebb2bcf61bfd729188, 0x24785f678ac8855470be763006a723e2369005e73722975c23590b6ccd180109);
        vk.IC[3] = Pairing.G1Point(0x4aa175b16d23a6491b5e6bcb532f273889d8e6188b90bc63cc87d98472fe3b2, 0x8eceffbe7626d514d5c5b5f7d842de943e9a16b434b67f0438a1c6011bbfa13);
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
    event Verified(string);
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
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified(&quot;Transaction successfully verified.&quot;);
            return true;
        } else {
            return false;
        }
    }
}