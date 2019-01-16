pragma solidity ^0.4.24;

// import "./Console.sol";

// contract Game is Console{
contract Game{
  using ShareCalc for uint256;
  using SafeMath for *;
  uint256 constant private weight0 = 1;
  uint256 constant private weight1 = 1;
  // uint256 constant private weight2 = 0;
  uint256 constant private refcodeFee = 1e16;//
  uint256 constant private phasePerStage = 4; //每个stage 4 个phase;
  uint256 constant private maxStage = 5; //游戏最多10stage
  Entrepreneur.Company public gameState;  
  mapping (bytes32 => address) public refcode2Addr;

  mapping (address => Entrepreneur.Player) public players;    // 
  address foundationAddr = 0xC1C523bAf839515d5681d81f2Cf88725E4Ae0598;
  uint256 constant private phaseLen  = 15 minutes;//the length of each phase
  uint256 constant private growthTarget    = 110; //growth rate per phase;
  uint256 constant private lockup = 1 ;//2 stage以后才能buyout----stage 1的在stage 3 可以buyout
  uint256 constant private sweepDelay = 10 minutes;
  Entrepreneur.Allocation rate = Entrepreneur.Allocation(30,10,5,2,3,50);//div/ref1/ref2/ref3/foundation/pot  
  mapping (uint256 => Entrepreneur.Phase) public phases;
  mapping (uint256 => mapping (address => uint256)) public phase_player_origShare; 
  mapping (uint256 =>mapping (uint256 => mapping (address => uint256))) public stage_prod_player_origShare;//stage = 是seed，angel等
  mapping (uint256 =>mapping (uint256 => mapping (address => uint256))) public stage_prod_player_cdps;
  mapping (uint256 =>mapping (uint256 => mapping (address => uint256))) public stage_prod_player_cbps;
  mapping (uint256 =>mapping (uint256 =>  uint256)) public phase_prod_Share;//
  mapping (uint256 =>mapping (uint256 =>  uint256)) public stage_prod_currShare;//还剩多少
  mapping (uint256 =>mapping (uint256 =>  uint256)) public stage_prod_origShare;//最早卖了多少
  mapping (uint256 =>mapping (uint256 =>  uint256)) public stage_prod_cdps;//Cum Div Per Share
  mapping (uint256 =>mapping (uint256 =>  uint256)) public stage_prod_cbps;//Cum Buyouteth Per Share;
  modifier isHuman() { //据说这个方法比f3d用的方法靠谱
    require(msg.sender == tx.origin, "Humans only");
    _;
  }
  modifier ethLimit(uint256 _eth) { //金额限制
    require(_eth >= 1e16, "0.01ETH min");
    require(_eth <= 1e20, "100ETH max");
    _;    
  }
  constructor () public {
    gameState.stage=1;
    gameState.phase=1;
    phases[gameState.phase].ethGoal=1*10000000000000000000;
    phases[gameState.phase].shareGoal=(gameState.eth).sharesRec(phases[gameState.phase].ethGoal);//转换成shareGoal 
    
    // phases[gameState.phase].shareGoal=673128360964834*1000000000;
    // phases[gameState.phase].ethGoal=(gameState.origShares).ethRec(phases[gameState.phase].shareGoal);
    phases[gameState.phase].stage=1;
    // log(&#39;phases&#39;,gameState.phase);
  }
  string public gameName = "Entrepreneur";
////////////////////////////////////////////////////
//前端专用
////////////////////////////////////////////////////
  
  function accruedDiv (address playerAddr)//确定有多少未提现分红---免费函数
    public //private 
    view 
    returns (uint256)
  {
    uint256 div=0;
    for(uint i=1;i<=gameState.stage;i++){
      for(uint j=0;j<2;j++){//目前就两个产品（buyout or not）
        div=(stage_prod_cdps[i][j].sub(stage_prod_player_cdps[i][j][playerAddr]).mul(stage_prod_player_origShare[i][j][playerAddr])/1e18).add(div);        
      }
    }
    return div;
  }
  function accruedBuyout (address playerAddr)//确定有多少未提现分红---免费函数
    public//private 
    view 
    returns (uint256)
  {
    if(gameState.stage<=lockup)
      return 0;
    uint256 buyoutEth=0;
      for(uint i=1;i<=gameState.stage.sub(lockup);i++){//兑现buyout
        buyoutEth=buyoutEth.add((stage_prod_cbps[i][0].sub(stage_prod_player_cbps[i][0][playerAddr])).mul(stage_prod_player_origShare[i][0][playerAddr])/1e18);        
      }
    return buyoutEth;
  }
  function potShare(address playerAddr)
    private
    view
    returns (uint256)
  {
    uint256 weightedShare=phase_player_origShare[gameState.phase][playerAddr].mul(weight0);//最后三轮的投资者按比例分  
    if(gameState.phase>1){
      weightedShare=weightedShare.add(phase_player_origShare[gameState.phase-1][playerAddr].mul(weight1));
      // if(gameState.phase>2){
      //   weightedShare=weightedShare.add(phase_player_origShare[gameState.phase-2][playerAddr].mul(weight2));        
      // }  
    }
    return weightedShare;        
  }
  function accruedLiq(address playerAddr) 
    private 
    view 
    returns (uint256)
  {
    if(gameState.ended>0 && !players[playerAddr].redeemed )//游戏已经结束且未兑换
    {
      // uint256 weightedShare=phase_player_origShare[gameState.phase][playerAddr].mul(weight0);//最后三轮的投资者按比例分  
      // if(gameState.phase>1){
      //   weightedShare=weightedShare.add(phase_player_origShare[gameState.phase-1][playerAddr].mul(weight1));
      //   if(gameState.phase>2){
      //     weightedShare=weightedShare.add(phase_player_origShare[gameState.phase-2][playerAddr].mul(weight2));        
      //   }  
      // }        
      return (gameState.lps).mul(potShare(playerAddr))/1e18;      
    }      
    return 0;
  }
  function currShares(address playerAddr)
    private
    view
    returns(uint256)
  {
    uint256 _shares;
    for(uint i=1;i<=gameState.stage;i++){//兑现div
      for(uint j=0;j<2;j++){//目前就两个产品（buyout or not）
        if(stage_prod_origShare[i][j]>0)
          _shares=_shares.add(stage_prod_player_origShare[i][j][playerAddr].mul(stage_prod_currShare[i][j])/stage_prod_origShare[i][j]);        
      }
    }
    return _shares;
  }
  function getState() //如果当前phase已经结束，这个会自动变成下一个phase;
    public 
    view 
    returns (
      uint256,//0:pot
      uint256,//1:origshares全局总票数
      uint256,//2:plycount
      uint256,//3:adjCurrPhase
      uint256,//4:phase.end
      uint256,//5:phase.ethGoal
      uint256,//6:phase.eth      
      uint256,//7:stage
      uint256,//8:currEth
      uint256//9:currShare
    )
  {
    uint256 phase=gameState.phase;
    uint256 end;
    uint256 ethGoal;
    uint256 eth;  
    uint256 stage=gameState.stage;
    if(phases[phase].end!=0 && now > phases[phase].end && phases[phase].shares>=phases[phase].shareGoal && gameState.ended==0){//是否需要调整         
      end=phases[phase].end.add(phaseLen);      
      ethGoal=phases[phase].eth.mul(growthTarget)/100;//设置一个更高的目标！              
      phase++;
      stage=(phase-1)/phasePerStage+1;
      // if(phase % phasePerStage == 1){
      //   stage=gameState.stage+1;
      // }
    }else{
      end=phases[phase].end;
      ethGoal=phases[phase].ethGoal;
      eth=phases[phase].eth;
    }
    return (
      gameState.pot, 
      gameState.origShares,
      gameState.plyrCount,
      phase,
      end,
      ethGoal,
      eth,
      stage,
      gameState.eth,
      gameState.currShares
      );    
  }
  function phaseAddtlInfo(uint256 phase)
    public 
    view
    returns(      
      uint256,// stage;
      uint256,// eth;             
      uint256,// ethGoal;      
      uint256// growth
    )
  { 
    uint256 growth;
    if(phase==1)
      growth=0;
    else
      growth=phases[phase].eth.mul(10000)/phases[phase.sub(1)].eth;
    uint256 stage;
    // uint256 end;    
    uint256 ethGoal;
          
    if(phase == gameState.phase + 1 && phases[gameState.phase].end!=0 && phases[gameState.phase].shares>=phases[gameState.phase].shareGoal && now > phases[gameState.phase].end){//目前的phase实际已经结束了
      stage=(phase-1)/phasePerStage+1;
      // end=phases[gameState.phase].end.add(phaseLen);      
      
      ethGoal=phases[gameState.phase].eth.mul(growthTarget)/100;
    }else{
      stage=phases[phase].stage;
      // end=phases[phase].end;
      ethGoal=phases[phase].ethGoal;
    }

    return(
      stage,
      // end,      
      phases[phase].eth,
      ethGoal,      
      growth
    );
  }
  
  function getPlayer(address playerAddr) 
    public 
    view 
    returns (      
      uint256,//cumDiv
      uint256,//cumRef
      uint256,//cumBuyout
      uint256,//cumLiq
      uint256,//ethBalance
      uint256,//remaining share;
      uint256//pot share;
      )
  {    
    return (      
      players[playerAddr].redeemedDiv.add(accruedDiv(playerAddr)),      
      players[playerAddr].redeemedRef,
      players[playerAddr].redeemedBuyout.add(accruedBuyout(playerAddr)),
      players[playerAddr].redeemedLiq.add(accruedLiq(playerAddr)),
      totalBal(playerAddr),
      currShares(playerAddr),
      potShare(playerAddr));
  }
  function totalBal(address playerAddr)
    public 
    view 
    returns(uint256)
  {
    uint256 div = accruedDiv(playerAddr);  
    uint256 liq = accruedLiq(playerAddr);
    uint256 buyout=accruedBuyout(playerAddr);
    return players[playerAddr].bal.add(div).add(liq).add(buyout);
  }

///////////////////////////////////
//内部计算
///////////////////////////////////
  function _register(address playerAddr,address ref) 
    private
  {//注册用户
    if(players[playerAddr].id>0)//已经注册过了
      return;
    if(players[ref].id==0 || ref==playerAddr)//如果推荐人没有注册, 不能推荐；自己不能推荐；
      ref=address(0);
    players[playerAddr].id=++gameState.plyrCount;
    players[playerAddr].ref=ref;
    players[ref].apprentice1++;
    address ref2=players[ref].ref;
    if(ref2 != address(0)){
      players[ref2].apprentice2++;
      address ref3=players[ref2].ref;
      if(ref3 != address(0)){
        players[ref3].apprentice3++;
      }
    }    
  }
  function _register2(address playerAddr,bytes32 refcode)
    private
  {//using refcode
    _register(playerAddr,refcode2Addr[refcode]);
  }

  function endGame() 
    private 
    returns (uint256)
  {
    if(gameState.ended>0){
      return gameState.ended;
    }      
    if(now > phases[gameState.phase].end){
      if(phases[gameState.phase].shares>=phases[gameState.phase].shareGoal)//顺利达标本轮目标
      {
        uint256 nextPhase=gameState.phase+1;
        if(gameState.phase % phasePerStage == 0){          //stage结束
          if(gameState.stage+1>maxStage){//达到最大轮次,
            gameState.ended=2;            //IPO成功
          }else{
            gameState.stage++;            
          }
        }     
        if(gameState.ended==0){
          phases[nextPhase].stage=gameState.stage;
          phases[nextPhase].end=phases[gameState.phase].end.add(phaseLen);      
          phases[nextPhase].ethGoal=phases[gameState.phase].eth.mul(growthTarget)/100;//设置一个更高的目标！        
          phases[nextPhase].shareGoal=(gameState.eth).sharesRec(phases[nextPhase].ethGoal);//转换成shareGoal             
          gameState.phase=nextPhase;        
          if(now > phases[gameState.phase].end){//但是下一轮的时间已经用完了....
            gameState.ended=1;
          }                
        }        
      }else{//本轮就没完成
        gameState.ended=1;                
      }      
    }
    if(gameState.ended>0){//分钱      
      uint256 weightedShare=phases[gameState.phase].shares.mul(weight0);//最后三轮的投资者按比例分  
      if(gameState.phase>1){
        weightedShare=weightedShare.add(phases[gameState.phase-1].shares.mul(weight1));
        // if(gameState.phase>2){
        //   weightedShare=weightedShare.add(phases[gameState.phase-2].shares.mul(weight2));        
        // }  
      }        
      gameState.lps=(gameState.pot).mul(1e18)/weightedShare;
      gameState.pot=0;
    }
    return gameState.ended;      
  }
  function calcBuyout(uint256 shares) 
    public//private 
    view
    returns(uint256)
  { 
    if(gameState.stage<=lockup)
      return 0;
    uint256 buyoutShares;

    if(phases[gameState.phase].shares.add(shares)>phases[gameState.phase].shareGoal){//超过目标的票
      buyoutShares=phases[gameState.phase].shares.add(shares).sub(phases[gameState.phase].shareGoal);
    }
    if(buyoutShares>shares){//本轮购票
      buyoutShares=shares;
    }
    if(buyoutShares > stage_prod_currShare[gameState.stage.sub(lockup)][0]){//可用于回购的票
      buyoutShares= stage_prod_currShare[gameState.stage.sub(lockup)][0];
    }
    return buyoutShares;
  }
  function minRedeem(address playerAddr,uint256 stage,uint256 prodId)//只redeem相关产品的div
    public//private //这类都是应该private的，改成public只是为了测试
  {     
    uint256 div= (stage_prod_cdps[stage][prodId].sub(stage_prod_player_cdps[stage][prodId][playerAddr])).mul(stage_prod_player_origShare[stage][prodId][playerAddr])/1e18;
      
    stage_prod_player_cdps[stage][prodId][playerAddr]=stage_prod_cdps[stage][prodId];
    players[playerAddr].bal=div.add(players[playerAddr].bal);
    players[playerAddr].redeemedDiv=div.add(players[playerAddr].redeemedDiv);    
  }
  function redeem(address playerAddr) //提取到余额
    public//private //这类都是应该private的，改成public只是为了测试
  {
    uint256 liq=0;
    if(gameState.ended>0 && !players[playerAddr].redeemed){//兑现liq
      liq=accruedLiq(playerAddr);
      // players[playerAddr].bal = liq.add(players[playerAddr].bal);        
      players[playerAddr].redeemed=true;
    }

    uint256 div=0;
    for(uint i=1;i<=gameState.stage;i++){//兑现div
      for(uint j=0;j<2;j++){//目前就两个产品（buyout or not）
        div=div.add((stage_prod_cdps[i][j].sub(stage_prod_player_cdps[i][j][playerAddr])).mul(stage_prod_player_origShare[i][j][playerAddr])/1e18);
        stage_prod_player_cdps[i][j][playerAddr]=stage_prod_cdps[i][j];
      }
    }      
    
    uint256 buyoutEth=0;
    if(gameState.stage>lockup){
      for(i=1;i<=gameState.stage.sub(lockup);i++){//兑现buyout
        buyoutEth=buyoutEth.add((stage_prod_cbps[i][0].sub(stage_prod_player_cbps[i][0][playerAddr])).mul(stage_prod_player_origShare[i][0][playerAddr])/1e18);
        stage_prod_player_cbps[i][0][playerAddr]=stage_prod_cbps[i][0];
      }
    }
    
    players[playerAddr].bal=liq.add(div).add(buyoutEth).add(players[playerAddr].bal);
    players[playerAddr].redeemedLiq=players[playerAddr].redeemedLiq.add(liq);
    players[playerAddr].redeemedDiv=players[playerAddr].redeemedDiv.add(div);
    players[playerAddr].redeemedBuyout=players[playerAddr].redeemedBuyout.add(buyoutEth);
  }    
  
  function payRef(address playerAddr,uint256 eth) 
    private
  {
    uint256 foundationAmt=eth.mul(rate.foundation)/100;
    uint256 ref1Amt=eth.mul(rate.ref1)/100;
    uint256 ref2Amt=eth.mul(rate.ref2)/100;
    uint256 ref3Amt=eth.mul(rate.ref3)/100;

    address ref1= players[playerAddr].ref;//三层分销体系:)
    if(ref1 != address(0)){
      players[ref1].bal=ref1Amt.add(players[ref1].bal);
      players[ref1].redeemedRef=ref1Amt.add(players[ref1].redeemedRef);
      address ref2=players[ref1].ref;
      if(ref2 != address(0)){
        players[ref2].bal=ref2Amt.add(players[ref2].bal);
        players[ref2].redeemedRef=ref2Amt.add(players[ref2].redeemedRef);
        address ref3=players[ref2].ref;
        if(ref3 != address(0)){
          players[ref3].bal=ref3Amt.add(players[ref3].bal);
          players[ref3].redeemedRef=ref3Amt.add(players[ref3].redeemedRef);
        }else{
          foundationAmt=foundationAmt.add(ref3Amt);    
        }        
      }else{
        foundationAmt=foundationAmt.add(ref3Amt).add(ref2Amt);    
      }        
    }else{
      foundationAmt=foundationAmt.add(ref3Amt).add(ref2Amt).add(ref1Amt);    
    }            
    foundationAddr.transfer(foundationAmt);  
  }
  function updateDps(uint256 div) 
    private
  {
    uint256 dps=div.mul(1e18)/gameState.currShares;  
    for(uint i = 1; i <= gameState.stage; i++){
      for(uint j=0;j<=1;j++){//目前就两个产品（buyout or not）
        if(stage_prod_origShare[i][j]>0){
          stage_prod_cdps[i][j]=(dps.mul(stage_prod_currShare[i][j])/stage_prod_origShare[i][j]).add(stage_prod_cdps[i][j]);     
        }        
      }
    }    
  }  
  function _buy(address playerAddr, uint256 eth, uint256 prodId) 
    ethLimit(eth)
    private      
  {
    if(prodId>1)//只有0,1两个产品。
      prodId=1;
    if(players[playerAddr].id==0)
      _register(playerAddr,address(0));
      
    minRedeem(playerAddr,gameState.stage,prodId);
    require(players[playerAddr].bal >= eth,"insufficient fund");
        
    if(eth>0 && phases[gameState.phase].end==0)
      phases[gameState.phase].end=now.add(phaseLen);//第一个比买入开始计时---否则会导致lps分母为零..............        

    if(endGame()>0)
      return;

    uint256 stage=gameState.stage;
    uint256 phase=gameState.phase;

    players[playerAddr].bal=(players[playerAddr].bal).sub(eth);//扣钱
    
    uint256 shares=(gameState.eth).sharesRec(eth);//计算能买多少股         
    uint256 buyout = calcBuyout(shares);            
    uint256 newShare=shares.sub(buyout);    
    uint256 newShareEth=(gameState.origShares).ethRec(newShare);//新股对应的资金：    
    uint256 buyoutEth=eth.sub(newShareEth);//老股对应的资金；

    //buyout---only prod 0 can be buyout
    if(buyout>0){
      uint256 buyoutStage=stage.sub(lockup);
      stage_prod_currShare[buyoutStage][0]=stage_prod_currShare[buyoutStage][0].sub(buyout);
      // uint256 bps;
      // bps=buyoutEth.mul(rate.pot).mul(1e18)/100/stage_prod_origShare[buyoutStage][0];
      // stage_prod_cbps[buyoutStage][0]=bps.add(stage_prod_cbps[buyoutStage][0]);
      stage_prod_cbps[buyoutStage][0]=(stage_prod_cbps[buyoutStage][0]).add(buyoutEth.mul(rate.pot).mul(1e18)/100/stage_prod_origShare[buyoutStage][0]);
    }    
    
    // //update global state:
    gameState.origShares = shares.add(gameState.origShares);
    gameState.currShares=newShare.add(gameState.currShares);
    gameState.eth = eth.add(gameState.eth);
    phases[phase].shares=shares.add(phases[phase].shares);    
    phases[phase].eth=eth.add(phases[phase].eth);    
    stage_prod_origShare[stage][prodId]=shares.add(stage_prod_origShare[stage][prodId]);
    stage_prod_currShare[stage][prodId]=stage_prod_origShare[stage][prodId];//shares.add(stage_prod_currShare[stage][prodId]);    
    //update player shares:    
    // players[playerAddr].shares=shares.add(players[playerAddr].shares);//只是为了显示；
    stage_prod_player_origShare[stage][prodId][playerAddr]=shares.add(stage_prod_player_origShare[stage][prodId][playerAddr]);//这是为了回购做的
    phase_player_origShare[phase][playerAddr]=shares.add(phase_player_origShare[phase][playerAddr]);//这是为了最后三轮的人分奖池做的
    
    // //更新dps
    updateDps(eth.mul(rate.div)/100);        
    
    payRef(playerAddr,eth);
    // //只有newShareEth会贡献pot;
    gameState.pot=gameState.pot.add(newShareEth.mul(rate.pot)/100);        
  }
  function sweep()
    public
  {
    if(gameState.ended>0 && now > sweepDelay + phases[gameState.phase].end)
      foundationAddr.transfer(address(this).balance);
  }

///////////////////////////////////
//用户交互
///////////////////////////////////
  function register(address ref)
    isHuman()
    public
  {
    _register(msg.sender,ref);
  }
      
  
  function recharge()    
    public 
    payable
  {
    players[msg.sender].bal=(players[msg.sender].bal).add(msg.value);
  }

  function withdraw() 
    isHuman()
    public 
  {
    redeem(msg.sender);
    //uint256 _bal = players[msg.sender].bal;    
    msg.sender.transfer(players[msg.sender].bal);
    players[msg.sender].bal=0;    
  }
  function buyFromWallet(uint256 prodId,bytes32 refCode) 
    isHuman()    
    public 
    payable
  {
    _register2(msg.sender, refCode);
    players[msg.sender].bal=(players[msg.sender].bal).add(msg.value);        
    _buy(msg.sender,msg.value,prodId);
  }

  function regRefcode(bytes32 refcode)
    public 
    payable
    returns (bool)
  {
    _register2(msg.sender, "");
    if(msg.value<refcodeFee || refcode2Addr[refcode]!=address(0)){
      msg.sender.transfer(msg.value);
      return false;
    }
    refcode2Addr[refcode]=msg.sender;
    return true;  
  }

  function buyFromBal(uint256 eth,uint256 prodId,bytes32 refCode)    
    isHuman()
    public
  {
    _register2(msg.sender, refCode);
    redeem(msg.sender);
    _buy(msg.sender,eth,prodId);
  }

  function getEthNeeded(uint256 keysCount) public view returns(uint256) {
    uint256 ethCount=(gameState.origShares).ethRec(keysCount);//新股对应的资金：

    return ethCount;
  }
}

library Entrepreneur {
  struct Player {    
    uint256 shares;       
    uint256 bal;    //    
    bool redeemed;
    uint256 id;//顺序编号，顺便可以判定是否注册了；
    address ref;//推荐人
    uint256 apprentice1;//一级下线
    uint256 redeemedDiv;    
    uint256 redeemedRef;
    uint256 redeemedBuyout;
    uint256 redeemedLiq;
    uint256 apprentice2;//2级下线
    uint256 apprentice3;//3级下线
  }
    
  struct Company {    
    uint256 eth;    // 0:total eth in    
    uint256 pot;    // 1:eth to pot 
    uint256 origShares;//2:我们用这个新名字
    uint256 currShares;//3;
    uint256 lps;//4:liq per share (in the last phase);
    uint256 ended;//5:整个游戏结束标记;0/1/2: 进行中/失败/IPO    
    uint256 plyrCount;//6:    
    uint256 phase;//7:
    uint256 stage;  //8:
  }  

  struct Phase{ //一个阶段
    uint256 stage;
    uint256 end; //结束时间
    uint256 shareGoal; //目标share
    uint256 shares; //卖出多少share----我们叫做share吧，比较cool;
    uint256 eth;
    uint256 ethGoal;    
  }

  struct Allocation {
    uint256 div;  //dividend paid currently
    uint256 ref1;
    uint256 ref2;
    uint256 ref3;
    uint256 foundation;   //
    uint256 pot;    // 
  }  
}

library ShareCalc {
  using SafeMath for *;
  /**
    * @dev calculates number of share received given X eth 
    * @param _curEth current amount of eth in contract 
    * @param _newEth eth being spent
    * @return amount of Share purchased
    */
  function sharesRec(uint256 _curEth, uint256 _newEth)
      internal
      pure
      returns (uint256)
  {
    return(shares((_curEth).add(_newEth)).sub(shares(_curEth)));
  }
  
  /**
    * @dev calculates amount of eth received if you sold X share 
    * @param _curShares current amount of shares that exist 
    * @param _sellShares amount of shares you wish to sell
    * @return amount of eth received
    */
  function ethRec(uint256 _curShares, uint256 _sellShares)
      internal
      pure
      returns (uint256)
  {
    return(eth(_curShares.add(_sellShares)).sub(eth(_curShares)));
  }

  /**
    * @dev calculates how many shares would exist with given an amount of eth
    * @param _eth eth "in contract"
    * @return number of shares that would exist
    */
  function shares(uint256 _eth) 
      internal
      pure
      returns(uint256)
  {
    //return _eth.mul(10);
    return ((((((_eth).mul(1000000000000000000)).mul(46675600000000000000000000)).add(49018761795600000000000000000000000000000000000000000000000000)).sqrt()).sub(7001340000000000000000000000000)) / (23337800);
  }
  
  /**
    * @dev calculates how much eth would be in contract given a number of shares
    * @param _shares number of shares "in contract" 
    * @return eth that would exists
    */
  function eth(uint256 _shares) 
      internal
      pure
      returns(uint256)  
  {
    //return _shares/10;    
    return ((11668900).mul(_shares.sq()).add(((14002680000000).mul(_shares.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
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
      for (uint256 i = 1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}