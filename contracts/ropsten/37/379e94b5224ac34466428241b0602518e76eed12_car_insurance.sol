pragma solidity ^0.4.25;

contract car_insurance{
    
    event addCar_log( uint80 license, address sourceAddr, uint fee);
        
    struct car
    {
        uint license;
        uint total_fee;
        bool is_applied;
        uint80 voted_for_license;
        address account_address;
    }
    uint public IndexSize; //total # of cumstomers
    uint public count_yes;
    uint public count_no;
    uint public count_vote;
    string public current_state;
    uint80 public voting_license;
    bool public vote;
   
    uint compensation;
    uint collected_coins=0;
 
    mapping (address=>car) public cars;
    
    constructor() public //start
    {
        
        compensation = 0;
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
                cars[_license].total_fee = msg.value;
                cars[_license].is_applied = false;
                cars[_license].voted_for_license = 0;
                cars[_license].account_address=msg.sender;
                
                IndexSize++; //increase total # of cumstomers
                emit addCar_log (_license, msg.sender, msg.value);
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
    
    function vote(uint80 _license, uint80 _vote) public //vote for target car.
    {  if (vote==true)
      {
        if(cars[_license].license==_license)//check if it is existing in the data.
        {
            if(cars[_license].voted_for_license != voting_license)//check if the user voted
            { 
              if(_vote==1)
               {count_yes++;
               }
              else
                {count_no++;
                }
              count_vote=count_yes+count_no;
              cars[_license].voted_for_license=voting_license;
            }

        }
            
      }
       if (count_vote>=IndexSize)
       {    current_state = "No vote";
            vote=false;
            if (count_yes>=count_no)  
            {   compensation=2*cars[voting_license].total_fee;
                if(compensation<=address(this).balance)
                {cars[voting_license].account_address.transfer(compensation);
                }
                else
                {cars[voting_license].account_address.transfer(address(this).balance);
                }
                
                cars[voting_license].license=0;
                cars[voting_license].total_fee=0;
                cars[voting_license].voted_for_license=0;
                cars[voting_license].is_applied=false;
                cars[voting_license].account_address=0;
                IndexSize--;
            }
            voting_license=0;
            count_yes=0;
            count_no=0;
            count_vote=0;
            
       }
      
    }
}