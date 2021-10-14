/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract EtherCasino {
    address admin;
    uint256 session;
    uint256 gameId = 0;

    mapping(uint256 => Game) games;

    struct Game {
        uint256 id;
        string user;
        uint256 diceValue;
        uint256 amount;
        address player;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not an admin.");
        _;
    }

    modifier isGameTime() {
        require(
            block.timestamp < session - 300000,
            "Wait for next the next Game."
        );
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function setSession(uint256 _session) public payable {
        session = _session;
    }

    function getSession() public view returns (uint256) {
        return session;
    }

    function betGame(string memory _user, uint256 _diceValue)
        public
        payable
        isGameTime
    {
        games[gameId] = Game(gameId, _user, _diceValue, msg.value, msg.sender);
        gameId += 1;
    }
}