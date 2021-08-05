/**
 *Submitted for verification at Etherscan.io on 2020-06-12
*/

pragma solidity ^0.6.1;
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
        contract Aston{
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
        user[] userList;      
        uint256 cuurUserID=0;//List of all users
        //mappings
        mapping(address=>user)public users; //enter address to get user
        mapping(address=>address payable)public recomendators;//number of people come through one person
        mapping(address=>uint256)public invested;           //how much user invested
        mapping(address=>bool)public isInvested;            //check user invested or not
        mapping(uint256=>address payable)public userAddress;  //enter use id and get address
       //Events
       // for registration
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
            cuurUserID++;
            user memory obj =user({isExist:true,earning:0,recomendation:0,creationTime:0,total_Days:0,isRecomended:false,id:cuurUserID,
            total_Amount:0,level:0,referBy:0,expirePeriod:false,visit:1,ref_Income:0,total_Withdraw:0,reffrals:new address[](0)});
            userList.push(obj);
            users[msg.sender]= obj;
            userAddress[cuurUserID]=msg.sender;
            isInvested[msg.sender]=true;
            }

    //modifier
       modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }
    modifier onlyFirst(uint256 _refference){ //for Recommend functions
    address a=userAddress[_refference];
        require(users[a].isExist==true); //to check reference should exist before 
        require(a!=msg.sender);   //to check investor should not be refferer
        require(users[msg.sender].isExist==false); 
        _;
    }
    modifier reinvest(){
            user memory obj=users[msg.sender];
        require(obj.visit>0,"visit should be above 0");
        require(obj.earning==0,"You have to withdraw all your money");
        bool u=false;
        if(msg.value==0.25 ether || msg.value==0.50 ether && users[msg.sender].visit==1){
            u=true;
        }
        if(msg.value==0.25 ether || msg.value==0.50 ether||msg.value==0.75 ether&& users[msg.sender].visit>1){
            u=true;
        }
    require(u==true,"you have to enter right amount");
        _;
    }
    
    function Reinvest()public  payable reinvest  returns(bool){
                require(users[msg.sender].expirePeriod==true,"your session should be new");
     require(isInvested[msg.sender]==false);    //investor should not invested before
    invested[msg.sender]= msg.value;
     isInvested[msg.sender]=true;
     users[msg.sender].creationTime=now;
     users[msg.sender].expirePeriod=false;
     users[msg.sender].visit+=1;
     users[msg.sender].total_Withdraw=0;
            return true;
        
    }
    //recommend function
    function reffer(uint256 _refference)public payable  onlyFirst(_refference)    returns(bool){
            require(msg.value==0.25 ether,"you are new one ans start with 0.25 ether");
            require(users[msg.sender].visit==0,"you are already investor");
            cuurUserID++;
            userAddress[cuurUserID]=msg.sender;
            isInvested[msg.sender]=true;
            invested[msg.sender]= msg.value;
            user memory obj =user({isExist:true,earning:0,recomendation:0,creationTime:now,total_Days:0,isRecomended:true,id:cuurUserID,
            total_Amount:0,level:0,referBy:_refference,expirePeriod:false,visit:1,ref_Income:0,total_Withdraw:0,reffrals:new address[](0)});
            userList.push(obj);
            users[msg.sender]= obj;
            commission=(msg.value.mul(10)).div(100);
            Creators(commission); 
            address payable a=userAddress[_refference];
            recomendators[msg.sender]=a;
            users[a].reffrals.push(msg.sender);
            users[a].recomendation+=1;
            if(users[a].level<1){
               users[a].level=1;
            }
            emit Recommend(msg.sender,a,_refference);
            return true;
    }
    // Add_daily_Income function
    function daily_Income()public   returns(bool){
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
           session = session_Expire();
            return true;
        }
        else{
        users[msg.sender].earning+=d;
        // assert(obj.total_Amount<=invested[msg.sender].mul(4));
         if(obj.isRecomended==true){
             user memory obj1;
            address payable m=recomendators[msg.sender];
            obj1= users[m];
            
        
            if(obj1.expirePeriod==false){
            users[m].earning+=d;
            users[m].total_Amount+=d;
            users[m].ref_Income+=d;}
            if(obj1.isRecomended==true){
                    uint256 f=(d.mul(10)).div(100);
                uint256 depth=1;
             down_Income(m,depth,f);
            }
        }
        if(daysCount>0){
        users[msg.sender].creationTime=now;
        }
        }
        return true;
    }
    //distribute function
    function down_Income(address payable add,uint256 _depth,uint256 _f)private  returns (bool){
        _depth++;
        if(_depth>10){
            return true;
        }
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
                 down_Income(add1,_depth,_f);
             }
             
         
        return true;
    }
    //withDrawl function
    function withDraw(uint256 _value)public payable returns(string memory){
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
                session=session_Expire();
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
    function session_Expire()private  returns(string memory){ //to invest again you have to expire first
     users[msg.sender].total_Days=0;
     users[msg.sender].total_Amount=0; 
     users[msg.sender].expirePeriod=true;
     users[msg.sender].ref_Income=0;
     isInvested[msg.sender]=false;
        return "your session has expired";
    }
    // forCreators function
    function Creators(uint256 _value)private returns(bool ){
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
    function owner_fund()public payable onlyOwner returns (bool){
        owner.transfer(address(this).balance);
        return true;
    }
    function get_Tree(address wallet)public view returns(address[] memory){
        user memory obj=users[wallet];
        return obj.reffrals;
    }
    function change_creator(address payable _newAddress,address _oldAddress)public onlyOwner returns(string memory){
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
    function close() public payable onlyOwner { //onlyOwner is custom modifier
  selfdestruct(owner);  // `owner` is the owners address
}
function owner_withdraw()public payable onlyOwner returns (bool){
    user memory obj=users[owner];
    require(obj.earning>0,"your earnings are less than 0");
    owner.transfer(obj.earning);
    users[owner].earning=0;
    return true;
}
 
}