pragma solidity ^0.4.23;

contract PoormansHoneyPot {
    mapping (address => uint) public balances;

    constructor() public payable {
        store();
    }

    function store() public payable {
        balances[msg.sender] = msg.value;
    }

    function withdraw() public{
        assert (msg.sender.call.value(balances[msg.sender])()) ;
        balances[msg.sender] = 0;
    }


}