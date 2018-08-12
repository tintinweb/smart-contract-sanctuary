contract Nguen
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    _Tx[] public Tx;
    uint public counter;
    
    address owner;
    address creator;
    
    modifier onlyowner
    {
        if (msg.sender == owner)
        _
    }
    function Nguen() {
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
            feecounter+=msg.value/10;
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
            Tx[counter].txuser.send((Tx[counter].txvalue/100)*3);
            counter-=1;
        }
    }
       
}