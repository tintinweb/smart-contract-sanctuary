/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// File: conceal/Withdraw-verifier.sol

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
pragma solidity ^0.5.0;
library WithdrawPairing {
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
            // Use "invalid" to make gas() estimation work
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
            // Use "invalid" to make gas() estimation work
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
            // Use "invalid" to make gas() estimation work
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
contract WithdrawVerifier {
    using WithdrawPairing for *;
    struct VerifyingKey {
        WithdrawPairing.G1Point alfa1;
        WithdrawPairing.G2Point beta2;
        WithdrawPairing.G2Point gamma2;
        WithdrawPairing.G2Point delta2;
        WithdrawPairing.G1Point[] IC;
    }
    struct Proof {
        WithdrawPairing.G1Point A;
        WithdrawPairing.G2Point B;
        WithdrawPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = WithdrawPairing.G1Point(16122224429361360165495896710323717556817569717927664220395352936364188773809,19308821304069049805487909812845259701152237731090531599799296719817622808649);
        vk.beta2 = WithdrawPairing.G2Point([15742195186009531957683019244119866265169218554156270986820785035986979675495,17971786283595192108143850323405651860279660450956743538933099503822871223695], [18812379374022613981626542441491307179275052911278345098663956354563845387572,18166637814736053124356707300125551037167460242150070094683100763475625606778]);
        vk.gamma2 = WithdrawPairing.G2Point([3804309165560051998936028570496335352199751706740247109147439328005396808068,7726080157922178985549115604237760997638511814566094495324846590011010856487], [21887078455765841214810112476742456197556360040327347118496184669249559407265,11401770191552387201812623678675357713046330086038195382201988942087404791489]);
        vk.delta2 = WithdrawPairing.G2Point([12243584111877061836716328913839833000586664963497033512825182569139003987731,8515800110697566978083812163696401201110574051431329986371537532265314142798], [2936747634621792880292543256875975432268117684295820963043335114030947834550,2292076667648256500415679715482741933702823709162129642292800969344670318170]);
        vk.IC = new WithdrawPairing.G1Point[](6);
        vk.IC[0] = WithdrawPairing.G1Point(14113527843581317846786703524552352381462322135459069507318558830385257137643,5614687195709328189878978350488979314716330427373364361007458973144390766292);
        vk.IC[1] = WithdrawPairing.G1Point(10032336890966582629140836569190647598887172603885567890570620005848208915120,21266628694840328335966552182319322762834504474929837514822383825392202865679);
        vk.IC[2] = WithdrawPairing.G1Point(14351386369434505794664484682373329305740548482313796656557460426999048651406,9608572135874020459230326980104286369084126574215093271251307101873937457997);
        vk.IC[3] = WithdrawPairing.G1Point(17909736313133173174561604257312484946038490730388421060722551408626742680017,738642998879078751355623433014691460474547902353491836703558504393487768986);
        vk.IC[4] = WithdrawPairing.G1Point(8888450468048395100956572038184224797797919519092828590980891271655319302112,11549925395015303561525669850790742277156425046747348004261961575019205503500);
        vk.IC[5] = WithdrawPairing.G1Point(13567140135630962392180038295130654407516739677152840364794668209842724088609,21376772650052813881737297934707256387080009318463006972324308269531606627970);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        WithdrawPairing.G1Point memory vk_x = WithdrawPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = WithdrawPairing.addition(vk_x, WithdrawPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = WithdrawPairing.addition(vk_x, vk.IC[0]);
        if (!WithdrawPairing.pairingProd4(
            WithdrawPairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[5] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = WithdrawPairing.G1Point(a[0], a[1]);
        proof.B = WithdrawPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = WithdrawPairing.G1Point(c[0], c[1]);
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

// File: conceal/depositor-verifer.sol

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
pragma solidity ^0.5.0;
library DepositPairing {
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
            // Use "invalid" to make gas() estimation work
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
            // Use "invalid" to make gas() estimation work
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
            // Use "invalid" to make gas() estimation work
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
contract DepositVerifier {
    using DepositPairing for *;
    struct VerifyingKey {
        DepositPairing.G1Point alfa1;
        DepositPairing.G2Point beta2;
        DepositPairing.G2Point gamma2;
        DepositPairing.G2Point delta2;
        DepositPairing.G1Point[] IC;
    }
    struct Proof {
        DepositPairing.G1Point A;
        DepositPairing.G2Point B;
        DepositPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = DepositPairing.G1Point(10436172469864824943122622365866160700766733691225663281391281399768281792432,10013775164986556699748903408611044888497001527952485046148029488621290228585);
        vk.beta2 = DepositPairing.G2Point([6309523382050532091541080192957876574321484650081637658047902580386546515396,598834447583522476960665277503297970300165165045517679601275023833966991516], [8590716082440680164063032894460567742684770930570712765827215325137514538101,8041644809937488578904117444377291033263514510643299840024598892542107423696]);
        vk.gamma2 = DepositPairing.G2Point([9311246197523953352532181966516779338770754131311966565889991048533281336416,6806964349269168717187105400316621885061786836448630111519958812764418920687], [10418082789039162869629793611095143462256777121787211694416776365709854018377,2614882643262384713393249449267079986774540400035726921223478458896104844344]);
        vk.delta2 = DepositPairing.G2Point([19463756687631889938064438479781340527651301127382710593277385995401455789273,5164844382488576476366820908935907641518972821410840304322777611633491225058], [1020816115565590040942442095524606749442650898898841431006540382809871657232,8002327941064179861874658273740677379359751566880314418854454428845710739907]);
        vk.IC = new DepositPairing.G1Point[](7);
        vk.IC[0] = DepositPairing.G1Point(21411647262666990764495559661063800205412974836302731545741620815490889151788,17058251660887350087753253493452815562464770070825790645851768476857448866823);
        vk.IC[1] = DepositPairing.G1Point(4489528793234590408821674557567146513622182220068033318168722641066148346294,431598837137007722498041835307629832903486854852266353342117557231453915769);
        vk.IC[2] = DepositPairing.G1Point(12971765444327743169844725525786836847696064637452390413371071884747166637236,3928687943489294077114641274461068607167702548289196354483089718285113877074);
        vk.IC[3] = DepositPairing.G1Point(12188561213237719926849297698058632981780639967205666726128154962327519981564,20114624967037178164888953191668790590572692999526275989752914457005714918783);
        vk.IC[4] = DepositPairing.G1Point(9854055718096834032036282773533182355739137615821259876399996424552780097072,12998738893454613301889157021682490687033682582512707471705403431995499740210);
        vk.IC[5] = DepositPairing.G1Point(3546128512065154825135784403453313722058122770291688746941788810443755482819,1292937756460425419713531469722969064281949505806489771298471758510194029601);
        vk.IC[6] = DepositPairing.G1Point(14884424934208839787266016288287746147730611302255501430594188536611873187312,4845001161750391503145769631284113687171234179175451959574268797554475015601);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        DepositPairing.G1Point memory vk_x = DepositPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = DepositPairing.addition(vk_x, DepositPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = DepositPairing.addition(vk_x, vk.IC[0]);
        if (!DepositPairing.pairingProd4(
            DepositPairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[6] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = DepositPairing.G1Point(a[0], a[1]);
        proof.B = DepositPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = DepositPairing.G1Point(c[0], c[1]);
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

// File: conceal/conceal.sol

pragma solidity ^0.5.0;



contract Conceal {
  DepositVerifier    dVerifier;
  WithdrawVerifier    wVerifier;

  uint256 key = 0;
  uint256 amount = uint256(1000000000000000000);
  uint256 root ;
  uint256[] commitments;
  mapping(uint256 => bool) nullifiers;

  constructor( address _depositVerifierContractAddr, address _withdrawVerifierContractAddr) public {
    dVerifier = DepositVerifier(_depositVerifierContractAddr);
    wVerifier = WithdrawVerifier(_withdrawVerifierContractAddr);
    root = uint256(7191590165524151132621032034309259185021876706372059338263145339926209741311);
  }

  function deposit(
            uint256 _commitment,
            uint256 _root,
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c
  ) public payable {
    // check root state transition update with zkp
    uint256[6] memory input = [
      0,
      msg.value,
      root, // rootOld
      _root, // rootNew
      _commitment,
      key+1
    ];
    require(dVerifier.verifyProof(a, b, c, input), "zkProof deposit could not be verified");

    require(msg.value==amount, "value should be 1 ETH"); // this can be flexible with a wrapper with preset fixed amounts
    commitments.push(_commitment);
    root = _root;
    key += 1;
  }

  function getCommitments() public view returns (uint256[] memory, uint256, uint256) {
    return (commitments, root, key+1);
  }

  function withdraw(
            address payable _address,
            uint256 nullifier,
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c
  ) public {

    uint256[5] memory input = [
      0,
      amount,
      nullifier,
      root,
      uint256(_address)
    ];
    require(wVerifier.verifyProof(a, b, c, input), "zkProof withdraw could not be verified");
    // zk verification passed
    require(useNullifier(nullifier), "nullifier already used");
    // nullifier check passed
    // proceed with the withdraw

    _address.send(amount);
    // _address.call.value(amount).gas(20317)();
  }

  function useNullifier(
    uint256 nullifier
  ) internal returns (bool) {
    if (nullifiers[nullifier]) {
      return false;
    }
    nullifiers[nullifier] = true;
    return true;
  }
}