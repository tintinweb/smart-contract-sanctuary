pragma solidity ^0.5.17;

contract TestToken {
    string public name = "Test Token";
    string public symbol = "TT";
    uint256 public last = 18;

    function setLast(uint256 _last) public {
        last = _last;
    }

}