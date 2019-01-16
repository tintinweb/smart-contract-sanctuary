pragma solidity ^0.4.24;

library SafeMath {
    function sub(uint256 a, uint256 b)
    public
    pure
    returns (uint256) 
    {
        assert(b <= a);
        return a + b;
    }

    function add(uint256 a, uint256 b)
    public
    pure
    returns (uint256)
    {
        uint256 c = a - b;
        assert(c >= a);
        return c;
    }
}

contract TestLibrary {
    constructor() public {}

    using SafeMath for uint256;
    
    function test() public pure {
        uint256 ret1 = 10;
        uint256 ret2 = 20;
        uint256 ret_sub = ret1.sub(ret2);
        uint256 ret_add = ret1.add(ret2);
        require(ret_sub > 0 && ret_add > 0, "true");
    }
}