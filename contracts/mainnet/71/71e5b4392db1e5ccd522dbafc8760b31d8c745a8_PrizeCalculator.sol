pragma solidity ^0.4.25;

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)
        pure
        external
        returns (uint);
}

contract PrizeCalculator is IPrizeCalculator {
    using SafeMath for uint;
     
    function calculatePrizeAmount(uint _distributeTotalTokens, uint _collectedTotalTokens, uint _contributionTokens)        
        public
        pure
        returns (uint)
    {
        require (_distributeTotalTokens > 0, "Not valid 1 param");
        require (_collectedTotalTokens > 0, "Not valid 2 param");
        require (_contributionTokens > 0, "Not valid  3 param");
        
        uint returnValue = 0;
        
        returnValue = _contributionTokens.mul(_distributeTotalTokens).div(_collectedTotalTokens);
        
        return returnValue;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}