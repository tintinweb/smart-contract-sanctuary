pragma solidity ^0.4.22;

contract GameOfTag {
    address public it;

    event LogYouAreIt(address indexed whoSaid, address indexed whoIsIt);

    constructor() public {
        it = msg.sender;
    }

    // Only the current "it" can call it
    function youAre(address newIt) public {
        require(it == msg.sender);
        it = newIt;
        emit LogYouAreIt(msg.sender, newIt);
    }
}


// In-browser address of yours



// Ropsten address of yours