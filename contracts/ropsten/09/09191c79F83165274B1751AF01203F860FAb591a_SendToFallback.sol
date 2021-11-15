pragma solidity ^0.7.0;

contract Recipient {
    address payable owner;
    uint public interactions;
    event Received(address indexed from, uint value);
    
    constructor(address payable _owner) {
        owner = _owner;
    }

    receive() external payable {
        emit Received(tx.origin, msg.value); 
    }  
    
    fallback() external {
        interactions += 1;
    }
    
    function transferToOwner() public payable {
        owner.transfer(address(this).balance);
    } 
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract SendToFallback {
    function a()  external payable{}
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function dodo(Recipient recipient) external{
        (bool success,) = address(recipient).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
    }
    function callFallback(address payable _to) public {
        require(_to.send(10 wei),"smth wrong");
    }
}

