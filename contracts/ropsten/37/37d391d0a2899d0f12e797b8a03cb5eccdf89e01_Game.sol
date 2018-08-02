pragma solidity ^0.4.24;

contract Game {

    uint public position;
    struct gamer{
        address player;
        uint256 value;
    }
    gamer[] public line;

    function payin() public payable{
        uint256 money = msg.value;
        gamer memory temp = gamer(msg.sender,money);
        line.push(temp);
        while(money>0){
            if(position==line.length){
                msg.sender.send(address(this).balance);
                return;
            }
            else if(money>=line[position].value*2){
                money-=line[position].value*2;
                line[position].player.send(line[position].value*2);
                position++;
            }
            else{
                line[position].value-=money/2;
                line[position].player.send(money);
                money=0;
            }
        }

    }
}