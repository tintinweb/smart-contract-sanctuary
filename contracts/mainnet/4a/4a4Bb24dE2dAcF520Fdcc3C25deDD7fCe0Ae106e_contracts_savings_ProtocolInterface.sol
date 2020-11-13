pragma solidity ^0.6.0;

abstract contract ProtocolInterface {
    function deposit(address _user, uint256 _amount) public virtual;

    function withdraw(address _user, uint256 _amount) public virtual;
}
