/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity >=0.4.0 <0.9.0;

contract messageBoard {

    int public num = 129;
    string public message1;
    string public message2;
    int public people = 0;
    
    function set1(string memory initMessage) public {
        message1 = initMessage;
    }
    
    function set2(string memory _editMessage) public{
        message2 = _editMessage;
    }
    function get1() public view returns(string memory){ 
    return message1;
    }
    
    function pay() public payable{
        people++;
    }
}