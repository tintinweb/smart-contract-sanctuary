pragma solidity ^0.4.24;

contract MultiSendEth {

    address public owner;

    event Send(uint256 amount, address indexed _receiver);

    constructor(address _owner) public payable {
            owner = _owner;
    }

    function multiSendEth(uint256 amount, address[] list) public returns (bool) {
        for (uint i = 0; i < list.length; i ++) {
            list[i].transfer(amount);
            emit Send(amount, list[i]);
        }
    }

    function() public payable {}
}