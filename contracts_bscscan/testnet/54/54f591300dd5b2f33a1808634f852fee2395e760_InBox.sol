/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.4.17;

contract InBox{
        string public message;

        function InBox(string InitialMessage) public {
            message = InitialMessage;
        }

        function SetMessage(string newMessage) public returns (string) {
            message = newMessage;
            return message;
        }

}