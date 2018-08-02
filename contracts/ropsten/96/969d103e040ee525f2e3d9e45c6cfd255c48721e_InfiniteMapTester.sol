pragma solidity ^0.4.24;

contract InfiniteMap
{
    function get(uint _x, uint _y) public pure returns (uint);
}

contract InfiniteMapTester
{
    function get(uint _x, uint _y) public pure returns (uint)
    {
        InfiniteMap _map = InfiniteMap(0xCbc858eA15db592953D784a57ABf3b4caEae7196);
        
        return _map.get(_x, _y);
    }
}