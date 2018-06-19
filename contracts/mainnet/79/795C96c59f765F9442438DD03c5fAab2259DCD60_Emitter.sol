pragma solidity >=0.4.13;

contract Emitter {
    event Emit(uint x);
    function emit(uint x) {
        Emit(x);
    }
}

contract Caller {
    address emitter;
    function setEmitter(address e) {
        if (emitter == 0x0) {
            emitter = e;
        }
    }
    function callEmitter(uint x) {
        Emitter(emitter).emit(x);
    }
}