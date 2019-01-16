pragma solidity ^0.4.21;
 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library Fdatasets {
    
    struct Round {
        uint256 rounds;            //当前轮数
        uint256 rands;               //随机数
        address winningadd;          //抽奖中奖address
        address [] T ;            //100个key
        bool settle;             //能否结算
    }
    struct Round10 {
        uint256 rounds;            //当前轮数
        uint256 rands;               //随机数
        address winningadd;          //抽奖中奖address
        address [] T ;            //100个key
        bool settle;             //能否结算
    }
    struct Round50 {
        uint256 rounds;            //当前轮数
        uint256 rands;               //随机数
        address winningadd;          //抽奖中奖address
        address [] T ;            //100个key
        bool settle;             //能否结算
    }
    struct Player {
        uint256 win01;                // 赢得金库
        uint256 win10;                //1eth
        uint256 win50;                //5eth
        uint256 laff;               //推荐佣金
        uint256 winning01;           //抽奖中奖
        uint256 winning10;           //抽奖中奖
        uint256 winning50;           //抽奖中奖
        uint256 lrnd01;               //结算轮次
        uint256 lrnd10;               //结算轮次
        uint256 lrnd50;               //结算轮次 
        uint64 dengji;                //1,2,3,
        bool olduser;             //新用户
        address firstid;            //上级推荐人，第一
        address secondid;           //上上级推荐人，第二 
    }  
    
}

contract TokenERC20 {
	
    using SafeMath for uint256;
    uint256 public round;   ////当前轮数
    uint256 public round10;   ////当前轮数
    uint256 public round50;   ////当前轮数
    uint256 public prizepool01; //抽奖奖池
    uint256 public prizepool10; //奖池
    uint256 public prizepool50; //奖池 
    
    address companys;
    address company = 0x6f37127a623e71b3f1990eb411c0bbb2e86a50bf;//公司 
 
    mapping(uint256  => Fdatasets.Round)public round_;
    mapping(uint256 => Fdatasets.Round10)public round10_;
    mapping(uint256 => Fdatasets.Round50)public round50_;
    mapping(address => Fdatasets.Player)public player_;
    mapping(uint256 => address [])public T01;//抽奖
    mapping(uint256 => address [])public T10;//抽奖
    mapping(uint256 => address [])public T50;//抽奖
    
    mapping(uint256 => address)public winningaddress01; 
    mapping(uint256 => address)public winningaddress10; 
    mapping(uint256 => address)public winningaddress50; 
    
    function TokenERC20(address _owen)public {
       round = 1;
       round10 = 1;
       round50 = 1;
       round_[round].rounds = 1;
       round10_[round].rounds = 1;
       round50_[round].rounds = 1;
       companys = _owen;
    }
    
    function setts01(uint256 _value,address _owen)public payable{
        require(msg.value == _value * 1 ether / 10 ); 
        //新用户推荐
        if(!player_[msg.sender].olduser ){
            require(msg.sender != _owen);
            oldusesr(msg.sender,_owen);
        }
        //分红
        if(player_[msg.sender].lrnd01 < round  && player_[msg.sender].lrnd01 != 0 ){
            uint256 aunot = getwin011050(msg.sender,1);//分红 
            player_[msg.sender].win01 = aunot.add(player_[msg.sender].win01);
            player_[msg.sender].lrnd01 = round;
        }
        //写入奖池////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        uint256 ac = (round.div(10)).add(1);
        T01[ac].push(msg.sender);
        
        uint256 i;
        if( round_[round].T.length + _value < 100){
            for(i = 1; i <= _value; i++){
                round_[round].T.push(msg.sender);
            }
        } else if ( round_[round].T.length + _value >= 100) {
            uint256 a = round_[round].T.length.add(_value).sub(100);//第二轮
            uint256 b = _value.sub(a);//第一轮
            for(i = 1; i <= b; i++){
                round_[round].T.push(msg.sender);
            }
        //开奖
        round_[round].rands =  lottery(100);
        round_[round].settle = true;///可以结算
        
        //抽奖
        if(round % 10 == 0){
                uint256 ad = round.div(10);//第几次抽奖///////////////////////////////////////////////////////////////////////////////////////////
                uint256 winningid = lottery(T01[ad].length);
                address winadd = T01[ad][winningid];
                winningaddress01[ad] = winadd;
                round_[round].winningadd = winadd;
                player_[winadd].winning01 = prizepool01.add(player_[winadd].winning01);
                prizepool01 = 0;
            }
        //第二轮 
        round++;
        round_[round].rounds = round; 
        for(i = 1; i <= a; i++){
            round_[round].T.push(msg.sender);
        } 
        }
        //
        //address firstid = player_[msg.sender].firstid;
        address firstid = _owen;
        address secondid =player_[firstid].firstid;
        if(firstid != address(0) && firstid != msg.sender){
            player_[firstid].laff = player_[firstid].laff.add(msg.value * 2 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 2 / 100);
        }
        if(secondid != address(0)  && secondid != msg.sender){
            player_[secondid].laff = player_[secondid].laff.add(msg.value * 5 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 5 / 100);
        }
        prizepool01 = prizepool01.add(msg.value * 93 * 5 / 10000);
        company.transfer(msg.value * 93 * 5 / 10000);
        if(player_[msg.sender].dengji < 2){
            player_[msg.sender].dengji = 2;
        }
        
        
    }
    
    //新用户
    function oldusesr(address user,address first)public returns(bool){
        player_[user].firstid = first;
        player_[user].secondid = player_[first].firstid;
        player_[user].olduser = true;
        player_[user].lrnd01 = 1;
        player_[user].lrnd10 = 1;
        player_[user].lrnd50 = 1;
    }
    
    //开奖
    function lottery(uint256 _value)private  view  returns(uint256){
        // 生成一个0到100的随机数:
        uint256   randNonce = 0;
        uint256   random = uint256(keccak256(now, msg.sender, randNonce)) % _value;
        randNonce++;
        uint256  random2 = uint256(keccak256(now, msg.sender, randNonce)) % _value; 
        return random2;
    }
    
    //当前轮数key
    function getTlength01()public view returns(uint256){
        return round_[round].T.length; 
    }
    
    //当前轮数key
    function getTlength10()public view returns(uint256){
        return round10_[round10].T.length; 
    }
    
    //当前轮数key
    function getTlength50()public view returns(uint256){
        return round50_[round50].T.length; 
    }
    
    //查看当前盈利
    function getinfowin(address _owen,uint256 _value)public view returns(uint256 ){
        if(_value == 1){
            return player_[_owen].win01;
        }
        if(_value == 10){
            return player_[_owen].win10;
        }
        if(_value == 50){
            return player_[_owen].win50;
        }
     }
     
     //查看当前盈利
    function getinfowinning(address _owen,uint256 _value)public view returns(uint256 ){
        if(_value == 1){
            return player_[_owen].winning01;
        }
        if(_value == 10){
            return player_[_owen].winning10;
        }
        if(_value == 50){
            return player_[_owen].winning50;
        }
     }
     
    //推荐收入
    function getinfolaff(address _owen)public view returns(uint256 ){
         return player_[_owen].laff;
     } 
    
    //10轮抽奖，中奖地址查询
    function getwinningaddress01()public view returns(address){
        uint256 ad = round.div(10);
        return winningaddress01[ad];
    }
    
    //10轮抽奖，中奖地址查询
    function getwinningaddress10()public view returns(address){
        uint256 ad = round10.div(10);
        return winningaddress10[ad];
    }
    
    //10轮抽奖，中奖地址查询
    function getwinningaddress50()public view returns(address){
        uint256 ad = round50.div(10);
        return winningaddress50[ad];
    }
    
    
    //撤回资金
    function withdraw()public {
        uint256 _eth;
        uint256 win01 = getwin011050(msg.sender,1).add(player_[msg.sender].win01);
        player_[msg.sender].lrnd01 = round;
        uint256 win10 = getwin011050(msg.sender,10).add(player_[msg.sender].win10);
        player_[msg.sender].lrnd10 = round10;
        uint256 win50 = getwin011050(msg.sender,50).add(player_[msg.sender].win50);
        player_[msg.sender].lrnd50 = round50;
        _eth = win01.add(win10).add(win50).add(player_[msg.sender].laff).add(player_[msg.sender].winning01).add(player_[msg.sender].winning10).add(player_[msg.sender].winning50);
        if(_eth > 0){ 
            msg.sender.transfer(_eth);
            player_[msg.sender].win01 = 0;
            player_[msg.sender].win10 = 0;
            player_[msg.sender].win50 = 0;
            player_[msg.sender].laff = 0;
            player_[msg.sender].winning01 = 0;
            player_[msg.sender].winning10 = 0;
            player_[msg.sender].winning50 = 0;
        }
    }
    
    
    
    ////结算，分红 
    function getwin011050(address _owen,uint256 _value)public view   returns(uint256){
        uint256 c = 1;
        uint256 _round;
        uint256 randend;
        address addwin;
        uint256 aoun; 
        if(_value == 1 && round_[player_[_owen].lrnd01].settle == true){
            _round = player_[_owen].lrnd01;
            randend = round_[_round].rands;
            while(c <= 70)
            {
                addwin = round_[_round].T[randend];
                if(addwin == _owen){
                   aoun  = aoun.add(0.1195714285714285 ether); 
                }
            randend++;
            if(randend == 100){
                randend = 0;
            }
            c++;
            }
        }
        if(_value == 10 && round10_[player_[_owen].lrnd10].settle == true){
            _round = player_[_owen].lrnd10;
            randend = round10_[_round].rands;
            while(c <= 70)
            {
                addwin = round10_[_round].T[randend];
                if(addwin == _owen){
                   aoun  = aoun.add(1.195714285714285 ether);
                }
            randend++;
            if(randend == 100){
                randend = 0;
            }
            c++;
            }
        }
        if(_value == 50 && round50_[player_[_owen].lrnd50].settle == true){
            _round = player_[_owen].lrnd50;
            randend = round50_[_round].rands;
            while(c <= 70)
            {
                addwin = round50_[_round].T[randend];
                if(addwin == _owen){
                   aoun  = aoun.add(5.978571428571427 ether);
                }
            randend++;
            if(randend == 100){
                randend = 0;
            }
            c++;
            }
        }
        return aoun;
    }
    
    
    /////////////////////////////////////////////////////////
    //奖池2
    function setts10(uint256 _value,address _owen)public payable{
        require(msg.value == _value * 1 ether  ); 
        require(player_[msg.sender].dengji > 1);///玩过奖池1
        //分红
        if(player_[msg.sender].lrnd10 < round10  && player_[msg.sender].lrnd10 != 0 ){
            uint256 aunot = getwin011050(msg.sender,10);//分红 
            player_[msg.sender].win10 = aunot.add(player_[msg.sender].win10);
            player_[msg.sender].lrnd10 = round10;
        }
        //写入奖池
        uint256 ac = (round10.div(10)).add(1);
        T10[ac].push(msg.sender);
        
        uint256 i;
        if( round10_[round10].T.length + _value < 100){
            for(i = 1; i <= _value; i++){
                round10_[round10].T.push(msg.sender);
            }
        } else if ( round10_[round10].T.length + _value >= 100) {
            uint256 a = round10_[round10].T.length.add(_value).sub(100);//第二轮
            uint256 b = _value.sub(a);//第一轮
            for(i = 1; i <= b; i++){
                round10_[round10].T.push(msg.sender);
            }
            //开奖
            round10_[round10].rands =  lottery(100);
            round10_[round10].settle = true;///可以结算
            
            //抽奖
            if(round10 % 10 == 0){
                uint256 ad = round10.div(10);//第几次抽奖
                uint256 winningid = lottery(T10[ad].length);
                address winadd = T10[ad][winningid];
                winningaddress10[ad] = winadd;
                round10_[round10].winningadd = winadd;
                player_[winadd].winning10 = prizepool10.add(player_[winadd].winning10);
                prizepool10 = 0;
            }
            //第二轮
            round10++;
            round10_[round10].rounds = round10; 
            for(i = 1; i <= a; i++){
                round10_[round10].T.push(msg.sender);
            }
              
        }
        //address firstid = player_[msg.sender].firstid;
        address firstid = _owen;
        address secondid =player_[firstid].firstid;
        if(firstid != address(0)  && firstid != msg.sender ){
            player_[firstid].laff = player_[firstid].laff.add(msg.value * 2 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 2 / 100);
        }
        if(secondid != address(0)  && secondid != msg.sender){
            player_[secondid].laff = player_[secondid].laff.add(msg.value * 5 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 5 / 100);
        }
        prizepool10 = prizepool01.add(msg.value * 465 / 10000);
        company.transfer(msg.value * 465 / 10000);
        if(player_[msg.sender].dengji == 2){
            player_[msg.sender].dengji = 3;
        }
    } 
     
    /////////////////////////////////////////////////////////
    //奖池3
    function setts50(uint256 _value,address _owen)public payable{
        require(msg.value == _value * 5 ether  ); 
        require(player_[msg.sender].dengji > 2);///玩过奖池2
        //分红
        if(player_[msg.sender].lrnd50 < round50  && player_[msg.sender].lrnd50 != 0 ){
            uint256 aunot = getwin011050(msg.sender,50);//分红 
            player_[msg.sender].win50 = aunot.add(player_[msg.sender].win50);
            player_[msg.sender].lrnd50 = round50;
        }
        //写入奖池
        uint256 ac = (round50.div(10)).add(1);
        T50[ac].push(msg.sender);
        
        uint256 i;
        if( round50_[round50].T.length + _value < 200){
            for(i = 1; i <= _value; i++){
                round50_[round50].T.push(msg.sender);
            }
        } else if ( round50_[round50].T.length + _value >= 200) {
            uint256 a = round50_[round50].T.length.add(_value).sub(200);//第二轮
            uint256 b = _value.sub(a);//第一轮
            for(i = 1; i <= b; i++){
                round50_[round50].T.push(msg.sender);
            }
            //开奖
            round50_[round50].rands =  lottery(200);
            round50_[round50].settle = true;///可以结算
            
            //抽奖
            if(round50 % 10 == 0){
                uint256 ad = round10.div(10);//第几次抽奖
                uint256 winningid = lottery(T50[ad].length);
                address winadd = T50[ad][winningid];
                winningaddress50[ad] = winadd;
                round50_[round50].winningadd = winadd;
                player_[winadd].winning50 = prizepool50.add(player_[winadd].winning50);
                prizepool50 = 0;
            }
            //第二轮
            round50++;
            round50_[round50].rounds = round50; 
            for(i = 1; i <= a; i++){
                round50_[round50].T.push(msg.sender);
            }
              
        }
        //address firstid = player_[msg.sender].firstid;
        //address secondid =player_[msg.sender].secondid;
        address firstid = _owen;
        address secondid =player_[firstid].firstid;
        if(firstid != address(0)  && firstid != msg.sender){
            player_[firstid].laff = player_[firstid].laff.add(msg.value * 2 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 2 / 100);
        }
        if(secondid != address(0)  && secondid != msg.sender){
            player_[secondid].laff = player_[secondid].laff.add(msg.value * 5 / 100);
        } else {
            player_[companys].laff = player_[companys].laff.add(msg.value * 5 / 100);
        }
        prizepool50 = prizepool50.add(msg.value * 465 / 10000);
        company.transfer(msg.value * 465 / 10000);
    }

}