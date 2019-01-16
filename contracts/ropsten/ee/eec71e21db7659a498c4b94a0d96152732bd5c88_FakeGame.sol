contract HackingLabTools{
    //Welcome To HackingLab.cn
    //TXkgV2VjaGF0IGlzIENwbHVzSHVhLCBubyBuZWVkIHRvIGhlc2l0YXRlLCBhZGQgbWUgbm93IQ==
    function answerCompare(uint256 _answer, bytes32 _user_answer) public constant returns (bool){
        bytes32 system_answer = keccak256(keccak256(_answer), abi.encodePacked(msg.sender));
        if(system_answer == _user_answer){
            return true;
        }
        return false;
    }
    function getAddressAnswerKeccak256(uint256 _answer)public constant returns (bytes32){
        bytes32 system_answer = keccak256(keccak256(_answer), abi.encodePacked(msg.sender));
        return system_answer;
    }
}
contract FakeGame is HackingLabTools{
    uint256 luckyNum = 888;
    uint256 public last;
    struct Game {
        address player;
        bytes32 number;
    }
    Game[] public gameHistory;
    address owner = msg.sender;
    function guess(bytes32 _user_answer) public payable returns (bool){
        Game game;
        game.player = msg.sender;
        game.number = _user_answer;
        gameHistory.push(game);
        if(answerCompare(luckyNum, _user_answer)){
            msg.sender.transfer(100 wei);
        }
        return answerCompare(luckyNum, _user_answer);
        last = now;
    }
    constructor() public payable{
        //do nothing
        //good luck to Hackinglab users!
    }
}