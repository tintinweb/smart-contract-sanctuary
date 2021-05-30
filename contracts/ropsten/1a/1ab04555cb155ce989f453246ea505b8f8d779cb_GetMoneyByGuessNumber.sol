/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// pragma solidity >=0.7.0 <0.9.0;
pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract GetMoneyByGuessNumber {
    uint256 public answer;
    uint public LeftRange = 0;
    uint public RightRange = 100;
    uint public respond;
    string private message = "來猜數字八";
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
    
    function uint2str(uint i) internal returns (string c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        c = string(bstr);
        return c;
    }
    
    function generate()  private{
        LeftRange = 0;
        RightRange = 100;
        answer = uint256(sha256(abi.encodePacked(block.timestamp))) % 100;
    }
    
    function Restart()  private{
        generate();
        state = State.Start;
    }
    // function showMessage() public view returns(string)
    
    function showMessage() public view returns(string[]){
        string[] memory message_arr = new string[](3);
        message_arr[0] = message;
        message_arr[1] = uint2str(LeftRange);
        message_arr[2] = uint2str(RightRange);
        
        return message_arr;
    }
    
    function guess(uint _respond) public Stage(State.Start) payable{
        //respond = msg.value/10**15;
        respond = _respond;
        // return msg.value;
        require(respond <= 100,"can not over 100");
        if(respond < answer && respond >= LeftRange){
            LeftRange = respond;
            message = "Wrong Answer";
        }
        if(respond > answer && respond <= RightRange){
            RightRange = respond;
            message = "Wrong Answer";
        }
        if(respond == answer){
            message = "You Win";
             winner(respond);
        }
    }
    
    function winner(uint256 _respond) private Stage(State.Start){
        msg.sender.transfer(address(this).balance);
        emit Winner(msg.sender,_respond);
        state = State.End;
        Restart();
    }
    
}