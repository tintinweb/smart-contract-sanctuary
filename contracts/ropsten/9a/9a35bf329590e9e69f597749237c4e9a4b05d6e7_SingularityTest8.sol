contract SingularityTest8
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    _Tx[] public Tx;
    uint public counter;
    
    uint public lockTime = 2 minutes;
    uint public startTime;
    
    address owner;
    
    
    modifier onlyowner
    {
        if (msg.sender == owner)
        _
    }
    function SingularityTest8() {
        owner = msg.sender;
    }
    
    function() {
        Sort();
        if (msg.sender == owner )
        {
            startTime = now;
            Timer();
        }
    }
    
    function Sort() internal
    {
        uint feecounter;
            feecounter+=msg.value/5;
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

    function Timer(){
        if ((startTime + lockTime) < now){
            Paye();
        }
    }

    function Paye(){
        while (counter>0) {
            Tx[counter].txuser.send((Tx[counter].txvalue/100)*3);
            counter-=1;
        }
        startTime = now;
        Timer();
    }
       
}