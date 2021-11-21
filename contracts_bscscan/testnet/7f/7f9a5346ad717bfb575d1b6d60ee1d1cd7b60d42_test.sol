/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity 0.8.10;

contract test{
    string public mess;

    constructor() public{
        mess = "Hello world !";
    }

    function getMessage() external view returns (string memory){
        return mess;
    }
}