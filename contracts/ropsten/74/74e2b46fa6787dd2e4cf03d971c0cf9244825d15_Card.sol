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
 
    struct  Room{
        uint  roomid;
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
    uint index=0;
    uint firstplayer;
    event submitRoomdata(uint roomid,address _self,address _other,uint[5] _selfcard,uint[5] _othercard,uint _selfmoney,uint _totalmoney);
    //查找当前玩家账号地址加入玩家池中并设置房间号
   function getselfaddress()public payable{
       require(msg.value>=1*10**16);
       playerpool.push(msg.sender);
       if( playerpool.length<=1||playerpool.length%2!=0){
            firstplayer=msg.value;
           return ;//如果玩家正在匹配中，则放回0，匹配成功返回房间的id号 
       }
       rm.roomid=playerpool.length;
      //设置动态房间金额
      RoomPrice rp;
      rp.roomid=rm.roomid;
      rp.playeraddr[0]=playerpool[index];
      rp.playeraddr[1]=playerpool[index+1];
      rp.playerA[playerpool[index]]=firstplayer;
      rp.playerB[playerpool[index+1]]=msg.value;
     roommoney[index/2]=rp;
        //  roommoney[index/2].playeraddr[index]=playerpool[index];
    //      roommoney[index/2].playeraddr[index+1]=playerpool[index+1];
    //   roommoney[index/2].playerA[playerpool[index]]=firstplayer;
    //   roommoney[index/2].playerB[playerpool[index+1]]=msg.value;
    //   delete playerpool[index];
    //   delete playerpool[index+1];
    //   index+=2;
      
   }
   //玩家打完牌统计数据并加入事件
   function statisticaldata(uint roomid,address _self,address _other,uint[5] _selfcard,uint[5]  _othercard)public {
        
            if(_self==roommoney[roomid].playeraddr[0]){
               uint totalprice=roommoney[roomid].playerA[_self].add(roommoney[roomid].playerB[_other]);
                uint price=roommoney[roomid].playerA[_self];
                  
            pr=Player(_selfcard,price,totalprice);
            roomcount[roomid].mapself[_self]=pr;
            uint  _othermoney=roommoney[roomid].playerB[_other];
            pr =Player(_othercard,_othermoney,totalprice);
            roomcount[roomid].mapother[_other]=pr;
            
            }else{
                  uint totalprice1=roommoney[roomid].playerB[_self].add(roommoney[roomid].playerA[_other]);
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
   function setroommoney(uint _roomid) public  payable {
      //   require(msg.sender.balance>0,"账号余额不足");
      //    address contractaddress=this;
      //    require(msg.value>0,"支付金额必须大于0");
      // contractaddress.transfer(msg.value);
        require(msg.value>1*10*15,"投注金额大于10**15");
     if(msg.sender==roommoney[_roomid].playeraddr[0]){
         roommoney[_roomid].playerA[msg.sender]= roommoney[_roomid].playerA[msg.sender].add(msg.value);
     }else{
          roommoney[_roomid].playerB[msg.sender]= roommoney[_roomid].playerB[msg.sender].add(msg.value);
     }
    
   }
   
   function getplaypool()public view returns(uint){
       return playerpool.length;
   }


  //未配对玩家池
    //         address[] public playerpool;
    //房间对象
    // Room public rm;
    //玩家对象
    // Player public  pr;
    //动态房间对象
    // RoomPrice[] public roommoney;
    //玩家序号
    // uint index=0; 
   

   function getplayerpool() public view returns(address[]){
     return playerpool;
   }

   function getrm() public view returns(uint){
     return (rm.roomid);
   }
  
   function getroommoney() public view returns(uint){
     return roommoney[roommoney.length-1].roomid;
   }
   function getindex() public view returns(uint){
     return index;
   }
}