pragma solidity ^0.4.18;

contract SNOVToken {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract MultiTransfer {
    address public owner;

    function MultiTransfer() public {
        owner = msg.sender;
    }

    function MultiTransaction(address _tokenAddress, address[] _addresses, uint256[] _values) public {
        require(msg.sender == owner);
        SNOVToken token = SNOVToken(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], _values[i]);
        }
    }
}