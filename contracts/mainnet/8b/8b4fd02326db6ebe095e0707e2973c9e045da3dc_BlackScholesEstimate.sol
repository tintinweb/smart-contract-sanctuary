/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

// https://github.com/RyanHendricks/Black-Scholes-Solidity

pragma solidity ^0.6.12;


contract BlackScholesEstimate {
    
    /**
     * @dev sqrt calculates the square root of a given number x
     * @dev for precision into decimals the number must first
     * @dev be multiplied by the precision factor desired
     * @param x uint256 number for the calculation of square root
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 c = (x + 1) / 2;
        uint256 b = x;
        while (c < b) {
            b = c;
            c = (x / c + c) / 2;
        }
        return b;
    }
    
    /**
     * @dev stddev calculates the standard deviation for an array of integers
     * @dev precision is the same as sqrt above meaning for higher precision
     * @dev the decimal place must be moved prior to passing the params
     * @param numbers uint[] array of numbers to be used in calculation
     */
    function stddev(uint[] memory numbers) public pure returns (uint256 sd) {
        uint sum = 0;
        for(uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        uint256 mean = sum / numbers.length;        // Integral value; float not supported in Solidity
        sum = 0;
        uint i;
        for(i = 0; i < numbers.length; i++) {
            sum += (numbers[i] - mean) ** 2;
        }
        sd = sqrt(sum / (numbers.length - 1));      //Integral value; float not supported in Solidity
        return sd;
    }
    
    
    /**
     * @dev blackScholesEstimate calculates a rough price estimate for an ATM option
     * @dev input parameters should be transformed prior to being passed to the function
     * @dev so as to remove decimal places otherwise results will be far less accurate
     * @param _vol uint256 volatility of the underlying converted to remove decimals
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function blackScholesEstimate(
        uint256 _vol,
        uint256 _underlying,
        uint256 _time
    ) public pure returns (uint256 estimate) {
        estimate = 40 * _vol * _underlying * sqrt(_time);
        return estimate;
    }
    
    /**
     * @dev fromReturnsBSestimate first calculates the stddev of an array of price returns
     * @dev then uses that as the volatility param for the blackScholesEstimate
     * @param _numbers uint256[] array of price returns for volatility calculation
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function retBasedBlackScholesEstimate(
        uint256[] memory _numbers,
        uint256 _underlying,
        uint256 _time
    ) public pure {
        uint _vol = stddev(_numbers);
        blackScholesEstimate(_vol, _underlying, _time);
    }

}