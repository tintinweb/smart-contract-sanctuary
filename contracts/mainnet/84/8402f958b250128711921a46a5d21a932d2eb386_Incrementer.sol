pragma solidity ^0.4.11;

contract Incrementer {

    event LogWinner(address winner, uint amount);
    
    uint c = 0;

    function ticket() payable {
        
        uint ethrebuts = msg.value;
        if (ethrebuts != 10) {
            throw;
        }
        c++;
        
        if (c==3) {
            LogWinner(msg.sender,this.balance);
            msg.sender.transfer(this.balance);
            c=0;
        }
    }
}