/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity 0.8.6;

contract passfail {
    string public result;

    function enterMarks(uint256 _marks) public returns (string memory) {
        if(( _marks >= 60) && ( _marks <= 100) ) {
            result = "pass with A grade";
            return result;
            
        } else if (( _marks >= 50) && ( _marks < 60) ) {
            result = "pass with B grade";
            return result;
            
        } else if (( _marks >= 33) && ( _marks < 50) ) {
            result = "pass with C grade";
            return result;
            
        } else {
            result = "try again";
            return result;
        }
    }
}