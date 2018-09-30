pragma solidity ^0.4.24;

contract Test {
    
    uint256 public total;
   
    function set(uint _total) public {
        total = _total;
    }
    
    function get() public view returns (uint256) {
        return total;
    }
    
}