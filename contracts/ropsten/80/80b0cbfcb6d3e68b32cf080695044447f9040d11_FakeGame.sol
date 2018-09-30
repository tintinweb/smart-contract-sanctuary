contract FakeGame{
    uint256 luckyNum = 888;
    uint256 public last;
    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gameHistory;
    address owner = msg.sender;
    function guess(uint256 _number) public payable{
        Game game;
        game.player = msg.sender;
        game.number = _number;
        gameHistory.push(game);
        if(_number == luckyNum){
            msg.sender.transfer(msg.value * 2);
        }
        last = now;
    }
}