/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity^0.4.20;  

interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value)returns (bool success);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
 
    /**
     * 初台化构造函数
     */
    function Ownable () public {
        owner = msg.sender;
    }
 
    /**
     * 判断当前合约调用者是否是合约的所有者
     */
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
 
    /**
     * 合约的所有者指派一个新的管理员
     * @param  newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
  
}


contract BebBetsGame is Ownable{
      bool lock = true;
           //是否开奖
     bool isLottery = true;
     
     modifier isLock {
        require(!lock);
        _;
    }
   modifier isBet {
        require(isLottery);
        _;
    }

    //玩家B下注数据结构
   struct Player {
        address addr; //玩家下注 钱包地址
        uint256 amount; //下注金额
        uint position;
    }
    Player[] public games;
    struct miner{
       uint position;//位置1,2=A位置,3,4=B位置,5,6=C位置,7,8 =D位置
       uint point;//点数
   }
   //36张麻将牌1-36
   struct Mahjong{
       uint _Mahjong;//麻将牌分布1~9，1~9,1~9,1~9,4个1~9就是36张麻将
       uint NumberOfcards;
   }
   struct numberGame{
       uint256 NumberOfcards;//期数
       bool northOpenPairs;//北方是否对子
       uint northOpenPoint;//北方点数
       bool WEATOpenPairs;//西方是否对子
       uint WEATOpenPoint;//西方点数
       bool southOpenPairs;//南方是否对子
       uint southOpenPoint;//南方点数
       bool EastOpenPairs;//东方是否对子
       uint EastOpenPoint;//东方点
   }
   //mapping(uint=>miner)miners;
   mapping(address=>uint)public toTime;
   mapping(uint=>numberGame)public numberGamer;
   //numberGame[]public numberGames;//历史期数结构数组
   //Mahjong(uint=>miner)public miners;//映射位置
   miner[] public minersArray;
   Mahjong[] public MahjongsArray;//麻将牌结构数组
   uint256 gamesmul=now;//现在时间
   uint[] game=[0,1,2,3,4,5,6,7];
    uint[] game_a=[2,4,7,3,8,1,5,6,9];
    uint[] game_b=[1,7,9,4,6,5,2,8,3];
    uint[] game_c=[7,3,4,1,8,2,6,9,5];
    uint[] game_d=[5,1,7,9,3,2,8,4,6];
    uint[] game_e=[6,2,8,4,9,1,7,3,5];
    uint[] game_f=[9,4,2,7,5,8,3,6,1];
    //uint8 Licensing;
   uint256 totalAmount=0;//总的玩家下注的金额
    
    uint256 openRandom1;//庄家随机数 1
    uint256 openRandom2;//庄家随机数 2
    uint openPoint;//庄家计算点数
    bool openPairs;//庄家是否为对子
    
    uint256 gameRandomB1;//B位置 随机数 1
    uint256 gameRandomB2;//B位置 随机数 2
    uint gamePointB;//B位置 计算点数
    bool gamePairsB;//B位置 是否为对子
    
    uint256 gameRandomC1;//C位置 随机数 1
    uint256 gameRandomC2;//C位置 随机数 2
    uint gamePointC;//C位置 计算点数
    bool gamePairsC;//C位置 是否为对子
    
    uint256 gameRandomD1;//D位置 随机数 1
    uint256 gameRandomD2;//D位置 随机数 2
    uint gamePointD;//D位置 计算点数
    bool gamePairsD;//D位置 是否为对子
    
    uint256 numberOfPeriods=201900001;//期数 
    uint256 ethExchuangeRate;
    uint8 decimals = 18;
    uint MIN_BET=100*(10**uint256(decimals));//最小下注
    uint MAX_BET=10000000*(10**uint256(decimals));//最大下注
    tokenTransfer public bebTokenTransfer; 
    event messageOpenGame(address sender,bool isScuccess,string message);
        //BEB的合约地址  
    function BebBetsGame(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         setgames();
     }
     function setgames()internal{
        for(uint i=0;i<game.length;i++){
          miner memory set = miner(game[i],0);
           minersArray.push(set);
        }
    }
      //在合约用BEB兑换ETH。每天兑换只能兑换一次，每次1000BEB
    function sellBeb()public {
        if(toTime[msg.sender]==0){
           toTime[msg.sender]==now;
       }
       uint256 _time = toTime[msg.sender]=+86400;
       require(now>_time);
        uint amount = 1000*(10**uint256(decimals))/ethExchuangeRate;
         msg.sender.transfer(amount);
    }
    //在合约用ETH购买BEB
    function buyBeb() payable public {
        uint amount = msg.value;
        //合约余额充足 
        require(getTokenBalance()>amount*ethExchuangeRate);
        //uint256 _value=amount*ethExchuangeRate;
        bebTokenTransfer.transfer(msg.sender,amount*ethExchuangeRate);//转账给会员BEB 
    }
        //调整下注最大和最小
    function setBetMinOrMax(uint256 minAmuont,uint256 maxAmuont)onlyOwner{
     MIN_BET=minAmuont;
     MAX_BET=maxAmuont;   
    }
    //洗牌
    function setMAJIAN()internal{
        
        for(uint nn=0;nn<4;nn++){
            uint256 randomgame = _random(block.difficulty+gamesmul);
            gamesmul+=gamesmul*993/1000;
            if(randomgame==1){
                for(uint h=0;h<game_a.length;h++){
                    Mahjong memory setgame=Mahjong(game_a[h],0);
                    MahjongsArray.push(setgame);
                }
            }
            if(randomgame==2){
                for(uint j=0;j<game_b.length;j++){
                    Mahjong memory setgame1 = Mahjong(game_b[j],0);
                    MahjongsArray.push(setgame1);
                }
            }
            if(randomgame==3){
                for(uint k=0;k<game_c.length;k++){
                    Mahjong memory setgame2=Mahjong(game_c[k],0);
                    MahjongsArray.push(setgame2);
                }
            }
            if(randomgame==4){
                for(uint l=0;l<game_d.length;l++){
                    Mahjong memory setgame3=Mahjong(game_d[l],0);
                    MahjongsArray.push(setgame3);
                }
            }
            if(randomgame==5){
                for(uint m=0;m<game_e.length;m++){
                    Mahjong memory setgame4=Mahjong(game_e[m],0);
                    MahjongsArray.push(setgame4);
                }
            }
            if(randomgame==6){
                for(uint n=0;n<game_f.length;n++){
                    Mahjong memory setgame5=Mahjong(game_f[n],0);
                    MahjongsArray.push(setgame5);
                }
            }
        }
    }
    //停止下注和洗牌
    function stopBets()public onlyOwner {
        lock = false;
        isLottery=false;
        setMAJIAN();//洗牌
    } 
    //开始下注
    function startBets()public onlyOwner {
        isLottery=true;
        delete MahjongsArray;//删除牌结构
        numberOfPeriods+=1;
        //清空合约前一局的所有下注信息
       delete games;
     //for(uint i=0;i<minersArray.length;i++){
        // minersArray[i].point=0; //将所有位置的点数清0 
       // }
    }
   //发牌，一次性把8个点数都发出来
   function hairPoker( uint256 _gamesmul) public isLock onlyOwner{
       uint256 random2 = _random(block.difficulty+_gamesmul*991/100);
       //循环位置数组
        for(uint i=0;i<minersArray.length;i++){
           //检查麻将牌是不是发了4张相同的
              uint256 random1 = random(block.difficulty+_gamesmul*random2/100);
              _gamesmul+=gamesmul+_gamesmul*97/1000;
             //判断麻将牌结构中的位置发牌次数是否小于4次，等于4就重新循环发牌可以循环100次，循环到发牌成功结束喜欢为止
             if(MahjongsArray[random1].NumberOfcards == 4){
              i-=1;//如果这一张牌发了4次就不能再发了，所以这次不算退1重新生成随机数
             }
             else
             {
                 //赋值给位置结构
                 minersArray[i].point=MahjongsArray[random1]._Mahjong;
                 MahjongsArray[random1].NumberOfcards+=1;//发牌次数增加一次
             }
        }
        setPosition();//牌全部发完了，现在赋值给各个位置
   }
   //int144
   function setPosition()internal{
      openRandom1=minersArray[0].point; 
      openRandom2=minersArray[1].point; //庄家
       if(openRandom1 == openRandom2){
         openPairs=true;//庄家为对子
         openPoint = openRandom1;
       }
       else{
        if(openRandom1 + openRandom2 >=10){
         openPairs= false;
         openPoint= openRandom1+ openRandom2-10;//庄家不为对子的时候计算出庄家点数如2+8=0赋值
         }
         else{
         openPairs= false;
         openPoint= openRandom1+ openRandom2;//随机数1+随机数2 相加不会大于等于10，就直接求和赋值
        }   
      }
       
      
      gameRandomB1=minersArray[2].point;
      gameRandomB2=minersArray[3].point;//B位置
      if(gameRandomB1 == gameRandomB2){
            gamePairsB = true;
            gamePointB = gameRandomB1;
        }
        else{
            if(gameRandomB1 + gameRandomB2 >=10){
            gamePairsB = false;
            gamePointB = gameRandomB1 + gameRandomB2 - 10;
        }else{
            gamePairsB = false;
            gamePointB = gameRandomB1 + gameRandomB2;
          }   
        }
      gameRandomC1=minersArray[4].point;//C位置
      gameRandomC2=minersArray[5].point;
      if(gameRandomC1 == gameRandomC2){
            gamePairsC = true;
            gamePointC =gameRandomC1;
        }
        else{
         if(gameRandomC1 + gameRandomC2 >=10){
            gamePairsC = false;
            gamePointC = gameRandomC1 + gameRandomC2 - 10;
        }else{
            gamePairsC = false;
            gamePointC = gameRandomC1 + gameRandomC2;
        }   
        }
        
      gameRandomD1=minersArray[6].point;//D位置
      gameRandomD2=minersArray[7].point;
      if(gameRandomD1 == gameRandomD2){
            gamePairsD = true;
            gamePointD = gameRandomD1;
        }
        else{
           if(gameRandomD1 + gameRandomD2 >=10){
            gamePairsD = false;
            gamePointD = gameRandomD1 + gameRandomD2 - 10;
        }else{
            gamePairsD = false;
            gamePointD = gameRandomD1 + gameRandomD2;
        } 
        }
        
        //每期添加到结构
        numberGame storage betdate=numberGamer[numberOfPeriods];
        betdate.northOpenPairs=openPairs;
        betdate.northOpenPoint=openPoint;
        betdate.WEATOpenPairs=gamePairsB;
        betdate.WEATOpenPoint=gamePointB;
        betdate.southOpenPairs=gamePairsC;
        betdate.southOpenPoint=gamePointC;
        betdate.EastOpenPairs=gamePairsD;
        betdate.EastOpenPoint=gamePointD;
   }
   //历史期号结果查询
   function getIssue(uint _Issue) public view returns(bool,uint,bool,uint,bool,uint,bool,uint){
       numberGame storage betdate=numberGamer[_Issue];
        return (betdate.northOpenPairs,betdate.northOpenPoint,betdate.WEATOpenPairs,betdate.WEATOpenPoint,betdate.southOpenPairs,betdate.southOpenPoint,betdate.EastOpenPairs,betdate.EastOpenPoint);
    }
    //开奖后查询所有位置的点数返回给前台展示
    function getPositionRandom() public view  returns(uint256,uint256,uint256,uint256,
            uint256,uint256,uint256,uint256){
        return(openRandom1,openRandom2,gameRandomB1,gameRandomB2,gameRandomC1,gameRandomC2,gameRandomD1,gameRandomD2);
        
    } 
   //用户下注  position=下注的位置
   event messageBetsGame(address sender,bool isScuccess,string message);
   function betsGame(uint position,uint256 amount)public isBet  {
       //断言下注金额必须大于0
         require (amount >= MIN_BET, "Insufficient bet amount");
         require (amount <= MAX_BET, "The amount is too large");
        //总的玩家下注的金额
        uint256 sumAmount = (amount + totalAmount);
        uint256 bankerAmount= getTokenBalance();
        assert(sumAmount < bankerAmount);
         address _address = msg.sender;
         //把玩家下注金额转给合约   
          bebTokenTransfer.transferFrom(_address,address(this),amount);
         //保存玩家下注信息 1=B,2=C,3=D
            if(position == 1){//B位置玩家 
                Player memory players = Player(_address,amount,position);
                games.push(players);
                //添加合约总金额
                totalAmount += amount;
                messageBetsGame(_address, true,"下注成功 ");
               return;
            }
             if(position == 2){//B位置玩家 
                Player memory playert = Player(_address,amount,position);
                games.push(playert);
                //添加合约总金额
                totalAmount += amount;
                messageBetsGame(_address, true,"下注成功 ");
               return;
            }
            if(position == 3){//B位置玩家 
                Player memory playeru = Player(_address,amount,position);
                games.push(playeru);
                //添加合约总金额
                totalAmount += amount;
                messageBetsGame(_address, true,"下注成功 ");
               return;
            }
    }
    function openGames()  public onlyOwner{
          Player players;
           for(uint i = 0 ; i < games.length ; i ++) {
              players = games[i];
              if(players.position==1){
                transferGame(gamePairsB,gamePointB,players.addr,players.amount);
              }else if(players.position==2){
                transferGame(gamePairsC,gamePointC,players.addr,players.amount);
              }else if(players.position==3){
                transferGame(gamePairsD,gamePointD,players.addr,players.amount);
              }
            }
            messageOpenGame(msg.sender, true,"开奖成功 !");
            return;
      }
    //开奖转账   
    //gamePairs=玩家是否是对子  gamePoint=玩家开奖点数  addr=玩家地址  amount=玩家下注金额
    //openPairs=庄家是否是对子  openPoint=庄家点数
    function transferGame(bool gamePairs,uint gamePoint,address addr,uint256 amount)  internal {
        //判断玩家是不是对子 
        if(gamePairs){
            //判断庄家是不是对子
            if(openPairs){
                //如果玩家和 庄家 对子相等 
                if(gamePoint == openPoint){
                     //退回给玩家金额 
                     bebTokenTransfer.transfer(addr,amount);
                }else if(gamePoint > openPoint){
                    //玩家比庄家大 玩家赢了 本金 + 奖金(100%) 
                    bebTokenTransfer.transfer(addr,amount * 2);
                }else{
                    //庄家赢了 
                }
            }else{//玩家是对子 玩家赢了
                 bebTokenTransfer.transfer(addr,amount * 2);
            }
        }else{
            if(openPairs){
               //庄家是对子 庄家赢了  
            }
            else {
               if(gamePoint==openPoint){
                     //退回给玩家金额 
                    bebTokenTransfer.transfer(addr,amount);    
                }
                else{
                    if(gamePoint > openPoint){
                     bebTokenTransfer.transfer(addr,amount * 2);
                }
                else{
                    //庄家赢了 
                }  
               }
            }
        }
    }
    //把合约里赢取的下注金额转出 
    function withdrawAmount(address toAddress) payable onlyOwner public {
       bebTokenTransfer.transfer(toAddress,address(this).balance);
    } 
   
     //查询合约代币余额 
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
  
    //查询有多少下注金额
    function getTotalAmount() public view returns(uint256){
        return totalAmount;
    }
    
    //查询有多少下注用户
     function getPlayersCount() public view returns(uint){
        return games.length;
    }
    //查询期数
    function getPeriods() public view returns(uint256){
        return numberOfPeriods;
    }
    
    //生成随机数
     function random(uint256 randomyType)  internal returns(uint256 num){
        uint256 random = uint256(keccak256(randomyType,now));
         uint256 randomNum = random%37;
         if(randomNum<1){
             randomNum=1;
         }
         if(randomNum>36){
            randomNum=36; 
         }
         
         return randomNum;
    }
        //生成随机数
     function _random(uint256 randomyType)  internal returns(uint256 num){
        uint256 _random1 = uint256(keccak256(randomyType,now));
         uint256 randomNum = _random1%7;
         if(randomNum<1){
             randomNum=1;
         }
         if(randomNum>6){
            randomNum=6; 
         }
         
         return randomNum;
    }
}