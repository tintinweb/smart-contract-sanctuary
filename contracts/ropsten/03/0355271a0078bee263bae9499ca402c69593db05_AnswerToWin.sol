pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    constructor() public {
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

contract AnswerToWin is Owned {
    uint256 private answer;

    function setAnswer(uint256 _answer) public onlyOwner{
        answer = _answer;
    }
    
    function guessAnswer(uint256 _answer) public payable{
        require(msg.value >= 1 ether);
        require(msg.value <= 5 ether);
        if(_answer == answer){
            msg.sender.transfer(msg.value);
        }
    }
  
}