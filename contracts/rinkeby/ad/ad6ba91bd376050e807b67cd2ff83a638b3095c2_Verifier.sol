/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: AML
// 
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
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

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
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

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
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
}

contract Verifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[13] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(7861457819783165755907655065085216834560522205432649486855270260376402376690), uint256(20674988008115679118498254639030499012402835306603444152358866137383965599671));
        vk.beta2 = Pairing.G2Point([uint256(2885106321571658514530213488347171682199715684548027277809567275739161241240), uint256(21878403933772911112416100744343154539551838511643237840137230658951016749448)], [uint256(19325382700868445072752747062250288841541285803913275311317975568900625158048), uint256(3387273068439238347048400388719555959754899473482436471385953526232579731405)]);
        vk.gamma2 = Pairing.G2Point([uint256(21531170436768095912953563931458668542020926253757359441850042582405408432984), uint256(1588676248761259975382901568047532330357830319763186913747021378104910550084)], [uint256(13109612067336967402763842217322792063978743691059644077837993978728192769803), uint256(13645542374284919934866046332065480148935745134982162800890628514745821528838)]);
        vk.delta2 = Pairing.G2Point([uint256(21834087906559473080491140105048863535491675089124137177484653336842385880195), uint256(7862543341552791667595200097847237457155132372844109662070055666743430669071)], [uint256(15429421171369878905296667296659542876322115874867585842193432272778991701969), uint256(18428152555156282819870708221710389973720398849271837155702945239390512021522)]);   
        vk.IC[0] = Pairing.G1Point(uint256(18899520182050158967888069795485137422346862893312262020469710738582877817178), uint256(15817909895044064689143181608158478241486990923764337630408111877283176533516));   
        vk.IC[1] = Pairing.G1Point(uint256(1693851977746321254672115214736401738693357952645269400487177119923959434084), uint256(1009388183183617396039711135097514866897935439172334529726679383505552881982));   
        vk.IC[2] = Pairing.G1Point(uint256(18300974015880879913549854663965447167598563334058312230405686230012278056954), uint256(1534587861027527631850510372952841392507100617616162112685971655741112944142));   
        vk.IC[3] = Pairing.G1Point(uint256(9463697636072721442128830094551758043505415337236934896722659847629229336245), uint256(7995947712315759111613052891022008213044028952989578594555874259081153553789));   
        vk.IC[4] = Pairing.G1Point(uint256(1571418015988769243420803663216974326426899747211251175397284797774607361653), uint256(3601433518126464810924419930401294452883948003830184744193847004378831500313));   
        vk.IC[5] = Pairing.G1Point(uint256(886823220384534012450722138466097735539353757008231223675845638152514823069), uint256(6272619607426823222981743275448804138253377842853523301500236851156227122979));   
        vk.IC[6] = Pairing.G1Point(uint256(3395398287902870544561101185725251825352119461956761950689850476787686749132), uint256(3326727870581640985971195717209551199636424056163644885721306482541484137701));   
        vk.IC[7] = Pairing.G1Point(uint256(12201145749545918589080380595660551583217638901860366337790823755263586995847), uint256(5418201669549142078962702185826410757806433980030253401822208491023604252206));   
        vk.IC[8] = Pairing.G1Point(uint256(6633230215531318201907654913118239373412883844124933726208895100063462694038), uint256(20127327642922206362451993065970260011211273340980372771609627792590147478118));   
        vk.IC[9] = Pairing.G1Point(uint256(7045665241117250971198619580963164188720976259848808775701371760670067906219), uint256(17752909107290280091629789291101998006587573002116671118263354475809460730518));   
        vk.IC[10] = Pairing.G1Point(uint256(1052922285400538534131393711830757326942620835072469543882150843106313806699), uint256(21411095605616861016864488570443946869177344179167545390612115957247416460691));   
        vk.IC[11] = Pairing.G1Point(uint256(4123274154319222559219329329553626940429704438500412485585265163439293781372), uint256(20456675470381975413000962857035582996645445583870372966321765647344298072258));   
        vk.IC[12] = Pairing.G1Point(uint256(14219193232840512705464186378348062021697277351225910788562791646362945789907), uint256(5564405655179070979240821540788412535222460609024238793351920784728471109498));
    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[12] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}