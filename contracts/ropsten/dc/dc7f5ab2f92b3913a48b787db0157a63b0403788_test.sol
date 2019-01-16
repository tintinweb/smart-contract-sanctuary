pragma solidity ^0.4.25;
contract test {
    uint private val;

    constructor()
    public {
        val = 0;
    }

    function numIncrement() 
    external {
        val = val + 1;
    }

    function getNum()
    external
    view
    returns (uint) {
        return val;
    }

    function setNum(uint _val)
    external {
        val = _val;
    }
}