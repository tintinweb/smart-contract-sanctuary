/**
 *Submitted for verification at Etherscan.io on 2020-06-26
*/

//EtherStorm::Augmentation of EtherWave
//Official site : https://etherwave.io/EtherStorm

pragma solidity ^0.6.1;
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

        contract EtherStorm{
                address payable public owner;
                address payable creator1;
                address payable creator2;
                address payable creator3;
                using SafeMath for uint256;
                uint256 commission;
                string public session;
        struct user
        {
        uint256 id;           
        uint256 recomendation;
        uint256 creationTime; 
        uint256 total_Days;   
        uint256 total_Amount; 
        uint256 level;         
        uint256 referBy;      
        bool expirePeriod;    
        uint256 visit;        
        uint256 ref_Income; 
        address[] reffrals;   
        uint256 total_Withdraw;
        }
        user[] userList;      
        uint256 cuurUserID=0;
        mapping(address=>user)public users; 
        mapping(address=>address payable)public recomendators;
        mapping(address=>uint256)public invested;           
        mapping(uint256=>address payable)public userAddress; 
        mapping(address=>bool)public isRecomended;
        mapping(uint256=>uint256)public level_price;
        mapping(address=>uint256)public amount;
        
       constructor() payable public{
            owner=msg.sender;
            creator1=0xcA7EE1Aa80a0c5781D3b664D881c29D12Ae80448;
            creator2=0x81205CE7C24Dd5FE71107048a096F4B552F5F30f;
            creator3=0x00A1F03381c4137b9c3d59750021c36F5a1eA35e;
            cuurUserID++;
            user memory obj =user({recomendation:0,creationTime:0,total_Days:0,id:cuurUserID,
            total_Amount:0,level:0,referBy:0,expirePeriod:false,visit:1,ref_Income:0,total_Withdraw:0,reffrals:new address[](0)});
            userList.push(obj);
            users[msg.sender]= obj;
            userAddress[cuurUserID]=msg.sender;
            isRecomended[msg.sender]=false;
            
            level_price[1]=50;
            level_price[2]=30;
            level_price[3]=20;
            level_price[4]=10;
            level_price[5]=10;
            level_price[6]=10;
            level_price[7]=10;
            level_price[8]=10;
            level_price[9]=10;
            level_price[10]=10;
            }
       modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }
    modifier onlyFirst(uint256 _refference){
    address a=userAddress[_refference];
        require(_refference<=cuurUserID);
        require(users[a].expirePeriod==false); 
        require(a!=msg.sender);   
        require(users[msg.sender].visit==0); 
        _;
    }
    modifier reinvest(){
            user memory obj=users[msg.sender];
        require(obj.visit>0,"visit should be above 0");
        require(obj.total_Withdraw==0,"You have to withdraw all your money");
        _;
    }
    modifier investAmount(){
       require(msg.value==0.25 ether || msg.value==0.50 ether|| msg.value==0.75 ether || msg.value==1 ether,"you have to enter right amount");
       _;
    }
    
    function Reinvest()public  payable reinvest investAmount returns(bool){
                require(users[msg.sender].expirePeriod==true,"your session should be new");
    invested[msg.sender]= msg.value;
     users[msg.sender].creationTime=now;
     users[msg.sender].expirePeriod=false;
     users[msg.sender].visit+=1;
      amount[msg.sender]=(invested[msg.sender].mul(1)).div(100);
            return true;
        
    }
    //recommend function
    function join(uint256 _refference)public payable  onlyFirst(_refference) investAmount   returns(bool){
            require(users[msg.sender].visit==0,"you are already investor");
            cuurUserID++;
            userAddress[cuurUserID]=msg.sender;
            invested[msg.sender]= msg.value;
            user memory obj =user({recomendation:0,creationTime:now,total_Days:0,id:cuurUserID,
            total_Amount:0,level:0,referBy:_refference,expirePeriod:false,visit:1,ref_Income:0,total_Withdraw:0,reffrals:new address[](0)});
            userList.push(obj);
            users[msg.sender]= obj;
            isRecomended[msg.sender]=true;
            commission=(msg.value.mul(10)).div(100);
            Creators(commission); 
            address payable a=userAddress[_refference];
            recomendators[msg.sender]=a;
            users[a].reffrals.push(msg.sender);
            users[a].recomendation+=1;
            if(users[a].level<1){
               users[a].level=1;
            }
             amount[msg.sender]=(invested[msg.sender].mul(1)).div(100);
            return true;
    }
    //distribute function
    function down_Income(address  add,uint256 _depth,uint256 _f)private  returns (bool){
        if(_depth>10){
            return true;
        }
        if(isRecomended[add]){
          uint256  f=(_f.mul(level_price[_depth]))/100;
             address payable add1=recomendators[add];
             user memory obj2=users[add1];
             if(obj2.recomendation>=_depth){
                 if(obj2.expirePeriod==false){
                 users[add1].ref_Income+=f;
                 }
                 if(obj2.level<_depth){
                 users[add1].level=_depth;
                 }
             }
             _depth++;
                 down_Income(add1,_depth,_f);
        }
        return true;
    }
    //withDrawl function
    function withDraw()public payable returns(string memory){
        
        uint256 d;
        address payable r=msg.sender;
        user memory obj=users[r];     
        require(obj.expirePeriod==false);
        uint256  t=obj.total_Days;
      
        uint256 time=now - obj.creationTime;
      uint256 daysCount=time.div(86400);
      users[msg.sender].total_Days+=daysCount;
      t+=daysCount;
          if(t>=401){
            return session_Expire();
        }
       d=amount[msg.sender].mul(daysCount);
       uint256  p=obj.total_Amount;
        users[msg.sender].total_Amount+=d;
        p+=d;
        p+=obj.ref_Income;
         if(daysCount>0){
                 uint256 depth=1;
        down_Income(msg.sender,depth,d);
        users[msg.sender].creationTime=now;
        }
        // require(obj.total_Withdraw<invested[msg.sender].mul(4) ,"you are already withdraw all amount");
          d=obj.ref_Income.add(d);
                  if(p>invested[msg.sender].mul(4)){
                     uint256 x=(invested[msg.sender].mul(4)).sub(obj.total_Withdraw);
                      r.transfer(x);
                session=session_Expire();
                  return "you have WithDraw all your profit";
                  }
                  else{
                        users[msg.sender].total_Withdraw=obj.total_Withdraw.add(d);
                        // users[msg.sender].earning=obj.earning.sub(_value);
                        r.transfer(d);   
                        return "you have succesfully WithDrawl your money";
                  }
               
                      }
        receive () external payable{
        }
    function session_Expire()private  returns(string memory){ //to invest again you have to expire first
     users[msg.sender].total_Days=0;
     users[msg.sender].total_Amount=0; 
     users[msg.sender].expirePeriod=true;
     users[msg.sender].ref_Income=0;
    users[msg.sender].total_Withdraw=0;
     invested[msg.sender]=0;
        return "your session has expired";
    }
    // forCreators function
    function Creators(uint256 _value)private returns(bool ){
        uint256 p=_value.div(3);
        creator1.transfer(p);
        creator2.transfer(p);
        creator3.transfer(p);
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
        else{
            return "your address does not found";
        }
        return "your address succesfuly changed";
    }
    function close() public payable onlyOwner { 
  selfdestruct(owner);
}
function owner_withdraw()public payable onlyOwner returns (bool){
    user memory obj=users[owner];
    require(obj.ref_Income>0,"your earnings are less than 0");
    owner.transfer(obj.ref_Income);
    users[owner].ref_Income=0;
    return true;
}
 
}