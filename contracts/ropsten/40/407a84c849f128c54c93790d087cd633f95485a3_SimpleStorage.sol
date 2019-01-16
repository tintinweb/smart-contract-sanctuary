pragma solidity >=0.4.0 <0.6.0;

contract SimpleStorage {
    uint storedData;
    event Set(address indexed _from, uint value);
    
    function set(uint x) public {
        storedData = x;
        emit Set(msg.sender, x);
    }

    function get() public view returns (uint) {
        return storedData;
    }
}