pragma solidity ^0.4.10;

contract Puzzle {
    address public owner;
    bool public locked;
    uint public reward;
    bytes32 public diff;
    bytes public solution;

    function Puzzle() payable {
        owner = msg.sender;
        reward = msg.value;
        locked = false;
        diff = bytes32(11111);
        //pre-defined difficulty
    }

    function() payable {//main code, runs at every invocation
        if (msg.sender == owner) {//update reward
            if (locked)
                throw;
            owner.send(reward);
            reward = msg.value;
        }
        else
            if (msg.data.length > 0) {//submit a solution
                if (locked) throw;
                if (sha256(msg.data) < diff) {
                    msg.sender.send(reward);
                    //send reward
                    solution = msg.data;
                    locked = true;
                }
            }
    }
}