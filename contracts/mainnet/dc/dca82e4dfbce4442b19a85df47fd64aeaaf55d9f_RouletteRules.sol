pragma solidity ^0.4.23;

contract RouletteRules {
    uint8[5809] payoutTable; // 37 * 157
    address developer;

    constructor() public {
        developer = msg.sender;
    }

    function getTotalBetAmount(bytes32 first16, bytes32 second16) public pure returns(uint totalBetAmount) {
        uint a;
        uint b;
        for (uint i = 240; i >= 0; i -= 16) {
            a = uint(first16 >> i & 0xffff);
            b = uint(second16 >> i & 0xffff);
            if (a == 0) return totalBetAmount;
            else totalBetAmount = totalBetAmount + a + b;
        }
    }

    function getBetResult(bytes32 betTypes, bytes32 first16, bytes32 second16, uint wheelResult) public view returns(uint wonAmount) {
        uint a;
        // player can place maximum 32 types of bets
        for (uint i = 0; i < 32; i++) {
            // get corresponding bet amount
            if (i < 16) a = uint(first16 >> (240 - i * 16) & 0xffff);
            else a = uint(second16 >> (240 - (i - 16) * 16) & 0xffff);
            // break if bet amount is empty
            if (a == 0) break;
            // resolve result with calculated index
            wonAmount += a * payoutTable[wheelResult * 157 + uint(betTypes[i])];
        }
    }

    function initPayoutTable(uint processStart, uint processEnd) public {
        require(msg.sender == developer);
        uint8[7] memory payoutRate = [36, 18, 12, 9, 6, 3, 2];
        uint start;
        for (uint r = processStart; r <= processEnd; r++) {
            start = r * 157;
            payoutTable[start + r] = payoutRate[0];
            if (r == 0 || r == 1) payoutTable[start + 37] = payoutRate[1];
            if (r == 0 || r == 2) payoutTable[start + 38] = payoutRate[1];
            if (r == 0 || r == 3) payoutTable[start + 39] = payoutRate[1];
            if (r == 1 || r == 2) payoutTable[start + 40] = payoutRate[1];
            if (r == 2 || r == 3) payoutTable[start + 41] = payoutRate[1];
            if (r == 1 || r == 4) payoutTable[start + 42] = payoutRate[1];
            if (r == 2 || r == 5) payoutTable[start + 43] = payoutRate[1];
            if (r == 3 || r == 6) payoutTable[start + 44] = payoutRate[1];
            if (r == 4 || r == 5) payoutTable[start + 45] = payoutRate[1];
            if (r == 5 || r == 6) payoutTable[start + 46] = payoutRate[1];
            if (r == 4 || r == 7) payoutTable[start + 47] = payoutRate[1];
            if (r == 5 || r == 8) payoutTable[start + 48] = payoutRate[1];
            if (r == 6 || r == 9) payoutTable[start + 49] = payoutRate[1];
            if (r == 7 || r == 8) payoutTable[start + 50] = payoutRate[1];
            if (r == 8 || r == 9) payoutTable[start + 51] = payoutRate[1];
            if (r == 7 || r == 10) payoutTable[start + 52] = payoutRate[1];
            if (r == 8 || r == 11) payoutTable[start + 53] = payoutRate[1];
            if (r == 9 || r == 12) payoutTable[start + 54] = payoutRate[1];
            if (r == 10 || r == 11) payoutTable[start + 55] = payoutRate[1];
            if (r == 11 || r == 12) payoutTable[start + 56] = payoutRate[1];
            if (r == 10 || r == 13) payoutTable[start + 57] = payoutRate[1];
            if (r == 11 || r == 14) payoutTable[start + 58] = payoutRate[1];
            if (r == 12 || r == 15) payoutTable[start + 59] = payoutRate[1];
            if (r == 13 || r == 14) payoutTable[start + 60] = payoutRate[1];
            if (r == 14 || r == 15) payoutTable[start + 61] = payoutRate[1];
            if (r == 13 || r == 16) payoutTable[start + 62] = payoutRate[1];
            if (r == 14 || r == 17) payoutTable[start + 63] = payoutRate[1];
            if (r == 15 || r == 18) payoutTable[start + 64] = payoutRate[1];
            if (r == 16 || r == 17) payoutTable[start + 65] = payoutRate[1];
            if (r == 17 || r == 18) payoutTable[start + 66] = payoutRate[1];
            if (r == 16 || r == 19) payoutTable[start + 67] = payoutRate[1];
            if (r == 17 || r == 20) payoutTable[start + 68] = payoutRate[1];
            if (r == 18 || r == 21) payoutTable[start + 69] = payoutRate[1];
            if (r == 19 || r == 20) payoutTable[start + 70] = payoutRate[1];
            if (r == 20 || r == 21) payoutTable[start + 71] = payoutRate[1];
            if (r == 19 || r == 22) payoutTable[start + 72] = payoutRate[1];
            if (r == 20 || r == 23) payoutTable[start + 73] = payoutRate[1];
            if (r == 21 || r == 24) payoutTable[start + 74] = payoutRate[1];
            if (r == 22 || r == 23) payoutTable[start + 75] = payoutRate[1];
            if (r == 23 || r == 24) payoutTable[start + 76] = payoutRate[1];
            if (r == 22 || r == 25) payoutTable[start + 77] = payoutRate[1];
            if (r == 23 || r == 26) payoutTable[start + 78] = payoutRate[1];
            if (r == 24 || r == 27) payoutTable[start + 79] = payoutRate[1];
            if (r == 25 || r == 26) payoutTable[start + 80] = payoutRate[1];
            if (r == 26 || r == 27) payoutTable[start + 81] = payoutRate[1];
            if (r == 25 || r == 28) payoutTable[start + 82] = payoutRate[1];
            if (r == 26 || r == 29) payoutTable[start + 83] = payoutRate[1];
            if (r == 27 || r == 30) payoutTable[start + 84] = payoutRate[1];
            if (r == 28 || r == 29) payoutTable[start + 85] = payoutRate[1];
            if (r == 29 || r == 30) payoutTable[start + 86] = payoutRate[1];
            if (r == 28 || r == 31) payoutTable[start + 87] = payoutRate[1];
            if (r == 29 || r == 32) payoutTable[start + 88] = payoutRate[1];
            if (r == 30 || r == 33) payoutTable[start + 89] = payoutRate[1];
            if (r == 31 || r == 32) payoutTable[start + 90] = payoutRate[1];
            if (r == 32 || r == 33) payoutTable[start + 91] = payoutRate[1];
            if (r == 31 || r == 34) payoutTable[start + 92] = payoutRate[1];
            if (r == 32 || r == 35) payoutTable[start + 93] = payoutRate[1];
            if (r == 33 || r == 36) payoutTable[start + 94] = payoutRate[1];
            if (r == 34 || r == 35) payoutTable[start + 95] = payoutRate[1];
            if (r == 35 || r == 36) payoutTable[start + 96] = payoutRate[1];
            if (r == 0 || r == 1 || r == 2) payoutTable[start + 97] = payoutRate[2];
            if (r == 0 || r == 2 || r == 3) payoutTable[start + 98] = payoutRate[2];
            if (r == 1 || r == 2 || r == 3) payoutTable[start + 99] = payoutRate[2];
            if (r == 4 || r == 5 || r == 6) payoutTable[start + 100] = payoutRate[2];
            if (r == 7 || r == 8 || r == 9) payoutTable[start + 101] = payoutRate[2];
            if (r == 10 || r == 11 || r == 12) payoutTable[start + 102] = payoutRate[2];
            if (r == 13 || r == 14 || r == 15) payoutTable[start + 103] = payoutRate[2];
            if (r == 16 || r == 17 || r == 18) payoutTable[start + 104] = payoutRate[2];
            if (r == 19 || r == 20 || r == 21) payoutTable[start + 105] = payoutRate[2];
            if (r == 22 || r == 23 || r == 24) payoutTable[start + 106] = payoutRate[2];
            if (r == 25 || r == 26 || r == 27) payoutTable[start + 107] = payoutRate[2];
            if (r == 28 || r == 29 || r == 30) payoutTable[start + 108] = payoutRate[2];
            if (r == 31 || r == 32 || r == 33) payoutTable[start + 109] = payoutRate[2];
            if (r == 34 || r == 35 || r == 36) payoutTable[start + 110] = payoutRate[2];
            if (r == 0 || r == 1 || r == 2 || r == 3) payoutTable[start + 111] = payoutRate[3];
            if (r == 1 || r == 2 || r == 4 || r == 5) payoutTable[start + 112] = payoutRate[3];
            if (r == 2 || r == 3 || r == 5 || r == 6) payoutTable[start + 113] = payoutRate[3];
            if (r == 4 || r == 5 || r == 7 || r == 8) payoutTable[start + 114] = payoutRate[3];
            if (r == 5 || r == 6 || r == 8 || r == 9) payoutTable[start + 115] = payoutRate[3];
            if (r == 7 || r == 8 || r == 10 || r == 11) payoutTable[start + 116] = payoutRate[3];
            if (r == 8 || r == 9 || r == 11 || r == 12) payoutTable[start + 117] = payoutRate[3];
            if (r == 10 || r == 11 || r == 13 || r == 14) payoutTable[start + 118] = payoutRate[3];
            if (r == 11 || r == 12 || r == 14 || r == 15) payoutTable[start + 119] = payoutRate[3];
            if (r == 13 || r == 14 || r == 16 || r == 17) payoutTable[start + 120] = payoutRate[3];
            if (r == 14 || r == 15 || r == 17 || r == 18) payoutTable[start + 121] = payoutRate[3];
            if (r == 16 || r == 17 || r == 19 || r == 20) payoutTable[start + 122] = payoutRate[3];
            if (r == 17 || r == 18 || r == 20 || r == 21) payoutTable[start + 123] = payoutRate[3];
            if (r == 19 || r == 20 || r == 22 || r == 23) payoutTable[start + 124] = payoutRate[3];
            if (r == 20 || r == 21 || r == 23 || r == 24) payoutTable[start + 125] = payoutRate[3];
            if (r == 22 || r == 23 || r == 25 || r == 26) payoutTable[start + 126] = payoutRate[3];
            if (r == 23 || r == 24 || r == 26 || r == 27) payoutTable[start + 127] = payoutRate[3];
            if (r == 25 || r == 26 || r == 28 || r == 29) payoutTable[start + 128] = payoutRate[3];
            if (r == 26 || r == 27 || r == 29 || r == 30) payoutTable[start + 129] = payoutRate[3];
            if (r == 28 || r == 29 || r == 31 || r == 32) payoutTable[start + 130] = payoutRate[3];
            if (r == 29 || r == 30 || r == 32 || r == 33) payoutTable[start + 131] = payoutRate[3];
            if (r == 31 || r == 32 || r == 34 || r == 35) payoutTable[start + 132] = payoutRate[3];
            if (r == 32 || r == 33 || r == 35 || r == 36) payoutTable[start + 133] = payoutRate[3];
            if (r >= 1 && r <= 6) payoutTable[start + 134] = payoutRate[4];
            if (r >= 4 && r <= 9) payoutTable[start + 135] = payoutRate[4];
            if (r >= 7 && r <= 12) payoutTable[start + 136] = payoutRate[4];
            if (r >= 10 && r <= 15) payoutTable[start + 137] = payoutRate[4];
            if (r >= 13 && r <= 18) payoutTable[start + 138] = payoutRate[4];
            if (r >= 16 && r <= 21) payoutTable[start + 139] = payoutRate[4];
            if (r >= 19 && r <= 24) payoutTable[start + 140] = payoutRate[4];
            if (r >= 22 && r <= 27) payoutTable[start + 141] = payoutRate[4];
            if (r >= 25 && r <= 30) payoutTable[start + 142] = payoutRate[4];
            if (r >= 28 && r <= 33) payoutTable[start + 143] = payoutRate[4];
            if (r >= 31 && r <= 36) payoutTable[start + 144] = payoutRate[4];
            if (r % 3 == 1) payoutTable[start + 145] = payoutRate[5];
            if (r % 3 == 2) payoutTable[start + 146] = payoutRate[5];
            if (r != 0 && r % 3 == 0) payoutTable[start + 147] = payoutRate[5];
            if (r >= 1 && r <= 12) payoutTable[start + 148] = payoutRate[5];
            if (r >= 13 && r <= 24) payoutTable[start + 149] = payoutRate[5];
            if (r >= 25 && r <= 36) payoutTable[start + 150] = payoutRate[5];
            if (r >= 1 && r <= 18) payoutTable[start + 151] = payoutRate[6];
            if (r >= 19 && r <= 36) payoutTable[start + 152] = payoutRate[6];
            if (r % 2 == 1) payoutTable[start + 153] = payoutRate[6];
            if (r != 0 && r % 2 == 0) payoutTable[start + 154] = payoutRate[6];
            if (r == 1 || r == 3 || r == 5 || r == 7 || r == 9 || r == 12 || r == 14 || r == 16 || r == 18 || r == 19 || r == 21 || r == 23 || r == 25 || r == 27 || r == 30 || r == 32 || r == 34 || r == 36) payoutTable[start + 155] = payoutRate[6];
            if (r == 2 || r == 4 || r == 6 || r == 8 || r == 10 || r == 11 || r == 13 || r == 15 || r == 17 || r == 20 || r == 22 || r == 24 || r == 26 || r == 28 || r == 29 || r == 31 || r == 33 || r == 35) payoutTable[start + 156] = payoutRate[6];
        }
    }
}