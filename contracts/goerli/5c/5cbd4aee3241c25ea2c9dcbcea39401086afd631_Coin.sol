/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

contract Coin{
    
    
    address public owner;
    mapping(address => uint) public balances;
    uint private INITIAL_SUPPLY = 10000;
    
    event Sent(address from,address to,uint amount);
    
    constructor(){
        owner = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    function sendIco(address receiver,uint amount) public {
        require(amount <= balances[msg.sender],"Insufficient balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender,receiver,amount);
    }
    
     function sendIcos(address[] memory receiver,uint[] memory amount) public {
         require(uint(receiver.length)  > 0,"null address");
         for(uint i = 0;i < uint(receiver.length); i++){
             require(amount[i] <= balances[msg.sender],"amount is error");
             balances[msg.sender] -= amount[i];
             balances[receiver[i]] += amount[i];
             emit Sent(msg.sender,receiver[i],amount[i]);
         }
    }
 

}