/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.1;

contract NewContract {
    
    enum State { Stop, Wait, Go }
    
    struct TrafLight{
        State state;
        bool Active;
    }
    
    address owner;
    TrafLight trafic_light;

    modifier onlyActive() {
        require(trafic_light.Active);
        _;
    }
    
    modifier onlyTimeRestrictions() {
        if (msg.sender == owner && block.timestamp >= 1637258820) {
            _;
        } else if (msg.sender == address(0x47C1C218f11077ef303591cb6B2056DC6ea3063F) && block.timestamp >= 1637259600) {
            _;
        } else if (block.timestamp >= 1637341200) {
            _;
        } else {
            revert("Failed to execute this function from you adress at this time");
        }
    }
    
    constructor() public {
        owner = msg.sender;
        trafic_light = TrafLight(State.Wait, true);
    }
    
    function getState() public view returns (State) {
       return trafic_light.state; 
    }
    
    function Enable() public onlyTimeRestrictions{
        trafic_light.Active = true;
    }
    
    function Disable() public onlyActive onlyTimeRestrictions {
        trafic_light.Active = false;
    }
    
    function Stop() public onlyActive onlyTimeRestrictions {
       trafic_light.state = State.Stop;
    }
    
    function Wait() public onlyActive onlyTimeRestrictions{
       trafic_light.state = State.Wait;
    }
    
    function Go() public onlyActive onlyTimeRestrictions {
       trafic_light.state = State.Go;
    }
    
}