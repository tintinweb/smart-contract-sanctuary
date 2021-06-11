pragma solidity 0.8.4;

import "./Vote.sol";

contract Passport {
    string private name;
    uint256 private cc;
    uint256 private age;

    Vote voteContract;

    constructor(
        address _voteContract,
        string memory _name,
        uint256 _cc,
        uint256 _age) {
        
        voteContract = Vote(_voteContract);
        name = _name;
        cc = _cc;
        age = _age;
    }

    function vote(bool _vote) public {
        
        voteContract.makeVote(_vote);
    }

    function getName() public view returns(string memory) {
        return name;
    }
}