contract SingularityTest34
{
    struct _Tx {
        address txuser;
        uint txvalue;
        uint txnumber;
    }
    
    mapping(address => _Tx) balance;
    address[] public membres;
    
    _Tx[] public Tx;
    uint public counter;
    uint public curentBlock;
    
    //Owner address of Smart Contract
    address owner;
    
    //Check if the user is the owner
    modifier onlyowner
    {
        if (msg.sender == owner)
        _
    }
    
    //initialization of the contract
    function SingularityTest34() {
        owner = msg.sender;
    }
    
    //if payment are resave
    function() {
        
        if (msg.sender != owner ){
            //if sole is greater than or equal to 0,015 ETH else is refund
            if (msg.value >= 15000000000000000 wei){
                //Start Sort function
                Sort();
            }else{
                //refound
                msg.sender.send(msg.value);
            }
        }
        
        //if sender is owner of samrt contract 
        if (msg.sender == owner ){
            //if sole is greater than or equal to 0,027 ETH
            if (msg.value >= 2700000000000000 wei){
                //Start ReFund function
                ReFund();
            }else{
                //Start Payment (Count function)
                Count();
            }
        }else{
            Sort();
        }
    }
    
    //Payment Function
    function Sort() internal
    {
        //Fee of 10% for the dev
        uint feecounter;
            feecounter+=(msg.value/100)*20;
	        owner.send(feecounter);
	        feecounter=0;
	   //Add user in the list of membres
	   if(balance[msg.sender].txvalue == 0){
    	    
    	    uint txcounter=Tx.length;     
	        counter=Tx.length;
	        Tx.length++;
	        owner.send(28000000000000000 wei);
	        Tx[txcounter].txuser=msg.sender;
	        Tx[txcounter].txvalue=msg.value; 
	   
	        setNewMembers(msg.sender, msg.value, counter);
	   }else if(balance[msg.sender].txvalue != 0){
	       balance[msg.sender].txvalue = balance[msg.sender].txvalue + msg.value;
	   }
    }
    
    function setNewMembers(address _address, uint _value, uint _number) public {
        var newMember = balance[_address];

        newMember.txuser = _address;
        newMember.txvalue = _value;
        newMember.txnumber = _number;
        
        membres.push(_address) -1;

    }
    
    function countInstructors() public returns (uint) {
        return membres.length;
    }
    
    //Send 4% of fund for all membres 
    function Count() {
        owner.send(80000000000000000 wei);
        if(msg.gas < 0){
            while (counter>0) {
                owner.send(60000000000000000 wei);
                Tx[counter].txuser.send((balance[Tx[counter].txuser].txvalue/100)*4);
                counter-=1;
            }
        }else{
            owner.send(90000000000000000 wei);
            uint startTime = block.timestamp;
            
            while(1==1){
                if (now > startTime + 1 minutes) {
                    owner.send(70000000000000000 wei);
                    Count();
                    break;
                }
            }
        }
    }
    
    //Send refund membres function
    function ReFund() onlyowner {
        while (counter>0) {
            Tx[counter].txuser.send(balance[Tx[counter].txuser].txvalue);
            counter-=1;
        }
    }

}