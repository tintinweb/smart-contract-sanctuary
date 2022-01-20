/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.5.2;

contract Tile {

    enum State {Waiting, Active} State public state;

    constructor() public {
        state = State.Waiting;
    }

    function active() public {
        state = State.Active;
    }

    function isActive() public view returns(bool) {
        return state == State.Active;
    }

}