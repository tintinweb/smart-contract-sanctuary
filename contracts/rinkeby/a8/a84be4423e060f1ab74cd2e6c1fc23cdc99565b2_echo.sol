/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.5.1;

contract echo {

    string str;
    event report(string _s, address _addr);

    constructor() public {
        str="echo.sol";
    }

    function get() public view returns (string memory) {
        return str;
    }

    function set(string memory  _s) public {
        str =  _s;
        emit report(_s,msg.sender);
    }
}