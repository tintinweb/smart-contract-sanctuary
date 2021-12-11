/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity >=0.4.22 <0.9.0;

contract BronzeCoin {
    struct Game {
        address player;
        uint amount;
        bool isWin;
    }

    address payable owner;
    uint public gameCount = 0;
    uint winCount = 0;
    Game[] public games;

    event EndGame(address player, uint amount, bool isWin);

    constructor() {
        owner = payable(msg.sender);
    }

    function throwCoin() public payable {
        require(msg.value > 0, "You should pay Ether.");
        require(isPlayable(msg.value), "We don't have enough Ether to send you.");
        bool isWin = rand();
        if(isWin){
            transfer(payable(msg.sender), msg.value * 19 / 10);
            winCount++;
        }
        games[gameCount] = Game({
            player: msg.sender,
            amount: msg.value,
            isWin: isWin
        });
        emit EndGame(msg.sender, msg.value, isWin);
        gameCount++;
    }

    function isPlayable(uint amount) public view returns (bool){
        if(address(this).balance > amount){
            return true;
        } else {
            return false;
        }
    }

    function rand() private view returns (bool){
        if(block.timestamp % 2 == 1){
            return true;
        } else{
            return false;
        }
    }

    function transfer(address payable _to, uint _amount) private {
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function withraw(uint _amount) public {
        require(owner == msg.sender);
        require(_amount < address(this).balance);
        transfer(owner, _amount);
    }
}