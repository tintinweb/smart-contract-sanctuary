pragma solidity ^0.4.25;



contract car_insurance{
        
    struct car
    {
        uint license;
        uint total_fee;
        bool is_applied;
        uint voted_yes;
        uint voted_no;
    }
    uint public IndexSize; //total # of cumstomers
    
   
    uint fee;
    uint compensation;
    uint collected_coins=0;
 
    mapping (address=>car) public cars;
    
    constructor() public //start
    {
        fee = 100; //100 eth
        compensation = 1000;
        IndexSize=1;
    }

    function addCar(uint _license) public payable
    {//input information by users

     //store new info into data
         if(msg.value>=1 ether){
            if(cars[msg.sender].license ==0){ //check if it is existing in the data
                cars[msg.sender].license = _license;
                cars[msg.sender].total_fee = fee;
                cars[msg.sender].is_applied = false;
                cars[msg.sender].voted_yes=0;
                cars[msg.sender].voted_no=0;

                 
                 collected_coins +=1;
                 IndexSize++; //increase total # of cumstomers
            }
            else{
                cars[msg.sender].total_fee +=1; //total fee ++ in case if it exists in the data
            }
         }
    }
    
    
    //apply compensation on user&#39;s side -> input car&#39;s info
    function apply_compensation() public payable
    {
        if(cars[msg.sender].license!=0) // checking if it&#39;s existing
        {
            //if it exists then,
            cars[msg.sender].is_applied = true; // set applied status as true
            //wait for the vote -> we have to find a way to force users to use "vote(_car , bool) function"
            while(cars[msg.sender].voted_yes+cars[msg.sender].voted_no < IndexSize)
            {
                //force other nodes to use vote();
            }
            
            if(cars[msg.sender].voted_yes>cars[msg.sender].voted_no)//if majority wins, then compensate
            {
                compensate(msg.sender);
                reset_application(msg.sender);
            }
            else{//if not, don&#39;t compensate, just reset &#39;
                reset_application(msg.sender);
            }
            
        }
        
    }
    
    function vote(address _car, bool _vote) public //vote for target car.
    {
        if(cars[msg.sender].license!=0)//checking if the sender has right to vote - check if he is customer or not.
        {
            if(cars[_car].is_applied == true)//check if the target car has applied for the compensation
            {
                if(_vote == true){// if vote for yes
                    cars[_car].voted_yes++;
                }
                else{// if vote for no
                    cars[_car].voted_no++;
                }
            }
            
        }
    }
    
    function pay(uint _amount) public payable 
    {
        if( cars[msg.sender].license!=0)// check if the caller is in the list
        {
            cars[msg.sender].total_fee -= msg.value;
        }
    }
        
    
    function compensate(address _payee) private 
    {
        //check, if the caller is the contract itself and the payee is valid in the list
        if( msg.sender == address(this) && cars[_payee].license!=0) 
        {
               _payee.send(compensation);
        }
        
    }
    
    function reset_application (address _payee) private //reset the number of votes on the application
    {
        cars[_payee].voted_yes=0;
        cars[_payee].voted_no=0;
        cars[_payee].is_applied = false;
    }
    
   
    
    
    function set_fee(uint _fee) private
    {
        fee = _fee;
    }
    function set_compenstation (uint _compensation) private
    {
       compensation = _compensation;
    }
    
}