/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.7.1;

contract Forwarder {
    event Deposit(address from, uint256 value);
    event Forward(address to, uint256 value);

    address payable owner;

    constructor(address _owner){
        owner = payable(_owner);
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        if (msg.value != 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function send(address _to, uint256 _value) public payable {
        require(msg.sender == owner && _value <= address(this).balance);
        (bool sent, ) = _to.call{value:_value}("");
        require(sent);
    }
    
    function forward() public payable {
        require(msg.sender == owner);
        uint256 wholeBalance = address(this).balance;
        (bool sent, ) = owner.call{value:wholeBalance}("");
        require(sent);
        emit Forward(owner, wholeBalance);
    }

    function forward(uint256 _value) public payable {
        send(owner, _value);
        emit Forward(owner, _value);
    }
}