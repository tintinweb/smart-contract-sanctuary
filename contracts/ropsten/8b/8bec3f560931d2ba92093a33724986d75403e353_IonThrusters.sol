/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/// ropsten 0xabE4ccA39F2286180B2EC45B261c48fD5C7acb5E



// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;




interface StarBoundInterface {
    function burn(uint amount) external;
    function balanceOf(address account) external;
}

contract IonThrusters {
    
    StarBoundInterface StarBound =  StarBoundInterface( 0x66Da620acf11e034D5Cd183b2D9A9886A5DFd1A5 );
    
    
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