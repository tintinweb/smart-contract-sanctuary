pragma solidity 0.4.24;

contract ProofOfLove {
    
    uint public count = 0;

    event Love(string name1, string name2);

    constructor() public { }

    function prove(string name1, string name2) external {
        count += 1;
        emit Love(name1, name2);
    }

}