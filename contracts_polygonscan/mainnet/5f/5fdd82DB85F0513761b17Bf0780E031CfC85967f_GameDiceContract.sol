/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

//0xD187a276fa5Dc445d64D7EE2247F56A6384EbF69
pragma solidity 0.4.26;

contract GameDiceContract {
    //v1: betSide, 1 = under, 2 = over
    //v2: betNumber

    uint256 public HOUSE_EDGE = 2;

    function verifyBet(uint256 v1, uint256 v2, uint256 v3, uint256 v4) public pure returns (bool) {
        if (!(v1 == 1 || v1 == 2)) return false;
        if (!(v1 == 1 ? v2 >= 1 && v2 <= 95 : v2 >= 4 && v2 <= 98)) return false;
        if (v3 != 0 || v4 != 0) return false;

        return true;
    }

    function payoutAmount(uint256 number, uint256 betAmount, uint256 v1, uint256 v2, uint256 v3, uint256 v4)
        public view returns (uint256) {
        uint256 randNumber = number % 100;
        if (v3 != 0 || v4 != 0) return 0;

        if ((v1 == 1 && randNumber < v2) || (v1 == 2 && v2 < randNumber)) {
            return betAmount * (100 - HOUSE_EDGE) / (v1 == 1 ? v2 : 99 - v2);
        }
        else {
            return 0;
        }
    }

    function result(uint256 number, uint256 betAmount, uint256 v1, uint256 v2)
        public view returns (
            uint256 payout, 
            uint256 houseEdge, 
            uint256 randNumber)
    {
        randNumber = number % 100;
        payout = payoutAmount(number, betAmount, v1, v2, 0, 0);
        houseEdge = HOUSE_EDGE;
    }
}