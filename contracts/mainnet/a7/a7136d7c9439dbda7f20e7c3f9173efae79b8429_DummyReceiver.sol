pragma solidity >=0.4.10;

// Dummy Receiver to satisfy Sales contract need for 3 receivers
contract DummyReceiver {

    // callback from sale contract when the sale begins
    function start() {
    }

    // callback from sale contract when sale ends
    function end() {
    }
}