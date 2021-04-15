/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract messageBoard {
    string public message;
    int public persons = 0;
    constructor(string memory initMessage) public{
        message = initMessage;
    }
    function editMessage(string memory _editMessage) public{
        message = _editMessage;
    }
    function showMessage() public view returns(string memory){
        return message;
    }
    function pay() public payable{
        persons = persons + 1;
    }
}