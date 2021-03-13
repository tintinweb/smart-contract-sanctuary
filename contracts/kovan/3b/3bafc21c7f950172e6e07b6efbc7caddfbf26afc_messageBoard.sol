/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity >=0.4.22 <0.6.0;
contract messageBoard {

        string public message ;
        int public num = 123;
        function messageBoard(string initMassage) public {
            message = initMassage;
        }
        function editMessage(string _editMessage) public {
            message = _editMessage;
        }
}