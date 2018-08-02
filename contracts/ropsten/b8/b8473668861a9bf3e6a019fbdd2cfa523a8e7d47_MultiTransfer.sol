pragma solidity ^0.4.18;

contract SNOVToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract MultiTransfer {
    function MultiTransaction(address _tokenAddress, address[] _addresses, uint256[] _values) public {
        SNOVToken token = SNOVToken(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _values[i]);
        }
    }
}