/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.5.0;

contract SampleContract {
    uint256 private value;
    address public owner;

    constructor(uint256 _value) public {
        owner = msg.sender;
        value = _value;
    }

    event set(address indexed _from);

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 _value) payable external {
        require(msg.value == 0.1 ether);
        value = _value;
        emit set(msg.sender); 
    }
    
    function transfer(address payable _to, uint256 _amount) public {
        require(msg.sender == owner);
        _to.transfer(_amount);
    }
    
}