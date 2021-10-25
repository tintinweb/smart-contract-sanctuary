/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;
    uint256 public currentRound;
    mapping(address => mapping(uint256 => bool)) public activeInLottery;

    function Lottery() public {
        manager = msg.sender;
        currentRound = 1;
    }
    
    function enter() public  payable {
        // user can only enter once per round
        require(activeInLottery[msg.sender][currentRound] != true);

        // manage can not enter
        require(msg.sender != manager);

        // .01 ether = 1000000000000000000 wei
        require(msg.value > .01 ether);
        players.push(msg.sender);
        activeInLottery[msg.sender][currentRound] = true;
    }
    
    function pseudoRandom() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = pseudoRandom() % players.length;
        players[index].transfer(this.balance);
        lastWinner = players[index];
        players = new address[](0);
        currentRound ++;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}