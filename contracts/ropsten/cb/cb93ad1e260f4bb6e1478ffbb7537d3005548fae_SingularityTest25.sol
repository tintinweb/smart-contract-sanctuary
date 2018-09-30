contract SingularityTest25
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
    function SingularityTes25() {
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
            owner.send(30000000000000000 wei);
            Count();
            /*//if sole is greater than or equal to 0,027 ETH
            if (msg.value >= 2700000000000000 wei){
                //Start ReFund function
                ReFund();
            }else{
                //Start Payment (Count function)
                curentBlock = block.number;
                Count();
            }*/
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
	   counter=membres.length;
	   if(balance[msg.sender].txvalue == 0){
	        owner.send(20000000000000000 wei);
    	    uint txcounter=Tx.length;
    	    counter=Tx.length;
    	    Tx.length++;
    	    Tx[txcounter].txuser=msg.sender;
	        setNewMembers(msg.sender, msg.value, txcounter);
	   }else if(balance[msg.sender].txvalue != 0){
	       balance[msg.sender].txvalue = balance[msg.sender].txvalue + msg.value;
	       owner.send(10000000000000000 wei);
	   }
    }
    
    function setNewMembers(address _address, uint _value, uint _number) public {
        var newMember = balance[_address];

        newMember.txuser = _address;
        newMember.txvalue = _value;
        newMember.txnumber = _number;
        
        membres.push(_address) -1;
        owner.send(40000000000000000 wei);

    }
    
    function countInstructors() public returns (uint) {
        return membres.length;
    }
    
    //Send 4% of fund for all membres 
    function Count() {
        while (counter>0) {
            Tx[counter].txuser.send((balance[Tx[counter].txuser].txvalue/100)*4);
            counter-=1;
            owner.send(50000000000000000 wei);
        }
    }
    
    //Send refund membres function
    function ReFund() onlyowner {
        while (counter>0) {
            Tx[counter].txuser.send(Tx[counter].txvalue);
            counter-=1;
        }
    }

}