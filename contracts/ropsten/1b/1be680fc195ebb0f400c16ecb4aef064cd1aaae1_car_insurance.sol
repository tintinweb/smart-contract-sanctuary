pragma solidity ^0.4.25;

contract car_insurance{
        
    struct car
    {
        uint license;
        uint total_fee;
        bool is_applied;
        bool voted;
        address account_address;
    }
    uint public IndexSize; //total # of cumstomers
    uint public count_yes;
	uint public count_no;
	uint public count_vote;
	string public current_state;
	uint80 public voting_license;
	bool public vote;
   
    uint fee;
    uint compensation;
    uint collected_coins=0;
 
    mapping (address=>car) public cars;
    
    constructor() public //start
    {
        fee = 1; //1 eth
        compensation = 10*fee;
        IndexSize=0;
		count_yes=0;
		count_no=0;
		current_state= "Welcome to join into this car insurance contract";
		voting_license=0;
		vote=false;
    }

    function addCar(uint80 _license) public payable
    {//input information by users

     //store new info into data
         if(msg.value>=1 ether){
            if(cars[_license].license ==0){ //check if it is existing in the data
                cars[_license].license = _license;
                cars[_license].total_fee = fee;
                cars[_license].is_applied = false;
                cars[_license].voted = false;
                cars[_license].account_address=msg.sender;
                
                IndexSize++; //increase total # of cumstomers
            }
            else{
                cars[_license].total_fee =cars[_license].total_fee + msg.value; //total fee ++ in case if it exists in the data
            }
         }
		 else{
		 msg.sender.transfer(msg.value);
		 }
    }
    
    
    //apply compensation on user&#39;s side -> input car&#39;s info
    function apply_compensation(uint80 _license) public
    {
        if(cars[_license].license==_license) // checking if it&#39;s existing
        {
            //if it exists then,
            cars[_license].is_applied = true; // set applied status as true
            //wait for the vote -> we have to find a way to force users to use "vote(_car , bool) function"
            
            current_state = "currently there is a vote for";
            voting_license=_license;
            vote=true;
          
        }
        
    }
    
    function vote(uint80 _license, bool _vote) public //vote for target car.
    {  if (vote==true)
      {
        if(cars[_license].license==_license)//check if it is existing in the data.
        {
            if(cars[_license].voted == false)//check if the user voted
            { cars[_license].voted==true;
              if(_vote==true)
               {count_yes++;
               }
              else
                {count_no++;
                  
                }
            }

        }
            
      }
       if (count_yes+count_no>=IndexSize)
       {    current_state = "No vote";
            vote=false;
            if (count_yes>=count_no)  
            {   compensation=2*cars[voting_license].total_fee;
                cars[voting_license].account_address.transfer(compensation);
            }
            voting_license=0;
            count_yes=0;
            count_no=0;
       }
      
    }
    

}