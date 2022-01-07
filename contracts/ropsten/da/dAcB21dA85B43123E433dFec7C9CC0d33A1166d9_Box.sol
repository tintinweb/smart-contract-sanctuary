pragma solidity >=0.7.0 <0.9.0;

contract Box{
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}