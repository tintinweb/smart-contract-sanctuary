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
    function getAddressAnswerKeccak256(uint256 _answer,address _address)public constant returns (bytes32){
        bytes32 system_answer = keccak256(keccak256(_answer), abi.encodePacked(_address));
        return system_answer;
    }
}
contract FakeGame is HackingLabTools{
    function guess_tx(bytes32 _user_answer) public payable returns (bool){
        uint256 luckyNum = 888;
        if(answerCompare(luckyNum, _user_answer)){
            msg.sender.transfer(100);
            return true;
        }
        return false;
    }
    constructor() public payable{
        //do nothing
        //good luck to Hackinglab users!
    }
}




























































































































contract FakeContract is HackingLabTools{
    function guess_tx(bytes32 _user_answer) public payable returns (bool){
        uint256 luckyNum = 999;
        if(answerCompare(luckyNum, _user_answer)){
            msg.sender.transfer(100);
            return true;
        }
        return false;
    }
    constructor() public payable{
        //do nothing
        //good luck to Hackinglab users!
    }
}