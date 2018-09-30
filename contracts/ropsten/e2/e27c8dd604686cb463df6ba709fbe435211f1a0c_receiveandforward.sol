pragma solidity ^0.4.24;
interface HourglassInterface  {
    function() payable external;
}
contract receiveandforward{
    HourglassInterface constant SPASMcontract_ = HourglassInterface(0xdc827558062AA1cc0e2AB28146DA9eeAC38A06D1);
    function () external payable{} // needed to receive p3d divs
    function forward() public{
        address SPASM = 0xdc827558062AA1cc0e2AB28146DA9eeAC38A06D1;
        SPASM.transfer(address(this).balance);
    }
    
}