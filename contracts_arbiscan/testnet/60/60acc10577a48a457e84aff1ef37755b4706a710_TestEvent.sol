/**
 *Submitted for verification at arbiscan.io on 2021-12-04
*/

pragma solidity ^0.8.0;

contract TestEvent {
    struct Info {
        string name;
    }
    event Event1(Info _info);

    function emitTest() external {
        Info memory info = Info({name: "sdf"});
        emit Event1(info);
    }
}