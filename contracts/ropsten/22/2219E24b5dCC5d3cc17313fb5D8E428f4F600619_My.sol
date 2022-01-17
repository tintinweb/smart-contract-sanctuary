pragma solidity 0.8.6;


contract Ownable {
    event O();
    constructor () {
        emit O();
    }
}


contract My is Ownable {
    event M();
    constructor () Ownable() {
        emit M();
    }
}