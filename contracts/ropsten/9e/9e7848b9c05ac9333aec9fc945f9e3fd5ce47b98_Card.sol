pragma solidity ^0.4.25;
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Card{
    using SafeMath for uint256;
    //房间数量
    Room[] public roomcount;
    struct Player{
        uint[5] card;
        uint money;
        uint totalmoney;
    }
    //通过玩家账号地址找到房间号
  //  mapping(roomcount=>Room[])) playermap;
 
    struct Room{
        uint roomid;
        mapping(address=>Player) mapself;
        mapping(address=>Player) mapother;
    }
    //玩家房间投注金额
    struct RoomPrice{
        uint roomid;
        address[2] playeraddr;
        mapping(address=>uint) playerA;
        mapping(address=>uint) playerB;
    }
    //未配对玩家数组
    address[] public playerpool;
    Room public rm;
    Player public  pr;
    RoomPrice[] public roommoney;

    
    event submitRoomdata(uint roomid,address _self,address _other,uint[5] _selfcard,uint[5] _othercard,uint _selfmoney,uint _totalmoney);
    //查找当前玩家账号地址加入玩家池中并设置房间号
   function getselfaddress()public payable returns(uint) {
       require(msg.sender.balance>1*10**16);
       playerpool.push(msg.sender);
       if( playerpool.length<=1){
           return 0;//如果玩家正在匹配中，则放回0，匹配成功返回房间的id号 
       }
       rm.roomid=roomcount.length;
       address contractaddress=this;
      contractaddress.transfer(1*10**16);//转账到合约账号
      //设置动态房间金额
      
         roommoney[rm.roomid].roomid=rm.roomid;
         roommoney[rm.roomid].playeraddr[0]=playerpool[0];
         roommoney[rm.roomid].playeraddr[1]=playerpool[1];
       roommoney[rm.roomid].playerA[playerpool[0]]=1*10**16;
       roommoney[rm.roomid].playerB[playerpool[1]]=1*10**16;
       delete playerpool[0];
       delete playerpool[1];
       return rm.roomid;
   }
   //玩家打完牌统计数据并全网通告
   function statisticaldata(uint roomid,address _self,address _other,uint[5] _selfcard,uint[5] _othercard)public {
        
            if(_self==roommoney[roomid].playeraddr[0]){
               uint totalprice=roommoney[roomid].playerA[_self]+roommoney[roomid].playerB[_other];
                uint price=roommoney[roomid].playerA[_self];
                  
            pr=Player(_selfcard,price,totalprice);
            roomcount[roomid].mapself[_self]=pr;
            uint  _othermoney=roommoney[roomid].playerB[_other];
            pr =Player(_othercard,_othermoney,totalprice);
            roomcount[roomid].mapother[_other]=pr;
            
            }else{
                  uint totalprice1=roommoney[roomid].playerB[_self]+roommoney[roomid].playerA[_other];
                uint price1=roommoney[roomid].playerB[_self];
                  
            pr=Player(_selfcard,price1,totalprice1);
            roomcount[roomid].mapself[_self]=pr;
            uint  _othermoney1=roommoney[roomid].playerA[_other];
            pr =Player(_othercard,_othermoney1,totalprice);
            roomcount[roomid].mapother[_other]=pr;
            }
            emit submitRoomdata(roomid,_self,_other,_selfcard,_othercard, price,totalprice);
   }
   //玩家投注金额
   function setroommoney(uint _roomid) public payable returns(string){
        require(msg.sender.balance>0,"账号余额不足");
         address contractaddress=this;
         require(msg.value>0,"支付金额必须大于0");
      contractaddress.transfer(msg.value);
     if(msg.sender==roommoney[_roomid].playeraddr[0]){
         roommoney[_roomid].playerA[msg.sender]= roommoney[_roomid].playerA[msg.sender].add(msg.value);
     }else{
          roommoney[_roomid].playerB[msg.sender]= roommoney[_roomid].playerB[msg.sender].add(msg.value);
     }
     return "支付成功";
   }
   
   function getplaypool()public view returns(uint){
       return playerpool.length;
   }
            
   
}