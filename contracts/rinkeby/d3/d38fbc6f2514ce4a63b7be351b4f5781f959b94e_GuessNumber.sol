/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.25;
//以finney為單位， 1 finney == 0.001 ether，猜的數字要等同於支付的價格，也就是說猜80就得支付80finney == 0.08 ether
contract GuessNumber {
    uint256 answer;
    uint256 public LeftRange;
    uint256 public RightRange;
    event Winner(address indexed _winner, uint256 _answer);
    
    enum State{
        Start,
        End
    }
    State state;
    modifier Stage(State _state){
        require(state == _state);
        _;
    }
    
    constructor() public {
        generate();
    }
    
    function generate()  private{
        answer = uint256(sha256(abi.encodePacked(block.timestamp))) % 100;
    }
    
    function guess() public Stage(State.Start) payable{
        uint respond = msg.value/10**15;
        require(respond <= 100,"不能超過100");
        if(respond < answer && respond >= LeftRange){
            LeftRange = respond;
        }
        if(respond > answer){
            RightRange = respond;
        }
        if(respond == answer){
             winner(respond);
        }
    }
    
    function winner(uint256 _respond) private Stage(State.Start){
        msg.sender.transfer(address(this).balance);
        emit Winner(msg.sender,_respond);
        state = State.End;
    }
    
}