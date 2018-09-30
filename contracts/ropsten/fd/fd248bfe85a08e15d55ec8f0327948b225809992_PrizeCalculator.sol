pragma solidity ^0.4.13;

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)
        pure
        external
        returns (uint);
}

contract PrizeCalculator is IPrizeCalculator {
    using SafeMath for uint;
     
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)        
        public
        pure
        returns (uint)
        {
            require (_predictionTotalTokens > 0, "Not valid prediction tokens");
            require (_winOutputTotalTokens > 0, "Not valid output tokens");
            require (_forecastTokens > 0, "Not valid forecast tokens");
            
            uint returnValue = 0;
            
            returnValue = _forecastTokens.mul(_predictionTotalTokens).div(_winOutputTotalTokens);
           
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