pragma solidity ^0.4.25;
// solidity一元夺宝游戏
contract onepay{
   //轮次
   uint256 round_=1;
   mapping(uint256=>uint256[]) roundIds;
   mapping(uint256=>address) players;
   mapping(uint256=>winner) winnerlist;
  
   uint256 seed=1 ;
   uint256 cashPot=0;
   address owner=0x94066127301abf11e1594cCaD1582A4444e51c4d;
   
   modifier ethlimit(uint256 _value){
     require(_value>=0.01 ether); 
     _;
   }
   
   
   struct winner{
      address winaddr;
      uint256 luckid;
      uint256 wincash; 
   }
   

   //抽奖
   function payin() public payable ethlimit(msg.value){
       address player =msg.sender;
       uint256 value =msg.value;
       uint256 round =round_;
       cashPot +=value;
       uint256 num = value / 0.01 ether;
       
        for(uint256 i = 0 ;i<num;i++){
          uint256 luckid=mint();
          roundIds[round].push(luckid);
          players[luckid]=player;  
       }
       if(roundIds[round].length==20){
           withdraw();
       }
       
   }
   
   //开奖
   function withdraw()internal{
      uint256 round=round_; 
      uint256 poolsize=roundIds[round].length;
      //伪随机数
      uint256 index =uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp)))%poolsize;
      uint256 winId =roundIds[round][index];
      address winaddr=players[winId];
      uint256 wincash=cashPot * 80/100;
      winaddr.transfer(wincash);
      owner.transfer(cashPot-wincash);
      winner memory w=winner({winaddr:winaddr,luckid:winId,wincash:wincash});
      winnerlist[winId]= w;
      endround();
   }
   
   
   //产生抽奖号码
   function mint()public returns(uint256){
       seed  +=1;
   }
   
   function endround()public{
       round_ ++;
       cashPot=0;
   }
   
  function showinforound(uint256 _round)view public returns(address winaddr,uint256 luckid,uint256 wincash){
     return (winnerlist[_round].winaddr,winnerlist[_round].luckid,winnerlist[_round].wincash);
      
  } 
}