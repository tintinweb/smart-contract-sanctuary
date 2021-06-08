/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.8.0;

contract HelloWolrd{
    //string hello;
    string public hello; //tips pour éviter la function getHello
    
    function setHello(string memory _hello) external {
        hello = _hello;
    }
    
    /*function getHello() external view returns (string memory) {
        return hello;
    }*/
}