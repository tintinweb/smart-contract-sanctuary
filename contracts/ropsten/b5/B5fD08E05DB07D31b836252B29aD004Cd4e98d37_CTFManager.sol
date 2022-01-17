/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

pragma solidity ^0.4.21;

interface LotteryChallenge {
    function isComplete() external view returns (bool);
}

contract CTFManager {

    // Define challenge struct
    struct Challenge {
        address addr;
        bool solved;
    }

    // Define user struct
    struct User { 
        string username;
        mapping (uint8 => Challenge) challenges;
    }

    // Users object
    mapping(address => User) ctfUsers;

    // Define variable owner of the type address
    address owner;

    // This function is executed at initialization and sets the owner of the contract
    constructor() public {
        owner = msg.sender; 
    }

    // Creates or update a user.
    function createUser(string username) public {
        ctfUsers[msg.sender].username = username;
    }

    // Get Username
    function getUsername() public view returns (string) {
        return ctfUsers[msg.sender].username;
    }

    // Add challenge to user
    function addChallenge(uint8 challengeId, address challengeAddr) public {
        ctfUsers[msg.sender].challenges[challengeId] = Challenge({addr:challengeAddr, solved:false});
    }

    // Remove challenge from user
    function removeChallenge(uint8 challengeId) public {
        delete(ctfUsers[msg.sender].challenges[challengeId]);
    }

    // Fetch Challenge n from user
    function getChallenge(uint8 challengeId) public view returns (address, bool) {
        return (
            ctfUsers[msg.sender].challenges[challengeId].addr,
            ctfUsers[msg.sender].challenges[challengeId].solved
        );
    }

    // Check Challenge Solution
    function checkChallenge(uint8 challengeId) public {
        ctfUsers[msg.sender].challenges[challengeId].solved = LotteryChallenge(ctfUsers[msg.sender].challenges[challengeId].addr).isComplete();
    }
    
}