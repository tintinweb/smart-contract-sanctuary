pragma solidity ^0.4.20;

contract AccessList {
    event Added(address _user);
    event Removed(address _user);

    mapping(address => bool) public access;

    function isSet(address addr) external view returns(bool) {
        return access[addr];
    }

    function add() external {
        require(!access[msg.sender]);
        access[msg.sender] = true;
        emit Added(msg.sender);
    }

    function remove() external {
        require(access[msg.sender]);
        access[msg.sender] = false;
        emit Removed(msg.sender);
    }
}