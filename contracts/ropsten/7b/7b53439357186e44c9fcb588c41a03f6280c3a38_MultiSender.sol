pragma solidity ^0.4.24;


contract MultiSender {
    string public constant name = &quot;MultiSender&quot;;
    
    function() public payable {
        // validation
    }
    
    function send(address[] _addresses, uint256[] _values) external {
        for (uint i=0; i<_addresses.length; i++) {
            _addresses[i].transfer(_values[i]);
        }
    }
}