pragma solidity ^0.4.16;

contract BatchTest {
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;


    function increment(address _address)  {
      balanceOf[_address] += 1;
    }
    
    function incrementBatch(address[] _addresses) {
        uint arrayLength = _addresses.length;
        for (uint i=0; i<arrayLength; i++) {
           balanceOf[_addresses[i]] += 1;
        }
    }
}