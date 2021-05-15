/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.8;

abstract contract Deployed {
    
    function a() virtual public;
}

contract checkmsg {
    
    Deployed dt;
    address dtaddress = 0x0Edc266d9A771Cf241BBE880782fCfe4c021Baaa;
    function trycall() public {
    dt = Deployed(dtaddress);    
    dt.a();
    }
    
    
}