/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;




interface StarBoundInterface {
    function burn(uint amount) external;
    function balanceOf(address account) external;
}

contract IonThrusters {
    
    StarBoundInterface StarBound =  StarBoundInterface( 0x801EA8C463a776E85344C565e355137b5c3324CD );
    
    
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