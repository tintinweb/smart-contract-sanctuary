/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.4.17;

contract CallAntherInter{
    function readData()public view returns(uint);
    function changeData(uint data) public;
    function findMsg() public view returns(address);
}
contract callMain{
    address conAddr = 0x4074a347b8754A43F579eeA0BeaB06b6edB3e6a2;
    uint readDa;
    address msgsender;
    function start()public returns(uint,uint,address){
        CallAntherInter callAnther = CallAntherInter(conAddr);
        readDa = callAnther.readData();
        callAnther.changeData(50);
        msgsender = callAnther.findMsg();
        return (readDa,callAnther.readData(),msgsender);
    }
}