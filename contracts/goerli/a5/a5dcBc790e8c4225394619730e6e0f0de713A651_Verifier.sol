// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero
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
     * @return r the sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input = [
            p1.X, p1.Y,
            p2.X, p2.Y
        ];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
     *         points p.
     */
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-mul-failed");
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
        uint256[24] memory input = [
            a1.X, a1.Y, a2.X[0], a2.X[1], a2.Y[0], a2.Y[1],
            b1.X, b1.Y, b2.X[0], b2.X[1], b2.Y[0], b2.Y[1],
            c1.X, c1.Y, c2.X[0], c2.X[1], c2.Y[0], c2.Y[1],
            d1.X, d1.Y, d2.X[0], d2.X[1], d2.Y[0], d2.Y[1]
        ];
        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, mul(24, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract Verifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[8] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
          vk.alfa1 = Pairing.G1Point(11465117836249954260815865875821374741827865987117488358056929741289450395454, 1052268272580629074379190939125980263983308905946631242770651428773097124609);
          vk.beta2 = Pairing.G2Point([5522112922638693255077472858989132518694872925223486402746719871447016035997, 9323266216127954098498767343292174412994788446155508342553123197909622474919], [10067354430014562037630999901209602758111444760448421418282115573330340897916, 10830161931861899553955792026243654795186828399254209933627426954589481078765]);
          vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]);
          vk.delta2 = Pairing.G2Point([16268284662012253551011603472988874581896270031227356290771274959971718981292, 1049789401458079223915354512226623997182014175995900027035085481463002743317], [2401168915411821708571434307728207008069542338731116947210606084611971703334, 4377981187591896661447332914126022259861171521553098264512583666435601769304]);
          
          vk.IC[0] = Pairing.G1Point(17617947796309913633033879390448232844604789349514098223941130162687650159008, 17346357615458054366016948897424972861600839916212017429175858761508112768345);
          vk.IC[1] = Pairing.G1Point(4160261244212410282740540174137797443000357762349456760427452666258281634655, 10659187970564361266401911054027693508596651272994185536394939682373133591481);
          vk.IC[2] = Pairing.G1Point(2426700727963839883125963293086408797329867932949826903819655837706057813733, 21094893171606925156945976452781962283002998862992794611241624376911014170227);
          vk.IC[3] = Pairing.G1Point(19523891677536897212490805885373830017030908782027633067437596647256641306894, 1169899796590863063631233591373311101057164196941533820493101551257276683239);
          vk.IC[4] = Pairing.G1Point(10182689738489949474701347235456094251230432804856044166712192214267104326123, 12620121188427273330943894767061134390470023783281980274058621012386472718316);
          vk.IC[5] = Pairing.G1Point(2056809025975301842690831552305735686318233508988643381967342064866013492391, 3960195661120568627798035589211436285682624873155088199357071231543937115084);
          vk.IC[6] = Pairing.G1Point(1551882644216845607500282592804363367809045543310798564794159286766313801711, 345904247515317740837890755024682892819384293337733397457716134089132913511);
          vk.IC[7] = Pairing.G1Point(15498489881415406932735571387384809110146605489005281179490713176855672819441, 18175838945573365488410002936921197302854555602050305602932644570309468584331);
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[7] memory input
    ) public view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        for (uint8 i = 0; i < p.length; i++) {
            // Make sure that each element in the proof is less than the prime q
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Pairing.G1Point memory proofA = Pairing.G1Point(p[0], p[1]);
        Pairing.G2Point memory proofB = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(p[6], p[7]);

        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = vk.IC[0];
        for (uint256 i = 0; i < input.length; i++) {
            // Make sure that every input is less than the snark scalar field
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-input-gte-snark-scalar-field");
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.IC[i + 1], input[i]));
        }

        return Pairing.pairing(
            Pairing.negate(proofA),
            proofB,
            vk.alfa1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proofC,
            vk.delta2
        );
    }
}