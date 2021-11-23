/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.5.1;

contract traffic_light {
    enum State {Red, Green, Yellow}
    string light;
    State state;

    constructor() public {
        state = State.Red;
    }

    function activateRed() public {
        state = State.Red;
       light = "Red light";
    }

    function activateYellow() public {
        state = State.Yellow;
        light = "Yellow light";
    }

    function activateGreen() public {
        state = State.Green;
        light = "Green light";
    }

    function whichLight() public view returns(string memory) {
        return light;
    }
}