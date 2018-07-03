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
        vk.A = Pairing.G2Point([0x27db448628ec04c15f9d55dc6a57b4fcb90a5b4fbea200c4d51d6e663ec392b8, 0x29944b1a35f2955e3f7457ee905e902117f165f8ee28fbaf5579fc2afd8b27e6], [0x270eb4ec9ef2a480392d919e7d62802a94b5cee450189749aa2f66c121efb4df, 0x7f59c7f68919f34e07b603864c59e1548f2b899759d9982cad603b3c3b8e12e]);
        vk.B = Pairing.G1Point(0x80494abffa6fc486985848623dec641b5c1d50003f984196c3cc619e8975610, 0x10b373c72633d53a3baa4dbca03ad273d573c78eb6a2ecef39e73459e3bc8102);
        vk.C = Pairing.G2Point([0x243a0fc38c604e671515a6619decab04cc8752b49648a9bdf2b766e72fb2de61, 0x2f70d267add6f30eac85434692b63f938abf183fcf081dc46adf196054185e74], [0x836cffd20f0080aa8c5d439ab5f52aa3258c783d4120919b4fec6b9a1db84e3, 0x1e2cf928e79690359d5696374008f4ed25103deafd210a3e36eda2d24a6fd02b]);
        vk.gamma = Pairing.G2Point([0x232f1070ccbb4486e1f39ce5e8106285855dec8f056834e3c06312cd3790cf91, 0x6ccd626757d1e9b73e4997b3eebd92b1cb9997c969e95ccfdab99443d5b3322], [0xe417b7f5d3bd1f8ebbc07c87ba8fe1984aea1e0be3f5b0febabb740569d50e4, 0x29adab5937dd0691b688f087866cd470b205fc6c509a3d9c2d7ee58dffbd98d1]);
        vk.gammaBeta1 = Pairing.G1Point(0xed588d27cb70fb8575018351764b596a1a8bba8c5e05f77c76cc8b172efcb2a, 0x22003b0f7eeaa9342e5cf550a977dee0192041e42ae73334ff51e01f6843a93);
        vk.gammaBeta2 = Pairing.G2Point([0x28be31203a3b558b543517b48c90afb92ebeb6cda0b087611e85cba66c33b2f6, 0x1186dc064b716d031408036e325be622ea72859eab457ae6cabb68639e63ef60], [0x25ffb997a164ab90dffa3e4621b24145c0317777c4ff70b9b07c934250dd86f8, 0xa2a44e48a4299eb1fbdec09d8f5445543d540199f43100e1d3867267d918d42]);
        vk.Z = Pairing.G2Point([0x12bff24288c53ff8d5992963cafe9c4786ca08891d51b4cc70b858e9e53c5d84, 0x2af5f56b5954015bd11c5d1e7caf262782562a4371ad38ab0e908ed27ed8b2b6], [0x1c517f896d8f8ea9689359439c02068ffdf49fc84fc7de6241c0b742179992fb, 0x2351f249a5e4c6342dba207f57b159bded453f46cf2e1ff64fba1c7870e15017]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x291764c75bd1fc18284ad4c4e7c5eebd14f2309991a9a4700b15d3a40725c5a, 0x10a5dd8b4e7a7b582ecea463f96bd2c08bc3f6bf8cb73d62f9751e72134f158);
        vk.IC[1] = Pairing.G1Point(0x15d686fd9936efd9cff7043eb6a8087c445e23cf69193b7ca38cb2d43c08a3d2, 0x187bf0d1213dc770dc35c53c17f726acb144de0fc83a0aa12167c764a84971b0);
        vk.IC[2] = Pairing.G1Point(0x2cfb5b7535d9be555cdb9ea3a642c2107bb34a0510774fdc925effe3e131136e, 0xe46b3ade2974979b6a56ad1763461d4690ab24ee74946c7d16615c138eaa76c);
        vk.IC[3] = Pairing.G1Point(0x6122492ec4e827d8c622c21919bdc0a804c8fecd52a961c35ff824b88c7e2a3, 0x2af297225f623623236d04220c74f0876e9a0c796d121f4c46d13a6df1c1d420);
        vk.IC[4] = Pairing.G1Point(0x2a84f2e50d6c57fc478fabaef98a0f5a52cfcf763992f24627f76adb467ada08, 0x18d954af7f29a38ce1d2ce981bfca576c92648d7dded41f6aacd06ac311b2d07);
        vk.IC[5] = Pairing.G1Point(0x820cb5589c62a359b1ee53d99615ba4043293f30782a30b47bbacdb771df609, 0x12b483f86d9ae642fc7b82a2aeb127741fb1609593b8383408cb84c808fbd021);
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
            uint[5] input
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