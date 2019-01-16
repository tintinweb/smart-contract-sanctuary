pragma solidity ^0.4.25;
contract Owned {
    address public owner;
    constructor() public payable{
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

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

contract AnswerToWin is Owned,HackingLabTools {
    uint256 private answer;

    function setAnswer(uint256 _answer) public onlyOwner{
        answer = _answer;
    }
    
    function guessAnswer(bytes32 _user_answer) public constant returns (bool){
        require(msg.value <= 5000000000 wei);
        return answerCompare(answer,_user_answer);
    }
    function transfer(address _to, uint256 _value) public  onlyOwner{
        _to.transfer(_value);
    }
    
  
}