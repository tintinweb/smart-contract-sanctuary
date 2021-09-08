/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.4.23;
contract messageBoard {
    string public message;
    address public manager;
    
    function activity(address _manager) public {
        manager = _manager;
    }
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string editMessage) public payable{
        message = editMessage;
    }
    function viewMessage() public  returns(string) {
        return message;
    }
    function payAll () public {
        manager.transfer(this.balance); 
    }
}