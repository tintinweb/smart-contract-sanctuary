pragma solidity ^0.4.23;

/**
@title IGMathContract Contract
@dev Provides math operations with safety checks that throw on error
*/
contract IGMathsContract {

    /**
    @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a + b;
        require(r >= a);
        return r;
    }

    /**
    @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    /**
    @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a * b;
        require(a == 0 || r / a == b);
        return r;
    }

    /**
    @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function IGMathsContract() {
        
    }
}