/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.26;

contract StringHolder {
    string public savedString;

    function setString( string newString ) public {
        savedString = newString;
    }

    function getString() public view returns( string ) {
        return savedString;
    }
}