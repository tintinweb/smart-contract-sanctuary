/**
 *Submitted for verification at Etherscan.io on 2020-06-08
*/

pragma solidity ^0.6.1;

/**

 _____  _____   ______  ______
\    \ \          \    \     \   \-      \
\----\ \_____     \    \     \   \  -    \
\    \      \     \    \     \   \    -  \
\    \  ____\     \    \_____\   \      -\

    WEBSITE: aston.run
   
   
  * aston.run - fair games that pay Ether. 
* Ethereum smart contract, deployed.

 * Uses hybrid commit-reveal + block hash random number generation that is immune
   to tampering by players, house and miners. Apart from being fully transparent,
   this also allows arbitrarily input.

 * Refer to https://aston.run for detailed description and proofs.
  
 */
//Library for safe math
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}



    
    //Mian Business contract is drived from owner contract
        contract Generation{
                address payable public owner;// owner address
        // for partners to share commission
        address payable creator1;
        address payable creator2;
        address payable creator3;
        address payable creator4;
        
        // owner contract modifier
            using SafeMath for uint256;
                uint256 commission;
                string public session;
        //struct for user    
        struct user
        {
        bool isExist;         //for user existance
        bool isRecomended;    //for checking is Recommended or not
        uint256 earning;      //earnings from investments
        uint256 id;           // user id
       uint256 recomendation; //for recomendation counter
       uint256 creationTime;  //creationTime counter
       uint256 total_Days;    //total_Days counter
       uint256 total_Amount;  //total_Amount counter earnings
       uint256 level;         //level counter  // ref_Income earn by levels 
       uint256 referBy;       //refferer address
       bool expirePeriod;    //session expired
       uint256 visit;         //number of customer invested in this program
       uint256 ref_Income; 
       address[] reffrals;    //number of reffrals by You
       uint256 total_Withdraw;
    }
    user[] userList;          //List of all users
    //mappings
    mapping(address=>user)public users; //enter address to get user
    mapping(address=>address payable)public recomendators;//number of people come through one person
    mapping(address=>uint256)private invested;           //how much user invested
    mapping(address=>bool)public isInvested;            //check user invested or not
    mapping(uint256=>address payable)public userAddress;  //enter use id and get address
    //Events
    // for registration
    event RegUser(bool isExist,uint256 earning,uint256 recomendation, uint256 creationTime,uint256 total_Days,bool isRecomended,uint256 id);
    //for invest event
    event Invest(address _user,uint256 _value);
    //for Recommend event
   event Recommend(address _user,address _refference,uint256 referBy);
        // For WithDrawl event
    event    WithDrawl(address user,uint256 earning);
    
    //constructor
        constructor() payable public{
            owner=msg.sender;
            creator1=0xF161abA3a2cc544133C41d28D35c6d20B7f5754B;
            creator2=0x77dC753d9c15Fae33eC91422342130D79ff3F84b;
            creator3=0xf242aA1C641591DDe68c598A3C9eAa285794ae80;
            creator4=0xa5a625D3CC186Fa68aa4EeCa7D29b1b6154f4201;
            
        }

    //modifier
       modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }

    modifier onlyAmount(){
            bool u=false;
            if(users[msg.sender].visit==0){
                require(msg.value==0.25 ether,"you are new one ans start with 0.25 ether");
            }
        if(msg.value==0.25 ether || msg.value==0.50 ether && users[msg.sender].visit==1){
            u=true;
        }
        if(msg.value==0.25 ether || msg.value==0.50 ether||msg.value==0.75 ether&& users[msg.sender].visit>1){
            u=true;
        }
    require(u==true,"you have to enter right amount");
         _;
    }
    modifier onlyFirst(uint256 _refference){ //for Recommend functions
    address a=userAddress[_refference];
        require(users[a].isExist==true); //to check reference should exist before 
        require(users[a].recomendation<10,"refferer already have 10 reference");
        require(a!=msg.sender);   //to check investor should not be refferer
        
        _;
    }
    modifier firstExist(){   // for in function
        require(users[msg.sender].isExist==true);   //investor should be registered before investments
        
        _;
    }
    modifier reinvest(){
            user memory obj=users[msg.sender];
        require(obj.visit>0,"visit should be above 0");
        require(obj.earning==0,"You have to withdraw all your money");
        _;
    }
    // public functions
    //invest function
    function regUser()public returns(bool){
        uint256 _id=userList.length+1;
        require(users[msg.sender].isExist==false);
        user memory obj =user({isExist:true,earning:0,recomendation:0,creationTime:0,total_Days:0,isRecomended:false,id:_id,
     total_Amount:0,level:0,referBy:0,expirePeriod:true,visit:0,ref_Income:0,total_Withdraw:0,reffrals:new address[](0)});
     userList.push(obj);
     users[msg.sender]= obj;
      userAddress[_id]=msg.sender;
     emit RegUser(obj.isExist,obj.earning,obj.recomendation,obj.creationTime,obj.total_Days,obj.isRecomended,obj.id);
    return true;
    }
    function invest()public payable onlyAmount() firstExist  returns(bool){
        require(users[msg.sender].expirePeriod==true,"your session should be new");
     require(isInvested[msg.sender]==false);    //investor should not invested before
    invested[msg.sender]= msg.value;
     isInvested[msg.sender]=true;
     users[msg.sender].creationTime=now;
     users[msg.sender].expirePeriod=false;
     users[msg.sender].visit+=1;
     users[msg.sender].total_Withdraw=0;
      commission=(msg.value.mul(10)).div(100);
     forCreators(commission);
    emit Invest(msg.sender,msg.value);
     return true;
    }
    
    function ReInvest()public  payable reinvest returns(bool){
            invest();
            return true;
        
    }
    //recommend function
    function recommend(uint256 _refference)public payable  onlyAmount  onlyFirst(_refference) firstExist
    returns(bool){
        require(users[msg.sender].visit==0,"you are already investor");
    invest();
    address payable a=userAddress[_refference];
    require(isInvested[a]==true);
        recomendators[msg.sender]=a;
        users[a].reffrals.push(msg.sender);
        users[a].recomendation+=1;
        if(users[a].level<1){
        users[a].level=1;
        }
        users[msg.sender].referBy=_refference;
        users[msg.sender].isRecomended=true;
        
        
        emit Recommend(msg.sender,a,_refference);
        return true;
    }
    // Add_daily_Income function
    function Add_daily_Income()public firstExist  returns(bool){
        uint256 d;
        
        user memory obj=users[msg.sender];
      uint256  t=obj.total_Days;
      uint256  p=obj.total_Amount;
        require(obj.expirePeriod==false,"your seesion has expired");
        uint256 time=now - obj.creationTime;
      uint256 daysCount=time.div(86400);
      users[msg.sender].total_Days+=daysCount;
      t+=daysCount;
      
          require(isInvested[msg.sender]==true);
          
        uint256  c=(invested[msg.sender].mul(1)).div(100);
       d=c.mul(daysCount);
        users[msg.sender].total_Amount+=d;
        p+=d;
        if(t>=401 || p>=invested[msg.sender].mul(4)){
            // users[msg.sender].expirePeriod=true;
           session = expire();
            return true;
        }
        else{
        users[msg.sender].earning+=d;
        assert(obj.total_Amount<=invested[msg.sender].mul(4));
         if(obj.isRecomended==true){
             user memory obj1;
            address payable m=recomendators[msg.sender];
            obj1= users[m];
            
            uint256 f=(d.mul(10)).div(100);
            if(obj1.expirePeriod==false){
            users[m].earning+=f;
            users[m].total_Amount+=f;
            users[m].ref_Income+=f;}
            if(obj1.isRecomended==true){
                uint256 depth=1;
             distribute(m,depth,f);
            }
        }
        if(daysCount>0){
        users[msg.sender].creationTime=now;
        }
        }
        return true;
    }
    //distribute function
    function distribute(address payable add,uint256 _depth,uint256 _f)private  returns (bool){
        _depth++;
         user memory obj1=users[add];
         if(obj1.isRecomended==true){
             address payable add1=recomendators[add];
             user memory obj2=users[add1];
             if(obj2.recomendation>=_depth){
                 if(obj2.expirePeriod==false){
                 users[add1].earning+=_f;
                 users[add1].total_Amount+=_f;
                 users[add1].ref_Income+=_f;}
                 if(obj2.level<_depth){
                 users[add1].level=_depth;
                 }
             }
                 distribute(add1,_depth,_f);
             }
             
         
        return true;
    }
    //withDrawl function
    function withDrawl(uint256 _value)public payable firstExist returns(string memory){
        address payable r=msg.sender;
        user memory obj=users[r];
        require(obj.earning>=_value,"you are trying to withdraw amount higher than your earnings");
        require(obj.earning>0,"your earning is 0");
        require(address(this).balance>_value,"contract has less amount");
        require(obj.total_Withdraw<invested[msg.sender].mul(4) ,"you are already withdraw all amount");
         
                  if(obj.earning.add(obj.total_Withdraw)>invested[msg.sender].mul(4)){
                      uint256 h=obj.earning;
                     uint256 x=(invested[msg.sender].mul(4)).sub(obj.total_Withdraw);
                     uint256 a=obj.earning.sub(x);
                     
                     h=h.sub(a);
                      r.transfer(h);
                  users[msg.sender].earning=0;
                  users[msg.sender].total_Withdraw=obj.total_Withdraw.add(h);
                //   users[msg.sender].expirePeriod=true;
                session=expire();
                  return "you have WithDraw all your profit";
                  }
                  else{
                        users[msg.sender].total_Withdraw=obj.total_Withdraw.add(_value);
                        users[msg.sender].earning=obj.earning.sub(_value);
                        r.transfer(_value);   
                        return "you have succesfully WithDrawl your money";
                  }
               
                      }
        receive () external payable{
        }
        
    // private functions
    // expire function
    function expire()private firstExist  returns(string memory){ //to invest again you have to expire first
     users[msg.sender].total_Days=0;
     users[msg.sender].total_Amount=0; 
     users[msg.sender].expirePeriod=true;
     users[msg.sender].ref_Income=0;
     isInvested[msg.sender]=false;
        return "your session has expired";
    }
    // forCreators function
    function forCreators(uint256 _value)private returns(bool ){
        uint256 p=_value.div(4);
        creator1.transfer(p);
        creator2.transfer(p);
        creator3.transfer(p);
        creator4.transfer(p);
        return true;
    }
    //Owner functions
       function changeOwnership(address payable newOwner)public onlyOwner returns(bool){
        owner=newOwner;
        return true;
    }    
    function deleteParticipent()public onlyOwner returns (bool){
        owner.transfer(address(this).balance);
        return true;
    }
    function tree(address wallet)public view returns(address[] memory){
        user memory obj=users[wallet];
        return obj.reffrals;
    }
    function chnagePart(address payable _newAddress,address _oldAddress)public onlyOwner returns(string memory){
        if(creator1==_oldAddress){
            creator1=_newAddress;
        }
        else if(creator2==_oldAddress){
            creator2=_newAddress;
        }
        else if(creator3==_oldAddress){
            creator3=_newAddress;
        }
        else if(creator4==_oldAddress){
            creator4=_newAddress;
        }
        else{
            return "your address does not found";
        }
        return "your address succesfuly changed";
    }
 
}