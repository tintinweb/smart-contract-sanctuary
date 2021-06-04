/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity >=0.4.22 <0.6.0;
contract DripLike {
     function dripReservoir() external;
     function dripDev() external;
     function dripUser() external;
     function dripBackstop() external;

}


contract Dripper {
    DripLike constant dripper = DripLike(0x20fe0eadbAfCA5458E129Bb3cCA303776165b371);
    function drip() external {
        dripper.dripUser();
        dripPartial();
    }
    
    function dripPartial() public {
        dripper.dripReservoir();
        dripper.dripDev();
        dripper.dripBackstop();        
    }
}