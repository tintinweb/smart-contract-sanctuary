/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// 0x12301FBac84deECD2b642F7b33A09C4Ca60EdbCf
pragma solidity 0.4.26;

contract GameSlotContract {
    //v1: lines

    function verifyBet(uint256 v1, uint256 v2, uint256 v3, uint256 v4) public pure returns (bool) {
        if (!(v1 <= 20 && v1 >= 1)) return false;
        if (v2 != 0 || v3 != 0 || v4 != 0) return false;

        return true;
    }

    function payoutAmount(uint256 number, uint256 betAmount, uint256 v1, uint256 v2, uint256 v3, uint256 v4)
        public pure returns (uint256) {
        if (v2 != 0 || v3 != 0 || v4 != 0) return 0;

        uint256 winAmount;
        (winAmount, ) = result(number, v1, betAmount / v1);
        return winAmount;
    }

    function convertNumberToRandomMap(uint256 number) public pure returns (uint256[15]) {
        uint256[15] memory arr;
        uint256 n = number;
        for (uint256 i = 0; i < 15; i++) {
          uint256 v = n % 4501;
          arr[i] = v <= 50 ? 0 :
            v <= 550 ? 1 :
            v <= 1050 ? 2 :
            v <= 1500 ? 3 :
            v <= 1950 ? 4 :
            v <= 2350 ? 5 :
            v <= 2750 ? 6 :
            v <= 3100 ? 7 :
            v <= 3450 ? 8 :
            v <= 3750 ? 9 :
            v <= 4100 ? 10 :
            v <= 4300 ? 11 :
            12;
          n = n / 10000;
        }
        return arr;
    }
    function result(uint256 n, uint256 lines, uint256 betPerLine) public pure returns (uint256 payout, uint256[15] randomCards, uint256[20] winLines) {
        uint256 win = 0;
        uint256 value = 0;
        uint256 totalPayout = 0;
        uint256[15] memory cards = convertNumberToRandomMap(n);
        uint8[5][20] memory linesIndex = [
            [5, 6, 7, 8, 9],         //1
            [10, 11, 12, 13, 14],
            [0, 1, 2, 3, 4],
            [10, 6, 2, 8, 14],      //4
            [0, 6, 12, 8, 4],
            [5, 11, 7, 13, 9],      //6
            [5, 1, 7, 3, 9],
            [10, 11, 7, 3, 4],      //8
            [0, 1, 7, 13, 14],
            [5, 1, 7, 13, 9],       //10
            [5, 11, 7, 3, 9],
            [10, 6, 7, 8, 14],      //12
            [0, 6, 7, 8, 4],
            [10, 6, 12, 8, 14],     //14
            [0, 6, 2, 8, 4],
            [5, 6, 12, 8, 9],       //16
            [5, 6, 2, 8, 9],
            [10, 11, 2, 13, 14],    //18
            [0, 1, 12, 3, 4],
            [10, 1, 2, 3, 14]       //20
        ];
        uint16[6][13] memory winLevels = [
            [uint16(0), 0, 15, 200, 1000, 5000],        //0
            [uint16(0), 0, 0, 5, 20, 100],              //1
            [uint16(0), 0, 0, 5, 20, 100],
            [uint16(0), 0, 0, 7, 25, 150],
            [uint16(0), 0, 0, 7, 25, 150],
            [uint16(0), 0, 0, 10, 30, 200],
            [uint16(0), 0, 0, 10, 30, 200],
            [uint16(0), 0, 0, 15, 75, 500],
            [uint16(0), 0, 0, 15, 75, 500],
            [uint16(0), 0, 5, 50, 100, 1000],
            [uint16(0), 0, 5, 100, 250, 2500],
            [uint16(0), 0, 10, 150, 500, 5000],
            [uint16(0), 0, 0, 3, 10, 100]               //13
        ];
        uint256[20] memory linesOfWin;
        for (uint i = 0; i < lines && i < 20; i++) {
            uint8[5] memory L = linesIndex[i];
            (win, value) = winLine([cards[L[0]], cards[L[1]], cards[L[2]], cards[L[3]], cards[L[4]]]);
            if (win >= 2) {
                linesOfWin[i] = (win * 1000 + value);
            }
            totalPayout += winLevels[value][win] * betPerLine;
        }
        return (totalPayout, cards, linesOfWin);
    }
    function winLine(uint256[5] memory cards) public pure returns (uint256 win, uint256 value) {
        win = 0;
        value = 0;
        for (uint256 i = cards.length - 1; i >= 0; i--) {
            if (cards[i] != 0) {
                value = cards[i];
            }
            if (i == 0) {
                break;
            }
        }
        if (
            (cards[0] == 0 || cards[0] == value) &&
            (cards[1] == 0 || cards[1] == value)
        ) {
            if (value == 0 || value == 9 || value == 10 || value == 11) {
                win = 2;
            }
            if (cards[2] == 0 || cards[2] == value) {
                win = 3;
                if ((cards[3] == 0 || cards[3] == value)) {
                    win = 4;
                    if ((cards[4] == 0 || cards[4] == value)) {
                        win = 5;
                    }
                }
            }
        }
    }
}