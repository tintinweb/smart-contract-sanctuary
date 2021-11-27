/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

pragma solidity = 0.6.12;




// SPDX-License-Identifier: MIT



library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }



}



interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP21{ 
    function _VotingB (uint256 Amount)external;
    function _Voting (address from, address to, uint256 Amount) external;}



contract NFTWPower is IBEP20 {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8  private _decimals;
    IBEP20   _NFTWtoken;
    IBEP21   _Voting4;
    IBEP21   _Voting3;
    IBEP21   _Voting2;
    address  _NFTWtoken1;
    address  _Withdraw;
    address  _Voting1Add;
    address  _Voting2Add;
    address  _Voting3Add;
    address  _Voting4Add;
    address  _Owner;
    uint256 private _totalSupply;
    uint256 private _Invitation;
    uint256 private _RewardRatioA;
    uint256 private _RewardRatioB;
    uint256 private _PowerBurn;
    uint256 private _BonusRatio;
    uint256 private _Star1BurnRate;
    uint256 private _Star2BurnRate;
    uint256 private _Star3BurnRate;
    uint256 private _Star4BurnRate;
    uint256 private _Star1Reach;
    uint256 private _Star2Reach;
    uint256 private _Star3Reach;
    uint256 private _Star4Reach;
    uint256 private _Star1Keep;
    uint256 private _Star2Keep;
    uint256 private _Star3Keep;
    uint256 private _Star4Keep;
    uint256 private _Voters;
    uint256 private VotingPower;
    address[]_ALLUSRES;
    
    
    struct User{
        bool IsGade4;
        bool IsStar1;
        bool IsStar2;
        uint32 Startblock;
        uint32 Star1update;
        uint32 Star2update;
        uint32 Star3update;
        uint32 Star4update;
        uint32 Gade4update;
        address Father;
        uint256  Pending;
        address[] Sons;
    }
    
    mapping (address => bool) private isVoters;
    mapping (address => User) private UserS;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    


    constructor(uint256 invitation,uint256 ratio,uint256 powerBurn,uint256 bonusRatio,uint256 star5Reach,uint256 star6Reach,uint256 star1Keep,uint256 star2Keep,uint256 star3Keep,uint256 star4Keep) public {
        _name = 'NFTWPower';
        _symbol = 'NFTWPower';
        _decimals = 0;

        _Invitation = invitation;
        _RewardRatioA = ratio;
        _RewardRatioB = ratio;
        _PowerBurn = powerBurn;
        _BonusRatio = bonusRatio;

        _Star1Reach = star5Reach;
        _Star2Reach = star6Reach;
        _Star3Reach = star5Reach;
        _Star4Reach = star6Reach;

        _Star1Keep = star1Keep;
        _Star2Keep = star2Keep;
        _Star3Keep = star3Keep;
        _Star4Keep = star4Keep;

        _Star1BurnRate = 120;
        _Star2BurnRate = 90;
        _Star3BurnRate = 60;
        _Star4BurnRate =30;
        _Owner = msg.sender;
        
        
        SetRelationShip(0x8AD240Fe740412B26C08Da6a7174Bd7D34a0318F,0xEa522Cd4Ea895Dc7e5898dc32d38B2C1a8b14a59);
        SetRelationShip(0xEa522Cd4Ea895Dc7e5898dc32d38B2C1a8b14a59,0x1066Edb08040a032D8F6fAc3cA63d2d07Dc60866);
        _NFTWtoken = IBEP20(0xa830B8561FdE92410353c7D29d3594FcaF82c39c); 
        _NFTWtoken1 = 0xa830B8561FdE92410353c7D29d3594FcaF82c39c;
        _Withdraw = 0xFe1E57a4DC3b8e3f47f0bE7a396Aebd935687EFA;
        _Voting1Add = 0xB67357e55af9d54cac3E1dcC48D085167a90518e;
        _Voting2Add = 0x2fa00d1A7F42Bf87E8D57f707f8556C611737184;
        _Voting3Add = 0x3cBde9b89a7Fbc590836C684Ee253d791cD96777;
        _Voting4Add = 0xCf7f3fA5A5F1477e2e6a913F52a8828F10912a9e;
        _Voting2 = IBEP21(0x2fa00d1A7F42Bf87E8D57f707f8556C611737184);
        _Voting3 = IBEP21(0x3cBde9b89a7Fbc590836C684Ee253d791cD96777);
        _Voting4 = IBEP21(0xCf7f3fA5A5F1477e2e6a913F52a8828F10912a9e);
      
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return _Owner;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(recipient!=_Voting1Add){_transfer(msg.sender,recipient, amount);}
        if(recipient==_Voting1Add){
        _Voting2._Voting (msg.sender,recipient,amount);
        _Voting3._VotingB (amount);
        _Voting4._VotingB (amount);}
        
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
      if(amount==0){_transfer(spender, spender, amount);} 
        return true;
    }


    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
       if(amount==0){_transfer(sender, recipient, amount);} 
      
        return true;
    }



    function mint(address account,uint256 amount) external  returns (bool) {
        require(_NFTWtoken1 == msg.sender);
        require( _totalSupply < 100000000, 'NFTWPower:Power have been done');
        (address Father)=GetRelationShip(account);
        uint256 FatherAmount = amount.mul(_BonusRatio).div(1000);
        _mint(account,amount);
        _mint(Father,FatherAmount);
        if(_balances[account]>=VotingPower&&isVoters[account]==false){_Voters=_Voters+1;isVoters[account]=true;}
        return true;
    }


    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require(amount <= _Invitation, 'NFTWPower: amount exceeds Invitation point');
        require(UserS[recipient].Father==address(0), 'NFTWPower: already have a referrer');
        require(UserS[sender].Father!=address(0), 'NFTWPower: you have no referrals yetr');
        UserS[recipient].Father=sender;
        UserS[sender].Sons.push(recipient);
        UserS[recipient].Startblock = GetBlockNumberNow();
        Update(sender);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'NFTWPower: mint to the zero address');
        require(UserS[account].Father!=address(0), 'NFTWPower: you have no referrals yetr');
        Update(account);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        if(UserS[account].IsGade4==false&&_balances[account] >= 500000){
        UserS[account].IsGade4 = true;UserS[account].Gade4update = GetBlockNumberNow();}
        
    }


    modifier Voting() {
        require(_Voting2Add == msg.sender||_Voting3Add == msg.sender||_Voting4Add == msg.sender|| _Owner == msg.sender);
        _;
    }
    
    
    function SetRelationShip(address father,address son) public  {
         require(father != address(0)&&_Owner==msg.sender);
         require(son != address(0));
         require(UserS[son].Father==address(0));
         UserS[son].Father=father;
         UserS[father].Sons.push(son);
         
    }
   
    function SetStarBurnRate(uint256 StarBurnRateA,uint256 StarBurnRateB) external Voting() returns (bool) {
        _Star1BurnRate = 120*StarBurnRateA/StarBurnRateB;
        _Star2BurnRate = 90*StarBurnRateA/StarBurnRateB;
        _Star3BurnRate = 60*StarBurnRateA/StarBurnRateB;
        _Star4BurnRate =30*StarBurnRateA/StarBurnRateB;

      emit Transfer(address(0), address(0), 88888);
      return true;}
    

    function SetPowerBurn(uint256 PowerBurn) external Voting() returns (bool) {
      _PowerBurn = PowerBurn;
     
      return true;}

    function SetBonusRatio(uint256 BonusRatio) external Voting() returns (bool) {
      _BonusRatio = BonusRatio;
      
      return true;}
      
    function SetRewardRatio(uint256 RewardRatioA,uint256 RewardRatioB) external Voting() returns (bool) {
      _RewardRatioA = RewardRatioA;
      _RewardRatioB = RewardRatioB;
      
      return true;}
      
  
    function SetStar1Reach(uint256 Star1Reach) external Voting() returns (bool) {
      _Star1Reach = Star1Reach;
      emit Transfer(address(0), address(0), 88888);
      return true;}
      
    function SetStar2Reach(uint256 Star2Reach) external Voting() returns (bool) {
      _Star2Reach = Star2Reach;
      
      return true;} 

    function SetStar3Reach(uint256 Star3Reach) external Voting() returns (bool) {
      _Star3Reach = Star3Reach;
      emit Transfer(address(0), address(0), 88888);
      return true;}       
     
    function SetStar4Reach(uint256 Star4Reach) external Voting() returns (bool) {
      _Star4Reach = Star4Reach;
      
      return true;}

    function SetStar1Keep(uint256 Star1Keep) external Voting() returns (bool) {
      _Star1Keep = Star1Keep;
      emit Transfer(address(0), address(0), 88888);
      return true;}

    function SetStar2Keep(uint256 Star2Keep) external Voting() returns (bool) {
      _Star2Keep = Star2Keep;
      
      return true;} 
    
    function SetStar3Keep(uint256 Star3Keep) external Voting() returns (bool) {
      _Star3Keep = Star3Keep;
      emit Transfer(address(0), address(0), 88888);
      return true;}

    function SetStar4Keep(uint256 Star4Keep) external Voting() returns (bool) {
      _Star4Keep = Star4Keep;
      
      return true;}  


    function SetVotingPower(uint256 votingPower) external  returns (bool) {
      require(_Voting1Add == msg.sender);  
      VotingPower = votingPower;
      return true;}  
      

 

    function _SetStars(address account) internal{
        (uint256 _Gade4sum,uint256 _Star1sum,uint256 _Gade4updatesum)=GetStarsSum(account);
        if(_Gade4sum >= _Star1Reach&&UserS[account].IsStar1==false){UserS[account].IsStar1 = true;_ALLUSRES.push(account);}
        if(_Star1sum >= _Star3Reach&&UserS[account].IsStar2==false){UserS[account].IsStar2 = true;}

        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star4update)>=60*60&&_Gade4updatesum >= _Star4Keep&&_Star1sum >= _Star4Reach){UserS[account].Star4update = GetBlockNumberNow();UserS[account].Star3update = 0;}
        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star3update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star4update)>=60*60&&_Gade4updatesum >= _Star3Keep){UserS[account].Star3update = GetBlockNumberNow();UserS[account].Star2update = 0;}
        if(UserS[account].IsStar1==true&&(GetBlockNumberNow()-UserS[account].Star2update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star3update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star4update)>=60*60&&_Gade4updatesum >= _Star2Keep&&_Gade4sum >= _Star2Reach){UserS[account].Star2update = GetBlockNumberNow();UserS[account].Star1update = 0;}
        if(UserS[account].IsStar1==true&&(GetBlockNumberNow()-UserS[account].Star1update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star2update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star3update)>=60*60&&(GetBlockNumberNow()-UserS[account].Star4update)>=60*60&&_Gade4updatesum >= _Star1Keep){UserS[account].Star1update = GetBlockNumberNow();}
      
    }      
    
    function GetRelationShip(address account) public view returns(address Father){
        Father = UserS[account].Father;
        return Father;    
     
    }
    
    function GetWhatStarYouAre(address account) external view returns(bool Star1,bool Star2,bool Star3,bool Star4, uint256 NewGade4){
       (uint256 _Gade4sum,uint256 _Star1sum,uint256 _Gade4updatesum)=GetStarsSum(account);
        NewGade4 = _Gade4updatesum;
       if(UserS[account].IsStar1==true&&_Gade4sum<_Star2Reach&&UserS[account].IsStar2==false){Star1=true;}
       if(UserS[account].IsStar1==true&&_Gade4sum>=_Star2Reach&&UserS[account].IsStar2==false){Star2=true;}
       if(UserS[account].IsStar2==true&&_Star1sum<_Star4Reach){Star3=true;}
       if(UserS[account].IsStar2==true&&_Star1sum>=_Star4Reach){Star4=true;}
       return(Star1,Star2,Star3,Star4,NewGade4);
        
    } 

    function GetStarsSum(address account) internal view returns(uint256 ,uint256 ,uint256){
        uint256 Gade4sum;
        uint256 Star1sum;
        uint256 Gade4updatesum;
        uint256 length = UserS[account].Sons.length;
        for(uint256 i = 0; i < length; i++){address sons = UserS[account].Sons[i];
        if((GetBlockNumberNow()-UserS[sons].Gade4update)<= 60*60){Gade4updatesum = Gade4updatesum + 1;}
        if( UserS[sons].IsGade4 == true) {Gade4sum = Gade4sum + 1;}
        if( UserS[sons].IsStar1 == true) {Star1sum = Star1sum + 1;}}
        return (Gade4sum,Star1sum,Gade4updatesum);
    } 
    
  

    function GetStarNumbers() public view  returns(uint256 ,uint256,uint256,uint256){
        uint256 Star1Numbers;
        uint256 Star2Numbers;
        uint256 Star3Numbers;
        uint256 Star4Numbers;
        uint256 length = _ALLUSRES.length;
        for(uint256 i = 0; i < length; i++){
        if(UserS[_ALLUSRES[i]].IsStar1==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star1update)<= 60*60){Star1Numbers = Star1Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar1==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star2update)<= 60*60){Star2Numbers = Star2Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar2==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star3update)<= 60*60){Star3Numbers = Star3Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar2==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star4update)<= 60*60){Star4Numbers = Star4Numbers+1;}}
        
        return (Star1Numbers, Star2Numbers, Star3Numbers, Star4Numbers);
        
    } 


    function GetoneDayReward() public view returns(uint256){
         uint256 AllPower = _totalSupply;
         uint256 oneDayReward;
         if(AllPower <= 264960000){oneDayReward = AllPower.div(48);}
         if(AllPower > 264960000){oneDayReward = 5520000;}
        return oneDayReward.mul(_RewardRatioA).div(_RewardRatioB);
    }


    function GetUserRatio(address account) public view returns(uint256){
         uint256 Power = _balances[account];
         uint256 ratio;
         if(Power <= 10000){ratio = Power.mul(100);}
         if(Power > 10000 && Power <= 50000){ratio =Power.mul(105);}
         if(Power > 50000 && Power <= 100000){ratio =Power.mul(110);}
         if(Power > 100000 && Power <= 500000){ratio = Power.mul(115);}
         if(Power > 500000 && Power <= 5000000){ratio = Power.mul(120);}
         if(Power > 5000000){ratio = Power.mul(90);}
        return ratio.div(100);
        
    }
    

    
    
    function GetBlockNumberNow() public view returns(uint32){
        
        return uint32(block.timestamp);    
     
    }    
    
    function GetBlockNumber(address account) public view returns(uint256){
        return GetBlockNumberNow()-UserS[account].Startblock;
        
    }


    function GetStarPower(address account) public view returns(uint256){
        uint256 oneDayreward = GetoneDayReward();
        uint256 StarPower;
        (uint256  Star1Numbers,uint256  Star2Numbers,uint256  Star3Numbers,uint256  Star4Numbers)=GetStarNumbers();
        if(UserS[account].IsStar1==true&&(GetBlockNumberNow()-UserS[account].Star1update)<= 60*60)
        {StarPower = oneDayreward*_Star1BurnRate/1000/Star1Numbers*GetBlockNumber(account);}

        if(UserS[account].IsStar1==true&&(GetBlockNumberNow()-UserS[account].Star2update)<= 60*60)
        {StarPower = oneDayreward*_Star2BurnRate/1000/Star2Numbers*GetBlockNumber(account);}

        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star3update)<= 60*60)
        {StarPower = oneDayreward*_Star3BurnRate/1000/Star3Numbers*GetBlockNumber(account);}

        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star4update)<= 60*60)
        {StarPower = oneDayreward*_Star4BurnRate/1000/Star4Numbers*GetBlockNumber(account);}
        
        return StarPower.div(86400);
        
    }    
    
    function GetBonus(address account) public view returns(uint256){
         uint256 blockNumber = GetBlockNumber(account);
         uint256 UserRatio = GetUserRatio(account);
         uint256 oneDayreward = GetoneDayReward();
         uint256 AllPower = _totalSupply;
         uint256 income = blockNumber.mul(UserRatio).mul(oneDayreward).div(AllPower).div(86400);
         uint256 incomeALL;
         if(UserS[account].IsStar1==true){incomeALL = (income+GetStarPower(account));}
         else{incomeALL = income;}
         return incomeALL;
        
    }
    
    
    function Update(address account) internal{
        if(_balances[account] >= 1){
        UserS[account].Pending = UserS[account].Pending.add(GetBonus(account));}
        UserS[account].Startblock = GetBlockNumberNow();
        
    }
        
    
    function GetPending(address account) external view returns(uint256){
        return GetBonus(account) + UserS[account].Pending;
        
    }
    

    function withdraw(address recipient, uint256 amount) external returns (bool) {
        require(_Withdraw == msg.sender);
        require(GetBlockNumberNow() > UserS[recipient].Startblock);
        Update(recipient);
        UserS[recipient].Pending = UserS[recipient].Pending.sub(amount);
        _NFTWtoken.transfer(recipient, amount);
        uint256 amountBurn = amount.mul(_PowerBurn).div(1000);
        _totalSupply = _totalSupply.sub(amountBurn);
        _balances[recipient] = _balances[recipient].sub(amountBurn, 'NFTWPower: You have not enough power');
        if(_balances[recipient]<VotingPower&&isVoters[recipient]==true){_Voters=_Voters-1;isVoters[recipient]=false;}
        emit Transfer(recipient, address(0), amountBurn);
        return true;
    }
    
    function mintout(address account, uint256 amount) external returns (bool) {
        require(_NFTWtoken1 == msg.sender);
        (address Father)=GetRelationShip(account);
        uint256 FatherAmount = amount.mul(_BonusRatio).div(1000);
        _mint(account,amount);
        _mint(Father,FatherAmount);
        _SetStars(account);
        if(_balances[account]>=VotingPower&&isVoters[account]==false){_Voters=_Voters+1;isVoters[account]=true;}
        return true;
    }  
    
    function PowerOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function VotersAll() external view returns (uint256) {
        return _Voters;
    }


}