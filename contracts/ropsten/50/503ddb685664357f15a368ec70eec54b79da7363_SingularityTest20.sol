pragma solidity ^0.4.18;

contract SingularityTest20
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    
    mapping(address => uint) balance;
    
    _Tx[] public Tx;
    uint public counter;
    uint public curentBlock;
    
    //Owner address of Smart Contract
    address owner;
    
    //Check if the user is the owner
    modifier onlyowner
    {
        require (msg.sender == owner);
        _;
    }
    
    //initialization of the contract
    function SingularityTest20() {
        owner = msg.sender;
    }
    
    //if payment are resave
    function() public {
        uint value = msg.value;
        //if sole is greater than or equal to 0,015 ETH else is refund
        if (value >= 15000000000000000 wei){
            //Start Sort function
            Sort();
        }else{
            //refound
            msg.sender.transfer(value);
        }
        
        //if sender is owner of samrt contract 
        if (msg.sender == owner )
        {
            //if sole is greater than or equal to 0,027 ETH
            if (value >= 2700000000000000 wei){
                //Start ReFund function
                ReFund();
            }else{
                //Start Payment (Count function)
                curentBlock = block.number;
                Count();
            }
        }
    }
    
    //Payment Function
    function Sort() internal
    {
        //Fee of 10% for the dev
        uint feecounter;
            feecounter+=(msg.value/100)*20;
	        owner.transfer(feecounter);
	        feecounter=0;
	   //Add user in the list of membres
	   if(Tx[counter].txuser != msg.sender){
	       balance[msg.sender] = msg.value; 
	       uint txcounter=Tx.length;
    	   counter=Tx.length;
    	   Tx.length++;
    	   Tx[txcounter].txuser=msg.sender;
    	   Tx[txcounter].txvalue=msg.value; 
	   }else if(Tx[counter].txuser == msg.sender){
	       balance[msg.sender] = (balance[msg.sender] + msg.value);
	   }
    }
    

    
    //Send 4% of fund for all membres 
    function Count() onlyowner public {
        while (counter>0) {
            Tx[counter].txuser.transfer((balance[Tx[counter].txuser]/100)*4);
            counter-=1;
            curentBlock = block.number;
        }
    }
    
    //Send refund membres function
    function ReFund() onlyowner public {
        while (counter>0) {
            Tx[counter].txuser.transfer(balance[Tx[counter].txuser]);
            counter-=1;
        }
    }

}