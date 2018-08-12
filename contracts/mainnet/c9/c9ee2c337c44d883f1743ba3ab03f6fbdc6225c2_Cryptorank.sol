pragma solidity^0.4.24;

/*interface DiviesInterface {
    function deposit() external payable;
}*/

contract Cryptorank{
    using SafeMath for *;
    using NameFilter for string;

    struct Round
    {
       bool active;
       address lastvoter;
       uint256  jackpot; //奖池 25%
       uint256 start; 
       uint256 end;
       uint256 tickets;//总票数
       uint256 pot;//空投，1%
       
    }
    
    struct Coin
    {
        string symbol;
        string name;
        uint256 votes;
    }
    
    address[] public players;
    //Coin[] public coins;
    Coin[] public coinSorting;//排序数组
    
    mapping(uint256 => Round) public rounds;
    
    //DiviesInterface constant private Divies = DiviesInterface(0x4a771aa796ba9fd4c5ed3d6e7b6e98270d5de880);
   
    
    address  private owner;
    address  public manager;
    uint256  public roundid = 0;//局数
    uint256  constant private initvotetime = 1 hours;
	uint256  constant private voteinterval = 90 seconds;
	uint256  constant private maxvotetime = 24 hours;
	
	uint256 public addcoinfee = 1 ether;
    uint256 private SortingCoinstime;
	
	uint256  public raiseethamount = 0;//众筹100个ether
    uint8 public addcoinslimit = 5;// 用户一次性最多添加5个币种，待管理员调整上币价格
	uint256 public tonextround = 0;//留到下一轮的资金
	
	//uint8 constant public  raiseicoprice = 100;
	//uint8 private invitation = 10;//邀请分比,10%
	//uint8 private promote = 5;//推广.5%
	uint256 private fund = 0;//基金,8%
	uint256 public nextRoundCoolingTime = 10 minutes;//下局开始的冷却时间
	
	uint256 public ticketPrice = 0.01 ether;//票价
	

    mapping(string=>bool) have;

    mapping(string=>uint)  cvotes;
    
    mapping(uint256 => uint256) public awardedReward;//已发放的奖励
    mapping(uint256 => uint256) public ticketHolderReward;//持票者奖励
    mapping(address => uint256) public selfharvest;//占比提成 
    mapping(address => uint256) public selfvoteamount;//个人投资总金额
    mapping(address => uint256) public selfvotes;//个人票数
    mapping(address => uint8) public selfOdds;//中奖概率
    mapping(address => uint256) public selfpotprofit;//空投奖励
    mapping(address => uint256) public selfcommission;//邀请抽成
    mapping(address => string) public playername;
    mapping(address => address) public playerreferees;
    mapping(bytes32 => uint256) public verifyName;//验证名字是否重复
    mapping(address => bool) public pState; //状态 表示地址是否已经注册为会员
    mapping(address => uint256) public raisemax;//众筹个人限制在1ether内
    
    
     modifier isactivity(uint256 rid){
         
         require(rounds[rid].active == true);
         _;
     }
     
     modifier onlyowner()
    {
        require(msg.sender == owner);
        _;
    }
    
     modifier isRepeat(string _name)
    {
        require(have[_name]==false);
       _;
    }
    
     modifier isHave (string _name)
    {
        require(have[_name]==true);
        _;
    }
    
    //排序刷新事件
    event Sortime(address indexed adr,uint256 indexed time);
    event AddCoin(uint _id,string _name,string _symbol);
    
    constructor()  public {
        
        owner = msg.sender;
        
        startRound();
      
    }
    
    //货币函数
     //添加币
    function addcoin(string _name,string _symbol) 
       public
       payable
       isRepeat(_name)
    {
        require(addcoinslimit > 1);
        
        if(msg.sender != owner){
            require(msg.value >= addcoinfee);
            
        }
        
        uint id = coinSorting.push(Coin(_symbol,_name, 0)) - 1;

        cvotes[_name]=id;

        emit AddCoin(id,_name,_symbol);

        have[_name]=true;
        
        addcoinslimit --;
        
        rounds[roundid].jackpot =   rounds[roundid].jackpot.add(msg.value);
    }
    
    
    function tovote(string _name,uint256 _votes,uint256 reward) private 
       isHave(_name)
       {
        
        coinSorting[cvotes[_name]].votes = coinSorting[cvotes[_name]].votes.add(_votes) ;
        
        for(uint256 i = 0;i < players.length;i++){
            
            address player = players[i];
            
            uint256 backreward = reward.mul(selfvotes[player]).div(rounds[roundid].tickets);
            
            selfharvest[player] = selfharvest[player].add(backreward);
        }
        
        
    }
    
    //由大到小排序
    function SortingCoins() public {
        
       /* delete coinSorting;
        coinSorting.length = 0;
        
        for(uint256 i = 0;i<coins.length;i++){
          
            coinSorting.push(Coin(coins[i].symbol,coins[i].name,coins[i].votes));
         
        }*/
        
        for(uint256 i = 0;i< coinSorting.length;i++){
            
            for(uint256 j = i + 1;j < coinSorting.length;j++){
              
                if(coinSorting[i].votes < coinSorting[j].votes){
                    
                    cvotes[coinSorting[i].name] =  j;
                    cvotes[coinSorting[j].name] =  i;
                    
                    Coin memory temp = Coin(coinSorting[i].symbol,coinSorting[i].name,coinSorting[i].votes);
                    coinSorting[i] = Coin(coinSorting[j].symbol,coinSorting[j].name,coinSorting[j].votes);
                    coinSorting[j] = Coin(temp.symbol,temp.name,temp.votes);
                    
                    
                }
            }
        }
     
     }
      
  
    //设置上币价
    function setcoinfee(uint256 _fee)  external onlyowner{
        
        addcoinfee = _fee;
        
        addcoinslimit = 5;
    }
    
    function getcoinSortinglength() public view returns(uint )
    {
        return coinSorting.length;
    }

    function getcvotesid(string _name)public view returns (uint)
    {
        return cvotes[_name];
    }
    function getcoinsvotes(string _name) public view returns(uint)
    {
        return coinSorting[cvotes[_name]].votes;
    }

    

    //众筹
    function raisevote()
        payable
        public
        isactivity(roundid){
        
        require(raiseethamount < 100 ether);
        
        require(raisemax[msg.sender].add(msg.value) <= 1 ether);
        
        uint256 raiseeth;
        
        if(raiseethamount.add(msg.value) > 100 ether){
            
            raiseeth = 100 - raiseethamount;
            
            uint256 backraise = raiseethamount.add(msg.value) - 100 ether;
        
            selfpotprofit[msg.sender] = selfpotprofit[msg.sender].add(backraise);
            
        }else{
            
            raiseeth = msg.value;
        }
      
        raiseethamount = raiseethamount.add(raiseeth);
        
        raisemax[msg.sender] = raisemax[msg.sender].add(raiseeth);
        
        uint256 ticketamount = raiseeth.div(0.01 ether);
        
        //Divies.deposit.value(msg.value.mul(5).div(100))();
        
        uint256 reward = msg.value.mul(51).div(100);
        
        for(uint256 i = 0;i < players.length;i++){
            
            address player = players[i];
            
            uint256 backreward = reward.mul(selfvotes[player]).div(rounds[roundid].tickets);
            
            selfharvest[player] = selfharvest[player].add(backreward);
        }
        
        allot(ticketamount);
    }
    
    
	///////////////////////////////////////////////
	// OWNER FUNCTIONS
	///////////////////////////////////////////////
    function transferOwnership(address newOwner) public {
		require(msg.sender == owner);

		owner = newOwner;
	}
	
	//设置manager地址，用以取款基金和注册费
	function setManager(address _manager) public  onlyowner{
	   
	   manager = _manager;
	}
    
    
    
    //开始下一轮
    function startRound() private{
       
       roundid++;
       
       rounds[roundid].active = true;
       rounds[roundid].lastvoter = 0x0;
       rounds[roundid].jackpot = tonextround;
       rounds[roundid].start = now;
       rounds[roundid].end = now + initvotetime;
       rounds[roundid].tickets = 0;
       rounds[roundid].pot = 0;
       
       ticketPrice = 0.01 ether;
       
  
    }
    
    //计算票价
    function calculatVotePrice() 
         public
         view
         returns(uint256){
        
        uint256 playersnum = players.length;
        
        if(playersnum <= 30)
           return  ticketPrice.mul(112).div(100);
        if(playersnum>30 && playersnum <= 100)
           return  ticketPrice.mul(103).div(100);
        if(playersnum > 100)
           return ticketPrice.mul(101).div(100);
    }
    
    //判断是非中奖
    function airdrop()
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 100) * 100)) < selfOdds[msg.sender])
            return(true);
        else
            return(false);
    }
    
    //计算空投奖励
    function airdrppReward()
        private
        returns(string){
        
        if(airdrop() == false){
            return "非常遗憾！没有空投！";
        }
        else{
            if(selfvoteamount[msg.sender] <= 1 ether && rounds[roundid].pot >= 0.1 ether){
              
              selfpotprofit[msg.sender] =  selfpotprofit[msg.sender].add(0.1 ether);        }
              
              rounds[roundid].pot = rounds[roundid].pot.sub(0.1 ether);
              
              return "恭喜获得空投 0.1 ether";
             }
            if(1 ether < selfvoteamount[msg.sender] && selfvoteamount[msg.sender] <= 5 ether && rounds[roundid].pot >=0.5 ether){
              
              selfpotprofit[msg.sender] = selfpotprofit[msg.sender].add(0.5 ether);
              
              rounds[roundid].pot = rounds[roundid].pot.sub(0.5 ether);
              
              return "恭喜获得空投 0.5 ether";
            }
            if(selfvoteamount[msg.sender] > 5 ether && rounds[roundid].pot >= 1 ether){
              
              selfpotprofit[msg.sender] = selfpotprofit[msg.sender].add(1 ether);
              
              rounds[roundid].pot = rounds[roundid].pot.sub(1 ether);
              
              return "恭喜获得空投 1 ether";
            }
    }
    
    //更新时间
    function updateTimer(uint256 _votes)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > rounds[roundid].end && rounds[roundid].lastvoter == address(0))
            _newTime = (_votes.mul(voteinterval)).add(_now);
        else
            _newTime = (_votes.mul(voteinterval)).add(rounds[roundid].end);
        
        // compare to max and set new end time
        if (_newTime < (maxvotetime).add(_now))
            rounds[roundid].end = _newTime;
        else
            rounds[roundid].end = maxvotetime.add(_now);
    }
    
    //投票
    function voting (string _name) 
       payable 
       public 
       isactivity(roundid)
       returns(string)
    {

        //require(raiseethamount == 100);
        
        uint256 currentticketPrice = ticketPrice;
       
        require(msg.value >= currentticketPrice);
        
        string memory ifgetpot = airdrppReward();
        
        require(now > (rounds[roundid].start + nextRoundCoolingTime) &&(now <= rounds[roundid].end ||rounds[roundid].lastvoter == address(0) ));
        
          
          selfvoteamount[msg.sender] = selfvoteamount[msg.sender].add(msg.value);
          
          uint256 votes = msg.value.div(currentticketPrice);
          
          //Divies.deposit.value(msg.value.mul(5).div(100))();
          
          uint256 reward = msg.value.mul(51).div(100);
          
          uint256 _now = now;
        if(_now - SortingCoinstime >2 hours){
            SortingCoins();
            SortingCoinstime = _now;
            emit Sortime(msg.sender,_now);
        }
          
          tovote(_name,votes,reward);
         
          allot(votes);
         
          calculateselfOdd();
          
          ticketPrice = calculatVotePrice();
        
        
      
       return ifgetpot;
   }
    
    //计算空投中奖概率
    function calculateselfOdd() private {
        
         if(selfvoteamount[msg.sender] <= 1 ether)
              selfOdds[msg.sender] = 25;
            if(1 ether < selfvoteamount[msg.sender] &&selfvoteamount[msg.sender] <= 10 ether)
               selfOdds[msg.sender] = 50;
            if(selfvoteamount[msg.sender] > 10 ether)
               selfOdds[msg.sender] = 75;
        
        
    }
    
    //分配资金
    function allot(uint256 votes) private  isactivity(roundid){
        
          if(playerreferees[msg.sender] != address(0)){
               
              selfcommission[playerreferees[msg.sender]] = selfcommission[playerreferees[msg.sender]].add(msg.value.mul(10).div(100));
          }else{
             
             rounds[roundid].jackpot = rounds[roundid].jackpot.add(msg.value.mul(10).div(100)); 
          }
          
           if(selectplayer() == false){
              players.push(msg.sender);
          }
          
          fund = fund.add(msg.value.mul(13).div(100));
          
          ticketHolderReward[roundid] = ticketHolderReward[roundid].add(msg.value.mul(51).div(100));
          
          rounds[roundid].jackpot = rounds[roundid].jackpot.add(msg.value.mul(25).div(100));
          
          rounds[roundid].pot =  rounds[roundid].pot.add(msg.value.mul(1).div(100));
          
          rounds[roundid].lastvoter = msg.sender;
          
          rounds[roundid].tickets = rounds[roundid].tickets.add(votes);
          
          selfvotes[msg.sender] = selfvotes[msg.sender].add(votes);
        
          updateTimer(votes);
          
    }
    
    
    
    //发奖
    function endround() public isactivity(roundid) {
        
        require(now > rounds[roundid].end && rounds[roundid].lastvoter != address(0));

        uint256 reward = rounds[roundid].jackpot;
        
        for(uint i = 0 ;i< players.length;i++){
            
            address player = players[i];
            
            uint256 selfbalance = selfcommission[msg.sender] + selfharvest[msg.sender] + selfpotprofit[msg.sender];
            
            uint256 endreward = reward.mul(42).div(100).mul(selfvotes[player]).div(rounds[roundid].tickets);
            
            selfcommission[player] = 0;
         
            selfharvest[player] = 0;
         
            selfpotprofit[player] = 0;
            
            selfvoteamount[player] = 0;
            
            selfvotes[player] = 0;
            
            player.transfer(endreward.add(selfbalance));
        }
        
    
        rounds[roundid].lastvoter.transfer(reward.mul(48).div(100));
        
        tonextround = reward.mul(10).div(100);
        
        uint256 remainingpot =  rounds[roundid].pot;
        
        tonextround = tonextround.add(remainingpot);
        
        rounds[roundid].active = false;
        
        delete players;
        players.length = 0;
        
        startRound();

     }
     
     //注册
     function registerNameXNAME(string _nameString,address _inviter) 
        public
        payable {
        // make sure name fees paid
        require (msg.value >= 0.01 ether, "umm.....  you have to pay the name fee");

        bytes32 _name = NameFilter.nameFilter(_nameString);

        require(verifyName[_name]!=1 ,"sorry that names already taken");
        
        bool state =   validation_inviter(_inviter);
        require(state,"注册失败");
        if(!pState[msg.sender]){
            
            verifyName[_name] = 1;
            playername[msg.sender] = _nameString;
            playerreferees[msg.sender] = _inviter;
            pState[msg.sender] = true;
        }

        manager.transfer(msg.value);
    }
    
     function  validation_inviter (address y_inviter) public view returns (bool){
        if(y_inviter== 0x0000000000000000000000000000000000000000){
            return true;
        }
        else if(pState[y_inviter]){
            return true;
        }
        else {

            return false;
        }

    }
     
     
     
     //取款
     function withdraw() public{
         
         uint256 reward = selfcommission[msg.sender] + selfharvest[msg.sender] + selfpotprofit[msg.sender];
         
         uint256 subselfharvest = selfharvest[msg.sender];
         
         selfcommission[msg.sender] = 0;
         
         selfharvest[msg.sender] = 0;
         
         selfpotprofit[msg.sender] = 0;
         
         ticketHolderReward[roundid] = ticketHolderReward[roundid].sub(subselfharvest);
         
         awardedReward[roundid] = awardedReward[roundid].add(reward);
         
         msg.sender.transfer(reward);
     }
     
     //manager取款
     function withdrawbymanager() public{
         
         require(msg.sender == manager);
         
         uint256 fundvalue = fund;
         
         fund = 0;
         
         manager.transfer(fundvalue);
     }
     
     //查询空投奖励
     function getpotReward() public view returns(uint256){
         
         return selfpotprofit[msg.sender];
     }
     
     //查询分红
     function getBonus() public view returns(uint256){
         
         return selfvotes[msg.sender] / rounds[roundid].tickets * rounds[roundid].jackpot;
     }
     
     //查询是否投票人已经在数组里
     function selectplayer() public view returns(bool){
         
         for(uint i = 0;i< players.length ;i++){
             
             if(players[i] == msg.sender)
               return true;
         
             }
            
             return false;
         
     }
    
    
    //返回开奖时间
    function getroundendtime() public view returns(uint256){
        
        if(rounds[roundid].end >= now){
            
            return  rounds[roundid].end - now;
        }
        
        return 0;
    }
    
    
    function getamountvotes() public view returns(uint) {
        
        return rounds[roundid].tickets;
    }
    
     function getjackpot() public view returns(uint)
   {
       return rounds[roundid].jackpot;
   }

    function () payable public {
        
        selfpotprofit[msg.sender] = selfpotprofit[msg.sender].add(msg.value);
    }
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


library NameFilter {

    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input) //名字过滤器
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 ||
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}