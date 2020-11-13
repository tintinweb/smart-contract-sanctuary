pragma solidity ^0.4.17;


contract Lottery {

    address public manager;
    address public winner;

    address[] private players;

    modifier isNotManager() {
        require(msg.sender != manager);
        _;
    }

    modifier isManager() {
        require(msg.sender == manager);
        _;
    }

    modifier isNotInList() {
        for (uint i=0; i < players.length; i++) {
            require(msg.sender != players[0]);
        }
        _;
    }

    modifier validValue() {
        require(msg.value == .01 ether);
        _;
    }

    modifier isAnyPlayers() {
        require(players.length > 0);
        _;
    }

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public isNotManager isNotInList validValue payable {
        players.push(msg.sender);
    }

    function pickWinner() public isManager isAnyPlayers payable returns(address) {
        uint index = random();
        uint share = (this.balance) * 20 / 100;
        winner = players[index];

        players[index].transfer(this.balance - share); // and the winner get the whole rest of the money
        manager.transfer(share);

        players = new address[](0);

        return winner;
    }

    function entryPlayers() public view returns(address[]) {
        return players;
    }

    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, players)) % players.length;
    }



}