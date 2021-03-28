/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.5.16;

contract Blink {
    uint public myData;

    event blinkEvent(uint data);

    function getData() view  public returns (uint retData) {
        return myData;
    }

    function setData(uint theData) public{
        myData=theData;
        emit blinkEvent(myData);
    }

}