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
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) view internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) view internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) view internal returns (bool) {
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
            success := staticcall(sub(gas, 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) view internal returns (bool) {
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
    ) view internal returns (bool) {
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
    ) view internal returns (bool) {
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
        vk.A = Pairing.G2Point([16610027721320090851672124826930543804510863425028512395206306928317475535804,8936789845922544559097602524648054597031330865008407381460968729887808214434], [2278578217592196498969542612994107970434638305320265550173445225942027074854,18336449124045676471393750622290479431334440531824730522288602977607157240650]);
        vk.B = Pairing.G1Point(1984924168632842141759455341627143753024960974027438898638858975972756407564,10991053238332375915565380359166789463201591761740938272761726473772838859618);
        vk.C = Pairing.G2Point([10660728934017853141365044466918475010597411890641229655657848436103395876116,3996391662237560225890291735380647896924014963474714424016445511172825791389], [5221331779058503178196633838312686055158887166644266661901185854029433298779,12183448649224206996148652487149426507910593413372228701177454061805688094675]);
        vk.gamma = Pairing.G2Point([19004037734259218065220057650211328986997252342301116788268586579684875932598,18093848281567039857436784662151682189745312020865996311429156694186522940309], [5377856403552463400841775516298918127240964967532295209455188775179474313786,2889539749595311565918940419300442407947814810042015422814827877135693568505]);
        vk.gammaBeta1 = Pairing.G1Point(7796626316580434743798382369107477206221192049125686546210621144964120983689,7934884528679805498299923633957794379202307702360555586276991024938091670488);
        vk.gammaBeta2 = Pairing.G2Point([4487005664450616024577102016311266690760571702764152553013463219021170678312,372268767343205135890641734006927513939290443891671725490699149337509414363], [8727588333078631340262914721329976700431073842680933627593659695896604918915,5027865297535949490479385388683367202474878200260477572501220964101178956894]);
        vk.Z = Pairing.G2Point([10162018577464408960423216104240658562943290569546240862381635704410977689235,15750847760428609853592351550031388692358090666989687368017823231947603993362], [13703537493621251480372183323146309058645469102580923196624726955632303691613,10133848043702140632001179191067180047829615626613968726429425860753144960369]);
        vk.IC = new Pairing.G1Point[](2);
        vk.IC[0] = Pairing.G1Point(10205875104072397627386129936295372804967786394340262122517620344193853862704,3108802252545217304319096845192350237223097046684036942919565176050064079266);
        vk.IC[1] = Pairing.G1Point(19450223878547003131641146404062695786601341609154957657760980302351711435043,2090278837353290546550331589621169669090493301065290400727820127066575899332);

    }
    function verify(uint[] input, Proof proof) view internal returns (uint) {
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
    function verifyProof(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[1] input
        ) view public returns (bool r) {
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
            return true;
        } else {
            return false;
        }
    }



    function test0() public view returns (bool) {
        return verifyProof(
            /* a */ [uint(0), uint(0)],
            /* ap */ [uint(0), uint(0)],
            /* b */ [[uint(0), uint(0)],
             [uint(0), uint(0)]],
            /* bp */[uint(0), uint(0)],
            /* c */ [uint(0), uint(0)],
            /* cp */ [uint(0), uint(0)],
            /* h */[uint(0), uint(0)],
            /* k*/[uint(0), uint(0)],
            [uint(0)]
        );
    }

    function test1() public view returns (bool)  {
        return verifyProof([uint(0x0602632d44b200a05e4cfd67a309e04794315ed46d5da0a11eaa059369864d42), uint(0x0f15410e46e065c59953e718012a45b7cf3a0d556c1a75b838158f10687ded5b)],[uint(0x119ad9e6f9bf39eb3d9858f1c0cb5297aa37acf2cf93c1f342ece20f4b731d7d), uint(0x2fc2bdd65dd5199cb167083933c5222cb29491e873300ffdb9cd1281c49a06d4)],[[uint(0x13414550f16bc3262fd4abfa4d61748462cb6c755ebb86600180a0b7640358d0), uint(0x2b678937241a9853341eadd032ebe6e2bf4d76c9aa8f97c2cbaca765d90c0f75)],[uint(0x27b1a219ad6976554cadd275d69ccf4dbe94128e3a34a0ba3039831b38faf384), uint(0x149733a9b879b2ad2d006171cb38e9dde2991f91edd7450b152da32557845c86)]],[uint(0x154d55e21ecb9ea4af229d25e790bf49bb0c3654b60de059e34a4b693f3585f6), uint(0x17491a6426c30d0be4331995853327a697026daa4f1b73ce552b54e8b0121de0)],[uint(0x069619e938167105cd94970c92c3e6e76eb8905bf43464bb4fcac05adfac2acc), uint(0x06f33230fc12bda6b7184c0086f11179bf0dd8ac2e8395fa3d4efbf217758357)],[uint(0x18b93d66e71761b1e9ceaf34f936be2cb15eda9622acdd7afd49d60fcd82099f), uint(0x2f8ac94ffecae821f38f6231f70330ddcc4521a77bc3878fb1f1d872bdb2c080)],[uint(0x0a3eaf6de7502d4cbad70b3c30f7a206a0f0e1a0a30413621528d4889ddcfe60), uint(0x2e799eba147970db2ed59599eefd69259a0a487c24f08a44071f21ede0c5698e)],[uint(0x2d48611e80abd84c1c3b21caf1b2e636bbb1a1f50e42a2b63d42091656bcc696), uint(0x28179e77d6247019d872e6cca0f32bcd88ae342b0c8c62e0922d19707d7e60a2)],[uint(0x0dee3e68072fbfd918cbf36e62c3f41c9ec8235295135a79c36c35970d8dd121)]);
    }

    function test2() public view returns (bool) {
        return verifyProof(
[uint(0x24716a0541142875855f3f298cf5976e04f6a5e68b33678936d376642ef60966)
, uint(0x20ee387a5ea647340bbd2799b71c92ded1b3ff0f31032d7a3db1f9d40ed34735)
],[uint(0x0fa111ac605bba4abb2f4c09c64ea2d6ce743f4704ce72bd8a9799c66c38438e)
, uint(0x159987a24f09c8e26114dbc6a065288126c1c0cd0b9a9973a84ab5bbf93213b2)
],[[uint(0x16fc6460c7c525edf602a925de33adea2f9d8e05393f6d1c4a46c690b248b176)
, uint(0x0951b0b2e6302656b72117859e05f1cf1d799eb510da57eae27ae29db1062b8f)
],[uint(0x0fd953f1e59aa51bb982512dc7989d7e165186d6d03cfd1a90f9acae79058d7e)
, uint(0x118d97a702d7e489ba683251326c925586e949feff557ae7ab9dfb7050d44bd9)
]],[uint(0x101f2dbfdfabc2835391cefcc4d2945d49f5e70e526ce1bf18baf0369c971ff1)
, uint(0x17b512c47fd4407b1b902fcb9709805ff4f17cf87e1dec53e23557f644579bef)
],[uint(0x2c764241e5181bd177eea92a059abdd0dccb638e6fc5e55cf11c6591264c50ea)
, uint(0x06f46f76647756df13cb8d0b001348421480ca71017b62a91bd1c192a278d167)
],[uint(0x0d7f9fda55770627e09d179ba15a4a7457fa6efc7dae425bb648f8fcdc263e5b)
, uint(0x27305d3466a6aeb688449c5ab147de5bde476050dfc44b729cee22616b6f856c)
],[uint(0x1638039fa57ae7a26552e7beb462d58e71c11f670c2a14bdbfcabfaa8aeebf30)
, uint(0x2798792457ab7ac77c6a0af195b0769e56d519bab54e361d69b3198aa7acf162)
],[uint(0x0d41a11a9070e85d9539c55625cd7169dfe78819b5f48b3d743378ff32624867)
, uint(0x27e49b1c6270ebf23540e5873f8daef078b5b4fa417616b57e3fb9da9d45943f)
],[uint(0x0000000000000000000000000000000000000000000000000000000000000021)
]
        );
    }
}