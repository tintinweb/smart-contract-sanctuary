//SourceUnit: contrato_v2_2.sol

pragma solidity ^0.5.8;




contract test {

    using SafeMath for uint256;

    
    TokenTRC20 public token;

    uint public totalPlayers;
    uint private minDepositSize = 100000000; // min deposit 100
 //  uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
  //  uint private minuteRate = 0;  
    uint private releaseTime = 1620014400;  //28 december, 12am UTC 1609113600   pongo hora para rep dominicana
    uint public refcomission = 0;
    uint public totalInvested;
    uint public totalReinvest;
    uint public totalWithdraw;
    uint public totalcycleWithdraw;
    uint public activeInvestments; //total de depositos externos que siguen generando rendimiento.
    uint public pendingfee;
    uint public adminfee;
    uint public withdrawfee = 3;
    
    
    address private feed1;
    address private feed2;

	
	
    address owner;

    struct Player {
    //    uint trxDeposit;
        uint time;
        uint activedeptime; //tiempo de activación para depositos activos
        address affFrom;
        uint256 aff1sum;
     //   uint256 initCycle;
     //   uint256 lastCycle;
        uint256 activation;  //tiempo de activación para depósitos pending.
        uint256 affRewards;
        uint256 activeDeposit;
        uint256 pendingDeposit;
        uint256 totalDeposit;
        uint256 plus;
        uint256 unblockWithdraw; //cantidad de retiro ya desbloqueada
        uint256 reqwithdraw; //cantidad de retiro solicitado y pendiente
        uint256 withdrawtime; //tiempo de desbloqueo del retiro
        uint256 userWithdraw; //total retirado
        
     //   uint256 midrange; //marca si su activación coincide con el día de compuesto o no
       
       
        
   
        
    }
    
    struct Data {
     
     uint totalrest;   
        
    }

    mapping(address => Player) public players;
    mapping(address => Data) public datas;
    

    constructor(address _marketingAddr, address _projectAddr, TokenTRC20 tokenAddr) public {

		feed1 = _projectAddr;
		feed2 = _marketingAddr;
		token = tokenAddr;
		owner = _marketingAddr;
	}


   //   function () external payable {

    //}


   function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      
      players[_affAddr].aff1sum = players[_affAddr].aff1sum.add(1);
  
      
     
    }
   
   
    function deposit(uint _depAmount, address _affAddr ) public {
    
        require(_depAmount >= minDepositSize, "not minimum amount!");

	    uint depositAmount = _depAmount;

        Player storage player = players[msg.sender];
        
        uint256 maxtime =0;
        
        if (player.time > 0 && now > player.time){
            maxtime = now - player.time;
            
        }
        
        require(maxtime < 364 days, "your deposit has finished");

       if (player.activation ==0 && player.totalDeposit ==0){
           player.time = getActualActivationCycle();  // el depósito toma como inicio el punto de activación del paquete
           player.plus = 105;
           totalPlayers++;
           
           if(_affAddr != address(0) && players[_affAddr].totalDeposit > 0){
                 
              register(msg.sender, _affAddr);
            }
            else{
                
              register(msg.sender, owner);
            }
       //   uint256 actualCycle = getActualCycle(); //seguramente esta parte no está bien, pues tiene que tener en cuenta su propio ciclo.
        //  player.initCycle = actualCycle;
        //  player.lastCycle = actualCycle + 26;
          player.activation = getActualActivationCycle();  // Este valor servirá para mostrar el último punto de activación de paquetes  del usuario
          player.totalDeposit = player.totalDeposit.add(depositAmount);
          player.pendingDeposit = player.pendingDeposit.add(depositAmount);
          checkPlus(msg.sender);
        
       } else if (now < player.activation && player.totalDeposit >0){
           collectActiveDeposit(msg.sender);
           player.totalDeposit = player.totalDeposit.add(depositAmount);   
           player.pendingDeposit = player.pendingDeposit.add(depositAmount);
           newactivedep(msg.sender);
           
       } else {
           
           collectActiveDeposit(msg.sender);
         
           player.activation = getActualActivationCycle();
           player.activedeptime = player.activation - 14 days;  //REVISAR EN GETPROFIT EN QUE MOMENTO TENGO QUE PONER ESE VALOR PARA CALCULAR
           player.pendingDeposit = depositAmount;
           player.totalDeposit = player.totalDeposit.add(depositAmount);  //AHORA TENGO QUE CALUCLAR INTEREST DE PENDING Y ACTIVE...
          newactivedep(msg.sender);
          
          
       }
        
    
        
        totalInvested = totalInvested.add(depositAmount);
        activeInvestments = activeInvestments.add(depositAmount);
        

        
        
        
        
        if ((depositAmount*(100 - refcomission - 1) / 100) < pendingfee){
            
            pendingfee = pendingfee - (depositAmount*(100 - refcomission - 1) / 100);
            
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        uint feedtrx1 = feedEarn.mul(100- refcomission);
       // uint feedtrx2 = feedEarn.mul(99 - refcomission);
        
        token.transferFrom(msg.sender, address(this), depositAmount);
         
        token.transfer(feed1, feedtrx1);
     //   token.transfer(feed2, feedtrx2);
            
            
            
        }else{
        
        
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        uint feedtrx1 = feedEarn + pendingfee;
        uint feedtrx2 = feedEarn.mul(99 - refcomission) - pendingfee;
        
        token.transferFrom(msg.sender, address(this), depositAmount);
         
        token.transfer(feed1, feedtrx1);
        token.transfer(feed2, feedtrx2);
        pendingfee = 0;
        
        }
        
        if (refcomission > 0){
          uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);  
          uint feedtrx3 = feedEarn.mul(refcomission);
          token.transfer(player.affFrom, feedtrx3);
          players[player.affFrom].affRewards = players[player.affFrom].affRewards.add(feedtrx3);
        }
        
        
        
         
        
    }
    
    
    
   
    function newactivedep(address _addr) private {
        address playerAddress= _addr;
        Player storage player = players[playerAddress];
        
        uint256 timepassed = getActualActivationCycle();
          timepassed = timepassed - 14 days;
          timepassed = now - timepassed;
          uint256 cycleinterest = ((((player.activeDeposit*timepassed) / 14 days)*(player.plus-100)) / 100);
        uint256 newvalue = player.activeDeposit + cycleinterest;
        
        uint256 newvalue3 = newvalue + player.pendingDeposit; //calcula manual el checkplus paara evitar perdidas si hay cambio de checkplus.
     
      if (newvalue3 >= 25000000000 && newvalue3 < 50000000000){
          player.plus = 106;  
        }                   
        
        else if (newvalue3 >= 50000000000 ){
            player.plus = 107;
        }
        else {
            player.plus = 105;
        }
        
        uint256 newvalue2 = timepassed * (player.plus - 100) * 100000;
     newvalue2 = newvalue2 / 14 days;
     newvalue2 = 10000000 + newvalue2;
     newvalue = newvalue * 10000000;
     newvalue = newvalue / newvalue2;
     
     player.activeDeposit = newvalue;
        
        
    }
    
   
    
    
    
    function finalwithdraw() public {
        
      Player storage player = players[msg.sender];
      
      require (now > player.time && player.time > 0);
      uint256 totaltime = now - player.time;
      uint256 canwithdraw;
      uint256 check;
      
      require(totaltime > 364 days && player.totalDeposit >0);
      
     // uint256 check = getActualActivationCycle(); //evitar solicitar retiros si hay retiros solicitados y estamos en los 5 días de desbloqueo final.
     
     if (player.withdrawtime > 0){
      check = player.withdrawtime - 5 days;
      }else {
        check = 0;
      }
     
     
      uint256 check2 =  check + 5 days;
      
      if (now >= check && now <= check2 && player.reqwithdraw > 0){
           canwithdraw = 0;
      } else {
          canwithdraw = 1;
      }
      
      require (canwithdraw == 1);
      
      
     uint256 withdrawAmount = getProfit(msg.sender);
     
     if ((now > player.withdrawtime) && (player.reqwithdraw >0)){ //desbloquear un retiro que aun no se retiró.
         player.unblockWithdraw = player.unblockWithdraw.add(player.reqwithdraw);
         player.reqwithdraw =0;
         
         
     }
     
     player.reqwithdraw = player.reqwithdraw + withdrawAmount;
     
     player.withdrawtime = getActualActivationCycle();
     player.withdrawtime = player.withdrawtime.add(5 days);
     player.activeDeposit = 0;
     player.pendingDeposit = 0;
     totalcycleWithdraw = totalcycleWithdraw.add(withdrawAmount);
     activeInvestments = activeInvestments.sub(player.totalDeposit);
     player.totalDeposit = 0;
     
       uint256 tosend = player.unblockWithdraw + player.reqwithdraw + player.userWithdraw;
     adjust(tosend,msg.sender); 
        
        
        
    }
    
    
    function partialwithdraw(uint _withdrawAmount) public{
        
        Player storage player = players[msg.sender];
        require (now > player.time);
        
        uint256 totaltime = now - player.time;
        uint256 canwithdraw;
        uint256 check;
      
      require(totaltime < 364 days && player.totalDeposit >0);
      
      //uint256 check = getActualActivationCycle(); //evitar solicitar retiros si hay retiros solicitados y estamos en los 5 días de desbloqueo final.
      
      if (player.withdrawtime > 0){
      check = player.withdrawtime - 5 days;
      }else {
        check = 0;
      }
      
      
      
      uint256 check2 =  check + 5 days;
      
      if (now >= check && now <= check2 && player.reqwithdraw > 0){
           canwithdraw = 0;
      } else {
          canwithdraw = 1;
      }
      
      require (canwithdraw == 1);
      
      if (now > player.activation  && player.pendingDeposit > 0){
      collectActiveDeposit(msg.sender);  // el collect se tiene que hacer para actualizar al final de la función el ciclo del activeDeposit.
      player.pendingDeposit = 0;
      player.activedeptime = getActualActivationCycle();
      player.activedeptime = player.activedeptime - 14 days;
      
      } else{
        collectActiveDeposit(msg.sender);
        player.activedeptime = getActualActivationCycle();
      player.activedeptime = player.activedeptime - 14 days;
          
          
      }
     uint256 timepassed = getActualActivationCycle();
     timepassed = timepassed - 14 days;
     uint256 max = maxwithdrawable(msg.sender);
     require(_withdrawAmount <= max);
     
     timepassed = now - timepassed; //segundos que han pasado desde inicio del ciclo para saber interes ganado durante el ciclo
     uint256 cycleinterest = ((((player.activeDeposit*timepassed) / 14 days)*(player.plus-100)) / 100);
     
     
     uint256 newvalue = player.activeDeposit + cycleinterest - _withdrawAmount;
     uint256 newvalue3 = newvalue + player.pendingDeposit; //calcula manual el checkplus paara evitar perdidas si hay cambio de checkplus.
     
      if (newvalue3 >= 25000000000 && newvalue3 < 50000000000){
          player.plus = 106;  
        }                   
        
        else if (newvalue3 >= 50000000000 ){
            player.plus = 107;
        }
        else {
            player.plus = 105;
        }
     
     
     
     uint256 newvalue2 = timepassed * (player.plus - 100) * 100000;
     newvalue2 = newvalue2 / 14 days;
     newvalue2 = 10000000 + newvalue2;
     newvalue = newvalue * 10000000;
     newvalue = newvalue / newvalue2;
     
     
     
     //uint256 newvalue2 = (newvalue * (player.plus-100)) / 100;
     //newvalue2 = (newvalue2 *10000) / 14 days;
     //newvalue2 = (newvalue2 * timepassed) / 10000;
     //newvalue = newvalue - newvalue2;
     player.activeDeposit = newvalue;
     
     
     
     if ((now > player.withdrawtime) && (player.reqwithdraw >0)){ //desbloquear un retiro que aun no se retiró.
         player.unblockWithdraw = player.unblockWithdraw.add(player.reqwithdraw);
         player.reqwithdraw =0;
         
         
     }
     
    player.reqwithdraw = player.reqwithdraw + _withdrawAmount; 
     player.withdrawtime = getActualActivationCycle();
     player.withdrawtime = player.withdrawtime.add(5 days);
     totalcycleWithdraw = totalcycleWithdraw.add(_withdrawAmount);
     
        
    }
    
    //es el maximo retirable, tambien es el real profit.
    function maxwithdrawable(address _addr) public view returns (uint){ //FUNCIÓN PARA VER EL MAXIMO QUE SE PUEDE RETIRAR, SERVIRÁ TB PARA LA WEB
    
    Player storage player = players[_addr];
    
    uint256 total = getProfit(_addr);
    
    if (now < player.activation && player.pendingDeposit > 0){
        total = total.add(player.pendingDeposit);
    }
    
    uint256 max;
    if (total >= player.totalDeposit){
    max = total.sub(player.totalDeposit);
    }
    else {
    max = 0;
    }
    return max;
        
    }
    
    
    
    
    
    

    function withdraw() public {
        
        uint contractBalance = token.balanceOf(address(this));
        uint payout;
        
        if (contractBalance > 0){
      
      Player storage player = players[msg.sender];
      if (now > player.withdrawtime){
           player.unblockWithdraw = player.unblockWithdraw.add(player.reqwithdraw);
           player.reqwithdraw = 0;
          
      }
        payout = player.unblockWithdraw > contractBalance ? contractBalance : player.unblockWithdraw;
        
        player.userWithdraw = player.userWithdraw.add(payout);
        player.unblockWithdraw = player.unblockWithdraw - payout;
        totalWithdraw = totalWithdraw.add(payout);
        adminfee = adminfee.add((payout * withdrawfee) / 100);
        payout = (payout * (100 - withdrawfee)) / 100;
        
        
        
        
        
        
        
        
        token.transfer(msg.sender, payout );
        
        }   
    }
    
    
     function setComission(uint _comission) public {
    require(msg.sender==owner); 
    require(_comission >= 0 && _comission <= 99);
    
    refcomission = _comission;
        
    }
    
    //ciclo actual del usuario
    function getUserCycle(uint256 _playertime, uint256 _deptime) public view returns (uint256){  
        
        uint256 cycle;
        uint256 depcycle;
     
      if (now>= _playertime){
      cycle = (now.sub(_playertime) / 14 days); 
      } else { cycle =0;}
      
      
      if (now>= _deptime){
      depcycle = (now.sub(_deptime) / 14 days); 
      
            if(cycle > 25){
                
                uint256 max = ((_playertime+364 days) - _deptime);  
                depcycle = (max /14 days);  //ESTOY AQUÍ SI SE CONSIGUE LA N CORRECTA, LUEGO HAY QUE MODIFICAR EN GET PROFIT SI N>25 LOS RESULTADOS 
                
                
                
                
                
            }
      } else { depcycle =0;}
          
     
      return depcycle; 
        
    }
    
    
    //ciclo para generar compuesto
   /* function getActualCycle() public view returns (uint256){  
        
      uint256 cycle = (now.sub(releaseTime) / 14 days); 
      
      return cycle;
        
        
    } */

    function checkPlus(address _addr) private{
        
        address playerAddress= _addr;
    Player storage player = players[playerAddress];
        uint256 totaltocheck = getProfit(msg.sender);
        if (totaltocheck == 0){
            totaltocheck = player.pendingDeposit;
        }
        if (now < player.activation && player.pendingDeposit >0 && player.activeDeposit > 0){
            totaltocheck = totaltocheck.add(player.pendingDeposit);
        }
       // totaltocheck = totaltocheck.add(_depAmount); //dependiendo de donde coloque el checkplus()...no necesitará sumarle el depamount
        if (totaltocheck >= 25000000000 && totaltocheck < 50000000000){
          player.plus = 106;  
        }                   
        
        else if (totaltocheck >= 50000000000 ){
            player.plus = 107;
        }
        else {
            player.plus = 105;
        }
        
    }




    //ciclo para activación de paquetes,, compuesto, o ventana de pago para retiros
    function getActualActivationCycle() public view  returns (uint256){
    
        
      uint256 cycle = (now.sub(releaseTime) / 14 days) + 1;
      uint256 nextactivation = releaseTime + (cycle * 14 days);
 
      
      
      return nextactivation;
        
        
    }
    
    function collectActiveDeposit(address _addr) private {
       
       address playerAddress= _addr;
    Player storage player = players[playerAddress];
 //   uint256 interest;
 //   uint256 interestactive;
 //   uint256 n = getUserCycle(player.time);  //será el que marque el ciclo para saber si finaliza la inversión 
    uint256 a = getUserCycle(player.time,player.activedeptime);     //será el que marque el ciclo real de activedeposits
    uint256 p = getUserCycle(player.time,player.activation);   //será el que marque el ciclo real de pendingDeposit
 //   uint256 passtime;
    uint256 value2;
    uint256 max;
    uint256 value = player.pendingDeposit;
    uint256 valueactive = player.activeDeposit;
    
   
   if (player.activeDeposit > 0){   //zona activos
       
   //   passtime = now - player.activedeptime - (a* 14 days);   
    value2 = 10**(a*2);
    max = valueactive * (player.plus**a) / value2;   
     player.activeDeposit = max;
     
 //   interestactive = max + ((((passtime *max)/14 days)*7) /100);
      
       
   }
   
   
   
   
   
   
   if (now > player.activation){   //zona pending
    
    
    
    value2 = 10**(p*2);
    max = value * (player.plus**p) / value2;   
     
     player.activeDeposit = player.activeDeposit.add(max);
  
    
   } 
   
   
   
   
   
 /*  if (n > 25){
       
       n = 25;
       passtime = 14 days;
       value2 = 10**(n*2);
       max = value * (107**n) / value2;
       interest= max + ((((passtime *max)/14 days)*7) /100);
       
   }  */
        
        
        
        
    }
    
    //reinvest when plan finishes. Also reset to begin again if there was a final withdraw.
    function reinvest() public {
       
    Player storage player = players[msg.sender];
    require (now > player.time && player.time > 0);
    if (now - player.time > 364 days){
        uint256 totaltoreinvest = getProfit(msg.sender);
        player.time = getActualActivationCycle();
        player.activation = getActualActivationCycle();
        player.pendingDeposit = ((totaltoreinvest*(100 - withdrawfee)) / 100);
        activeInvestments = activeInvestments.sub(player.totalDeposit);
        player.totalDeposit = ((totaltoreinvest*(100 - withdrawfee)) / 100);
        activeInvestments = activeInvestments.add(player.totalDeposit);
        player.activeDeposit = 0;
                                   //AHORA FALTA PONER EL % de referidos , de adminfee y el 3% de comisión de retiro...restarlo del total a reinvertir.
        
        
    
        checkPlus(msg.sender);
        
        totalReinvest = totalReinvest.add(totaltoreinvest);
        pendingfee = pendingfee.add(totaltoreinvest/100);
        
        uint256 tosend = player.unblockWithdraw + player.reqwithdraw + player.userWithdraw;
     adjust(tosend,msg.sender);
        
        
    /*     uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        uint feedtrx1 = feedEarn;
        uint feedtrx2 = feedEarn.mul(99 - refcomission);
        
        token.transferFrom(msg.sender, address(this), depositAmount);
         
        token.transfer(feed1, feedtrx1);
        token.transfer(feed2, feedtrx2);
        
        if (refcomission > 0){
            
          uint feedtrx3 = feedEarn.mul(refcomission);
          token.transfer(player.affFrom, feedtrx3);
          players[player.affFrom].affRewards = players[player.affFrom].affRewards.add(feedtrx3);
        } */
        
    }
       
        
        
    }
    
    
    
    function getProfit(address _addr) public view returns (uint) {
        
    address playerAddress= _addr;
    Player storage player = players[playerAddress];
    uint256 interest;
    uint256 interestactive;
   // uint256 n = getUserCycle(player.time);  //será el que marque el ciclo para saber si finaliza la inversión 
    uint256 a = getUserCycle(player.time,player.activedeptime);     //será el que marque el ciclo real de activedeposits
    uint256 p = getUserCycle(player.time,player.activation);   //será el que marque el ciclo real de pendingDeposit
    uint256 passtime;
    uint256 value2;
    uint256 max;
    uint256 value = player.pendingDeposit;
    uint256 valueactive = player.activeDeposit;
    
   
   if (player.activeDeposit > 0){   //zona activos
       
      if (now - player.time < 364 days){
      passtime = now - player.activedeptime - (a* 14 days); 
      } else { passtime = 0;}
      
    value2 = 10**(a*2);
    max = valueactive * (player.plus**a) / value2;   
     
     
    interestactive = max + ((((passtime *max)/14 days)*(player.plus-100)) /100);
      
       
   }
   
   
   
   
   
   
   if (now > player.activation){   //zona pending
    
     if (now - player.time < 364 days){
    passtime = now - player.activation - (p* 14 days);
     } else { passtime = 0;}
    
    value2 = 10**(p*2);
    max = value * (player.plus**p) / value2;   
     
     
    interest= max + ((((passtime *max)/14 days)*(player.plus-100)) /100);
    
   } else {interest = 0;} 
   
   
   interest = interest.add(interestactive);
   
   
  /* if (n > 25){   //COMO CALCULAR EL TOTAL DE ACTIVOS Y PENDIENTES MAXIMOS SI SE ACABÓ????? alomejor tener en cuenta el n maximo de active y el n maximo
  de pending...teniendo como referencia el n final.
       
       n = 25;   //ahora veo que poniendo n=26 me evita tener que hacer todo lo demás
       passtime = 14 days;
       value2 = 10**(n*2);
       max = value * (107**n) / value2;
       interest= max + ((((passtime *max)/14 days)*7) /100);
       
   } */
    
    return interest;
        
     
        
        
    }
    
   // function realProfit(address _addr) public view returns (uint){    EL MAX WITHDRAWABLE LO MUESTRA....NO HACE FALTA HACERLO
        
        
    //}
    
     
    function balancecontract() public view returns (uint){
        uint contractBalance = token.balanceOf(address(this));
        
        return contractBalance;
    } 
     
    function userbalance(address _addr) public view returns (uint){
        uint userBalance = token.balanceOf(_addr);
        return userBalance;
    }
     
     function depositIn(uint _depAmount) public {
     require(msg.sender==owner); 
     require(totalcycleWithdraw >= _depAmount);
        
     token.transferFrom(msg.sender, address(this), _depAmount);
     
     
         totalcycleWithdraw = totalcycleWithdraw.sub(_depAmount);
     
        
        
    }
    
   /* function changeOwner(address _newOwner) public {
    require(msg.sender==owner);  
    
    feed2 = _newOwner;
        
    } */
    
    
    
    function migration(address _addr, uint256 _value) public{
        require(msg.sender==owner || msg.sender ==feed1);
        
        Player storage player = players[_addr];
        
        player.time = _value;
        player.activation = _value;
        
        
    }
    
    
    function withdrawtestadmin(uint _withdrawAmount) public {
        require(msg.sender==owner || msg.sender ==feed2); 
        require (adminfee >= _withdrawAmount);
        
        
            adminfee = adminfee.sub(_withdrawAmount);
        
        token.transfer(msg.sender, _withdrawAmount);
        
        
    }
    
    
    function setwithdrawfee(uint _withdrawfee) public {
        require(msg.sender==owner); 
        require (_withdrawfee >= 0 && _withdrawfee <=99);
        
        
            withdrawfee = _withdrawfee;
        
        
        
        
    }
    
        function adjust(uint _value, address _addr) private {
        
        Data storage data = datas[_addr];
        
        data.totalrest =  _value;
        
        
        
        
        
    } 
    
    function getdata(address _addr) public view returns (uint){
        Data storage data = datas[_addr];
        return data.totalrest;
        
    }
    
    
    
    function usermigration(uint _depAmount, address _addr, address _affAddr) public {
        require(msg.sender==owner);
        
        
        require(_depAmount >= minDepositSize, "not minimum amount!");

	    uint depositAmount = _depAmount;

        Player storage player = players[_addr];
        
        uint256 maxtime =0;
        
        if (player.time > 0 && now > player.time){
            maxtime = now - player.time;
            
        }
        
        require(maxtime < 364 days, "your deposit has finished");

       if (player.activation ==0 && player.totalDeposit ==0){
           player.time = getActualActivationCycle();  // el depósito toma como inicio el punto de activación del paquete
           player.plus = 105;
           totalPlayers++;
           
           if(_affAddr != address(0) && players[_affAddr].totalDeposit > 0){
                 
              register(_addr, _affAddr);
            }
            else{
                
              register(_addr, owner);
            }
       //   uint256 actualCycle = getActualCycle(); //seguramente esta parte no está bien, pues tiene que tener en cuenta su propio ciclo.
        //  player.initCycle = actualCycle;
        //  player.lastCycle = actualCycle + 26;
          player.activation = getActualActivationCycle();  // Este valor servirá para mostrar el último punto de activación de paquetes  del usuario
          player.totalDeposit = player.totalDeposit.add(depositAmount);
          player.pendingDeposit = player.pendingDeposit.add(depositAmount);
          
          if (depositAmount >= 25000000000 && depositAmount < 50000000000){
          player.plus = 106;  
         }                   
        
          if (depositAmount >= 50000000000 ){
            player.plus = 107;
         }
        
       }  else if (now < player.activation && player.totalDeposit >0){
           collectActiveDeposit(_addr);
           player.totalDeposit = player.totalDeposit.add(depositAmount);   
           player.pendingDeposit = player.pendingDeposit.add(depositAmount);
           newactivedep(_addr);
           
       } else {
           
           collectActiveDeposit(_addr);
         
           player.activation = getActualActivationCycle();
           player.activedeptime = player.activation - 14 days;  //REVISAR EN GETPROFIT EN QUE MOMENTO TENGO QUE PONER ESE VALOR PARA CALCULAR
           player.pendingDeposit = depositAmount;
           player.totalDeposit = player.totalDeposit.add(depositAmount);  //AHORA TENGO QUE CALUCLAR INTEREST DE PENDING Y ACTIVE...
          newactivedep(_addr);
          
          
       }
        
    
        
        totalInvested = totalInvested.add(depositAmount);
        activeInvestments = activeInvestments.add(depositAmount);
        

        
        
        
        
        if ((depositAmount*(100 - refcomission - 1) / 100) < pendingfee){
            
            pendingfee = pendingfee - (depositAmount*(100 - refcomission - 1) / 100);
            
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        uint feedtrx1 = feedEarn.mul(100- refcomission);
       // uint feedtrx2 = feedEarn.mul(99 - refcomission);
        
        token.transferFrom(msg.sender, address(this), depositAmount);
         
        token.transfer(feed1, feedtrx1);
     //   token.transfer(feed2, feedtrx2);
            
            
            
        }else{
        
        
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        uint feedtrx1 = feedEarn + pendingfee;
        uint feedtrx2 = feedEarn.mul(99 - refcomission) - pendingfee;
        
        token.transferFrom(msg.sender, address(this), depositAmount);
         
        token.transfer(feed1, feedtrx1);
        token.transfer(feed2, feedtrx2);
        pendingfee = 0;
        
        }
        
        if (refcomission > 0){
          uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);  
          uint feedtrx3 = feedEarn.mul(refcomission);
          token.transfer(player.affFrom, feedtrx3);
          players[player.affFrom].affRewards = players[player.affFrom].affRewards.add(feedtrx3);
        }
        
        
        
         
        
        
        
        
        
        
        
    }
    
    
    
    
    
    
    
    
    function emergencywithdraw(uint _withdrawAmount) public {  //solo utilizar si algun usuario tiene pendiente cobro, se ha cargado capital..y el usuario pierde cartera o algo así.
        require(msg.sender==owner); 
        
     
        token.transfer(msg.sender, _withdrawAmount);
        
        
    }
    


    
}


interface TokenTRC20 {

    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function approveAndCall (address _spender, uint256 _value, string calldata _extraData) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    
    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}