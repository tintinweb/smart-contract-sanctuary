/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.4.22;

contract MoneyGame{
    event NewBet(address player, uint value);
    event Winner(address player);

    address public owner;
    address[] public players;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function Lottery() public {
        owner = msg.sender;
    }

    function enter() public payable{
        require(msg.value > .0001 ether);
        players.push(msg.sender);
        emit NewBet(msg.sender, msg.value);
    }

    function random() private view returns (uint){
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public ownerOnly{
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        emit Winner(players[index]);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
   
}