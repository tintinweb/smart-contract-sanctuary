/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;




interface StarBoundInterface {
    function burn(uint amount) external;
    function balanceOf(address account) external;
}

contract IonThrusters {
    
    StarBoundInterface StarBound =  StarBoundInterface( 0x0de6aD1AE91c3df9aB3B883D860beF3DAF6F7f58 );
    
    
    address public throttleController;
    
    constructor () {
        throttleController = msg.sender;
    }
    
    modifier onlyThrottleController {
        require(msg.sender == throttleController);
        _;
    }
    
    event AfterBurnersEngaged(address, address,  uint);
    
    function IonThrustersResult() public pure returns(string memory) {
        return "The StarBound in this contract can only be burned! Engaging Ion Thrusters will consume StarBound by decreasing total supply.";
    }
    
    function engageIonThrusters(uint amount ) public onlyThrottleController {
        StarBound.burn(amount);
    }
    
}