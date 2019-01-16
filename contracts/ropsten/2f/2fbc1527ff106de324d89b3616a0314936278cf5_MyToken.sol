pragma solidity ^0.4.23;

contract MyToken {
    event Paid(address, uint);

    function transfer(address _to, uint256 _value) public {
        emit Paid(_to, _value);
    }
}