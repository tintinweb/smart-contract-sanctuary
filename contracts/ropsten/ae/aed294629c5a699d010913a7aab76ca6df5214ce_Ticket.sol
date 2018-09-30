pragma solidity ^0.4.24;
library FDdatasets {
     
     struct winner{
        uint count;
        address[] _address;
    }
    struct personalticket{ //personal tickets
        uint256 hi;
        uint256 index;
        uint256 times;
      //  uint256[2][] myticket;
       // mapping(uint256=>uint256[2]) myticket;
    }
    struct roundinfo{
        uint256 ticketcount;//total count 
        uint256 firstprize;//1 winner
       // uint256[] secondprize;//5  winners
       // uint256[] thirdprize;//10  winners
        uint256  eth;//total eth
    }
    struct teamfee{
        uint256 champion;//first prize ratio
        uint256 second;//second prize ratio
        uint256 third;//third prize ratio
        //uint256 nextround;//nextround ratio
        uint256 team;//team fee ratia
    }
}
contract Ticket {
    using SafeMath for *;
    uint256 public Id;//roud id nuber
    uint256 constant private ticketsCountLimit = 1000;//0.01*9999 = 99.99ETH;when reach 99.99ETH ,atomatic award,end cur round,begin next round
    constructor()
    public
    {
        fees_ = FDdatasets.teamfee(50,45,0,5); //45% to champion;20% to second prize;30% to third;team get 5% fee from all the award-winner
       // roundinfos[1]=roundinfo(0,0,x,x,0);
       roundinfos[1].ticketcount = 0;
      // ticketsCountLimit = 10000;
       Id = 1;
        InitialArray();
    }
   
   
    mapping(uint256=>mapping(address => uint256)) public addrticket;//addr->count
    mapping(uint256=>mapping(uint256 => address)) public tickets;//ticket->address
    mapping(uint256=>address[]) public winners;//have already withdraw;
    mapping(uint256=>FDdatasets.roundinfo) public roundinfos;
    mapping(uint256=>uint256[]) public second;
    mapping(uint256=>uint256[]) public third;
    mapping(uint256=>mapping(address=>uint256[])) public _pticket;
    mapping(uint256=>mapping(uint256=>uint256)) private roomBalance;//record room Balance round id => roomid =>Balance
    uint256 totalBalance = 30*1000000000000000000;
    address private admin = msg.sender;
    uint256[]  ticketpool;
    uint256[]  x;
    uint256 high =950;
    uint256 low = 49;
    uint256 flag = 99;
    FDdatasets.teamfee fees_;
   
    function  InitialArray()
    public
    {
        for (uint256 v=0;v<50;v++){
            //ticketpool[v] = v;
            ticketpool.push(v);
            ticketpool.push(999-v);
        }
        high =950;
        low = 49;
        flag = 99;
    }
    
    
    function resetArray()
    public
    {
        for (uint256 v=0;v<50;v++){
            //ticketpool[v] = v;
           // ticketpool.push(v);
           // ticketpool.push(999-v);
            ticketpool[2*v] = v;
            ticketpool[2*v+1]=999-v;
        }
        high =950;
        low = 49;
        flag = 99;
        
    }
    
    function  del(uint index)
    public
    {
        if(index >= ticketpool.length) throw;
        for(uint i = index;i < ticketpool.length-1;i++){
            ticketpool[i] = ticketpool[i+1];
        }
        delete ticketpool[ticketpool.length-1];
        ticketpool.length --;
        
    }
    
    
     function updata(uint index,uint value ){
        if(index > ticketpool.length -1) throw;
        ticketpool[index] = value;
    }

    function  query(uint index)
    public
    returns(uint value)
    {
        if(index >= ticketpool.length) throw;
        return ticketpool[index];
    }
    modifier onlyOwner() {
        require(msg.sender == admin, "only owner");
        _;
    }
     modifier validRoom(uint256 id) {
        require(id>=1 && id <=100, "wrong room id");
        _;
    }
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
      modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 10000000000000000, "0.01ETH per a share ");
        require(_eth <= 20000000000000000000, "max limits: 20 ETH per address");
        _;
    }
    modifier isIntegerMultiple(uint256 _eth) {
        require(msg.value != 0, "at least 0.01");
        require(msg.value%30000000000000000 == 0, "0.03ETH multiples ");
        _;
    }
      
     function getWinNumber()//from the latest block hash ,get the first four number which is 0~9
        private
         returns(uint[] ret)
    {
       bytes32 hash = block.blockhash(block.number-1);
       ret = new uint[](4);
       uint256 _length = hash.length;
       uint256 j = 0;
       for (uint256 i=0;i<_length;i++)
       {
           if(j==4)
           {
               break;
           }
           byte h = byte(hash[i]>>4);
           byte l = byte(hash[i]&0x0F);
           if(h >= 0x00 && h <= 0x09)
           {
               ret[j] = uint(h);
               j++;
           }
           if(j==4)
           {
               break;
           }
           if(l >= 0x00 && l <= 0x09)
           {
               ret[j] = uint(l);
               j++;
           }
       }
        //return ret,hash;
    }
    //  function airdrop()
    //     private
    //     view
    //     returns(uint256)
    // {
    //     uint256 seed = uint256(keccak256(abi.encodePacked(

    //         (block.timestamp).add
    //         (block.difficulty).add
    //         ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
    //         (block.gaslimit).add
    //         ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
    //         (block.number)

    //     )));
    //   return seed%100;
    // }
    
    
    function  getTicketCode(uint256 dig)
    private
    returns(uint[] ret)
    {
         require(dig >=0 && dig<=9999, "dig should in [0,9999]");
         ret = new uint[](4);
         ret[0] = dig/1000;
         ret[1] = (dig%1000)/100;
         ret[2] = (dig%1000)%100/10;
         ret[3] = (dig%1000)%100%10;
    }

      function getthird(uint[] winNumber)
    private
    
    {
       
        // uint[] memory winNumber = getWinNumber();
          uint256 t=0;
          //roundinfos[Id].thirdprize  = new uint256[](90);
            for(uint i= 0;i<=9;i++){
                for(uint j=0;j<=9;j++)
                {
                    if(j!=winNumber[1])
                    {
                       
                       // roundinfos[Id].thirdprize[t]=i*1000+j*100+winNumber[2]*10+winNumber[3];
                        third[Id].push(i*1000+j*100+winNumber[2]*10+winNumber[3]);
                      // uint256 x = i*1000+j*100+winNumber[2]*10+winNumber[3];
                        t++;
                    }
                  
                 
                }
            }
          //  return third;
      //   return (second,third) ;
     
    }
     function getsecond(uint[] winNumber)
        private
      
    {
       
        // uint[] memory winNumber = getWinNumber();
            uint256 s=0;
          // roundinfos[Id].secondprize = new uint256[](9);
            for(uint i= 0;i<=9;i++){
                    if(i!=winNumber[0])
                    {
                       second[Id].push( i*100+winNumber[1]*10+winNumber[2]);
                       // roundinfos[Id].secondprize[s] = i*1000+winNumber[1]*100+winNumber[2]*10+winNumber[3];
                     // uint256 y= i*1000+winNumber[1]*100+winNumber[2]*10+winNumber[3];
                        s++;
                    }
               
            }
            //return second;
   
     
    }
    
    function  IsGot(uint[] ret,uint[] got)//
    private
    returns(uint r)//0:not prize;1:first prize;2:second prize;3:third prize
    {
         for(uint256 i=3;i>=1;i--){
             if (ret[i]!=got[i])
             {
                 break;
             }
         }
         if (i>=2)
         {
             r = 0;
         }
         if (i==1)
         {
             r = 3;
         }
         
         if(i==0)
         {
             r=2;
         }
         if(i==0 && ret[0] == got[0])
         {
             r=1;
         }
    }
     event onNewTicket
    (
        uint256 start,
        uint256 count,
        uint256 rid
    );
    
    function got()
    public
   
    {
          uint256 rId = Id;
          uint[] memory winNumber = getWinNumber();
            roundinfos[rId].firstprize = winNumber[0]*100+winNumber[1]*10+winNumber[2];
            
             getsecond(winNumber);
         //    getthird(winNumber);
           
            Id++;
           
    }

     function buyTickets(uint256 _shares,uint256 room)
        isHuman()
        isWithinLimits(msg.value)
        isIntegerMultiple(msg.value)
        validRoom(room)
        public
        payable
    {
     // require(room>=1 && room <=100, "wrong room id");
    
     require(_shares == msg.value/30000000000000000, "wrong shares");
      
      //uint256 roomid = room;
      uint256 rId = Id;
      uint256  start = roundinfos[rId].ticketcount;
     
      for(uint256 i=0;i<_shares;i++)
      {
       
        if(roundinfos[rId].ticketcount >= ticketsCountLimit)
          {
             rId++;
             resetArray();
          }
         
          if(high.sub(low)>1)
          {
               _pticket[rId][msg.sender].push(ticketpool[99-i]);
                tickets[rId][ticketpool[99-i]] = msg.sender;
                 if(i%2 == 0)
                  {
                      high--;
                      ticketpool[99-i] = high;
                  }else{
                      low++;
                      ticketpool[99-i] = low;
                  }
          }
          else
          {
               _pticket[rId][msg.sender].push(ticketpool[flag]);
                tickets[rId][ticketpool[flag]] = msg.sender;
                flag--;
          }
          
          roundinfos[rId].ticketcount++;
         
          
         
      }
      
     
      if(start.add(_shares)>=ticketsCountLimit)
      {
           uint256 cur = totalBalance.sub(roundinfos[rId].eth);
           roomBalance[Id][room] += cur;  //modify roomBalance
           roundinfos[Id].eth = totalBalance;  //
           got();
           roomBalance[Id][room] += msg.value.sub(cur);//modify net round roomBalance
           roundinfos[Id].eth +=msg.value.sub(cur);//modify this round balance
           addrticket[Id][msg.sender] +=  ticketsCountLimit.sub(start) ; //modify one&#39;s ticket count
           addrticket[Id][msg.sender] +=  _shares.sub(ticketsCountLimit.sub(start));//modify one&#39;s next round ticket count
      }else{
           roomBalance[rId][room] += msg.value; //modify room balance
           roundinfos[rId].eth += msg.value;  
           addrticket[rId][msg.sender] +=  _shares ;
      }
     // uint256 limits = ticketsCountLimit;
      emit onNewTicket(start,_shares,rId);
      
    }
    function getUserTicket(uint256 rid)
    public
    returns(uint256[] ret)
    {
       require(rid>=1 && rid<=Id);
       ret = _pticket[rid][msg.sender];
       
       
    }
    
    function getCurRoundInfo()
    public
    returns(uint256 curRoundId,uint256 curEth)
    {
     return (Id,roundinfos[Id].eth);
       
    }
    
    
    
    
    function getRoomBalance(uint256 rid,uint256 roomid)
    validRoom(roomid)
    public
    returns(uint256)
    {
        require(rid>=1 && rid<=Id);
        return roomBalance[rid][roomid];
    }
    function withdraw(uint256 rid)
        isHuman()
        public
    {
        uint256 rId = Id;
       require(rid>=1 && rid<rId);
      if(admin == msg.sender){
          admin.transfer(totalBalance.mul(5)/100);
          return;
      }
      for(uint256 k=0;k<winners[rId].length;k++){
          if( winners[rId][k] == msg.sender){ //already get award
              return;
          }
      }
      uint256 champion = roundinfos[rid].firstprize;
      if(msg.sender == tickets[rid][champion]) {//is champion winner
          msg.sender.transfer((totalBalance.mul(fees_.champion)/100).mul(95)/100);
        
          winners[rId].push(msg.sender) ;
      }
     // uint256[] second = roundinfos[rid].secondprize;
      for (uint256 i =0;i<second[rid].length;i++){//9 second prize winner
           
          if(tickets[rid][second[rid][i]] ==  msg.sender){
          //trans eth to msg.sender
            msg.sender.transfer((totalBalance.mul(fees_.second)/900).mul(95)/100);//because 9 person to get the 20%,5% of the award to team
            //winners[rId].count= winners[rId].count +1; 
            winners[rId].push(msg.sender) ;
          }
      }
       
     // uint256[] third = roundinfos[rid].thirdprize;
    //     for (uint256 j =0;j<third[rid].length;j++){//90 third prize winner
           
    //       if(tickets[rid][third[rid][j]] ==  msg.sender){
    //       //trans eth to msg.sender
    //           msg.sender.transfer((totalBalance.mul(fees_.third)/9000).mul(95)/100);//because 90 person to get the 20%,5% of the award to team
    //           //winners[rId].count= winners[rId].count +1; 
    //           winners[rId].push(msg.sender);
              
    //       }
    //   }
       
    }
    
    function getLastAwardInfo(uint256 rid)
        public
        view
        returns(uint256 firstprize, uint256[] secondprize)
    {
        require(rid>=1 && rid<=Id);
       
        return
          ( roundinfos[rid].firstprize,
            second[rid]
         //   third[rid]
          );
    }
    
    
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}