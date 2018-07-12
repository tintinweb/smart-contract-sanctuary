pragma solidity ^0.4.24;

contract ClientReceipt {
    event Deposit(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );
    mapping(address => uint256) deposits;

    function deposit(bytes32 _id) public payable {
        // Events are emitted using `emit`, followed by
        // the name of the event and the arguments
        // (if any) in parentheses. Any such invocation
        // (even deeply nested) can be detected from
        // the JavaScript API by filtering for `Deposit`.
        deposits[msg.sender] = msg.value;
        emit Deposit(msg.sender, _id, msg.value);
    }
    
    function withdraw() public {
        msg.sender.transfer(deposits[msg.sender]);
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}