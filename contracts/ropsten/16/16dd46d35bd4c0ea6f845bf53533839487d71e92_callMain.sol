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
    
    CallAntherInter callAnther = CallAntherInter(conAddr);
    function start1()public view returns(uint){
        return callAnther.readData();
    }
    function start2()public returns(uint) {
        callAnther.changeData(50);
        return callAnther.readData();
    }
    function start3()public view returns(address,address){
       return  (callAnther.findMsg(),msg.sender);
    }
}