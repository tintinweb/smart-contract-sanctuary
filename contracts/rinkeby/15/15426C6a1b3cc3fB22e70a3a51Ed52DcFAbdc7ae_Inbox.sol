/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity ^0.4.17;

contract Inbox {

    string public message;
    


    function Inbox(string initMessage) public {
        message = initMessage;
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }

    function doMath(int a, int b){
        
    }


}