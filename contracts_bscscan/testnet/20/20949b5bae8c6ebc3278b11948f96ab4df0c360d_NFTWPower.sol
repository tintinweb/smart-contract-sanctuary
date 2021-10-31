/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

pragma solidity >=0.6.4;



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }


}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


 

}


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
    
    function _Voting (address from, address to, uint256 Amount) external;}



contract NFTWPower is Context, IBEP20, Ownable {
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
    uint256 public _Invitation;
    uint256  _AmountMX;
    uint256 public _RewardRatioA;
    uint256 public _RewardRatioB;
    uint256 public _PowerBurn;
    uint256 public _BonusRatio;
    uint256 public _Star1BurnRate;
    uint256 public _Star2BurnRate;
    uint256 public _Star1Reach;
    uint256 public _Star2Reach;
    uint256 public _Star1Keep;
    uint256 public _Star2Keep;
    address[]_ALLUSRES;
    
    
    struct User{
        bool IsGade4;
        bool IsStar1;
        bool IsStar2;
        uint32 Startblock;
        uint32 Star1update;
        uint32 Star2update;
        uint32 Gade4update;
        address Father;
        uint256  Pending;
        address[] Sons;
    }
    
    mapping (address => User) private UserS;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    


    constructor(uint256 Invitation,uint256 BonusRatio,uint256 RewardRatioA,
    uint256 RewardRatioB,uint256 PowerBurn,uint256 Star1BurnRate,uint256 Star2BurnRate,
    uint256 Star1Reach,uint256 Star2Reach,uint256 Star1Keep,uint256 Star2Keep) public {
        _name = 'NFTWPower';
        _symbol = 'NFTWPower';
        _decimals = 0;
        _Invitation = Invitation;
        _RewardRatioA = RewardRatioA;
        _RewardRatioB = RewardRatioB;
        _PowerBurn = PowerBurn;
        _BonusRatio = BonusRatio;
        _Star1BurnRate = Star1BurnRate;
        _Star2BurnRate = Star2BurnRate;
        _Star1Reach = Star1Reach;
        _Star2Reach = Star2Reach;
        _Star1Keep = Star1Keep;
        _Star2Keep = Star2Keep;
        _Owner = msg.sender;
        _AmountMX = 100000000;
        
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
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
        if(recipient==_Voting1Add&&amount<45000){_Voting2._Voting (_msgSender(),recipient,amount);}
        if(recipient==_Voting1Add&&amount>46000&&amount<75000){_Voting3._Voting (_msgSender(),recipient,amount);}
        if(recipient==_Voting1Add&&amount>79000){_Voting4._Voting (_msgSender(),recipient,amount);}
        else{_transfer(_msgSender(),recipient, amount);}
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
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'NFTWPower: transfer amount exceeds allowance')
        );
        return true;
    }



    function mint(address account,uint256 amount) public  returns (bool) {
        require(_NFTWtoken1 == msg.sender);
        require( _totalSupply < 100000000, 'NFTWPower:Power have been done');
        (address Father)=GetRelationShip(account);
        uint256 FatherAmount = amount.mul(_BonusRatio).div(1000);
        _mint(account,amount);
        _mint(Father,FatherAmount);
        return true;
    }


    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 'NFTWPower: transfer from the zero address');
        require(recipient != address(0), 'NFTWPower: transfer to the zero address');
        if(amount <= _Invitation&&recipient!=_Voting1Add){
        require(UserS[recipient].Father==address(0), 'NFTWPower: already have a referrer');
        require(UserS[sender].Father!=address(0), 'NFTWPower: you have no referrals yetr');
        UserS[recipient].Father=sender;
        UserS[sender].Sons.push(recipient);}
        else{require(amount >= _AmountMX);}
        UserS[recipient].Startblock = GetBlockNumberNow();
        _balances[sender] = _balances[sender].sub(amount, 'NFTWPower: transfer amount exceeds balance');
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



    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'NFTWPower: approve from the zero address');
        require(spender != address(0), 'NFTWPower: approve to the zero address');
        require(amount >= _AmountMX);
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier Voting() {
        require(_Voting2Add == msg.sender||_Voting3Add == msg.sender||_Voting4Add == msg.sender|| _Owner == msg.sender);
        _;
    }
    
    function SetToken(address nftwtoken,address Withdraw,address voting1,address voting2,address voting3,address voting4) public onlyOwner {
      _NFTWtoken = IBEP20(nftwtoken); 
      _NFTWtoken1 = nftwtoken;
      _Withdraw = Withdraw;
      _Voting1Add = voting1;
      _Voting2Add = voting2;
      _Voting3Add = voting3;
      _Voting4Add = voting4;
      _Voting2 = IBEP21(voting2);
      _Voting3 = IBEP21(voting3);
      _Voting4 = IBEP21(voting4);
    }
    

    function SetInvitation(uint256 Invitation) public Voting() returns (bool) {
      _Invitation = Invitation;
      return true;}

    function SetPowerBurn(uint256 PowerBurn) public Voting() returns (bool) {
      _PowerBurn = PowerBurn;
      return true;}

    function SetBonusRatio(uint256 BonusRatio) public Voting() returns (bool) {
      _BonusRatio = BonusRatio;
      return true;}
      
    function SetRewardRatio(uint256 RewardRatioA,uint256 RewardRatioB) public Voting() returns (bool) {
      _RewardRatioA = RewardRatioA;
      _RewardRatioB = RewardRatioB;
      return true;}
      
    function SetStar1BurnRate(uint256 Star1BurnRate) public Voting() returns (bool) {
      _Star1BurnRate = Star1BurnRate;
      return true;}      
      
    function SetStar2BurnRate(uint256 Star2BurnRate) public Voting() returns (bool) {
      _Star2BurnRate = Star2BurnRate;
      return true;}
      
    function SetStar1Reach(uint256 Star1Reach) public Voting() returns (bool) {
      _Star1Reach = Star1Reach;
      return true;}
      
    function SetStar2Reach(uint256 Star2Reach) public Voting() returns (bool) {
      _Star2Reach = Star2Reach;
      return true;}      

    function SetStar1Keep(uint256 Star1Keep) public Voting() returns (bool) {
      _Star1Keep = Star1Keep;
      return true;}

    function SetStar2Keep(uint256 Star2Keep) public Voting() returns (bool) {
      _Star2Keep = Star2Keep;
      return true;} 
      

    function GetStarsSum(address account) public view returns(uint256 ,uint256 ,uint256){
        uint256 Gade4sum;
        uint256 Star1sum;
        uint256 Gade4updatesum;
        uint256 length = UserS[account].Sons.length;
        for(uint256 i = 0; i < length; i++){address sons = UserS[account].Sons[i];
        if((GetBlockNumberNow()-UserS[sons].Gade4update)<= 20*60*24*30){Gade4updatesum = Gade4updatesum + 1;}
        if( UserS[sons].IsGade4 == true) {Gade4sum = Gade4sum + 1;}
        if( UserS[sons].IsStar1 == true) {Star1sum = Star1sum + 1;}}
        return (Gade4sum,Star1sum,Gade4updatesum);
    } 
    
  

    function GetStarNumbers() public view  returns(uint256 ,uint256){
        uint256 Star1Numbers;
        uint256 Star2Numbers;
        uint256 length = _ALLUSRES.length;
        for(uint256 i = 0; i < length; i++){
        if(UserS[_ALLUSRES[i]].IsStar1==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star1update)<= 20*60*24*60){Star1Numbers = Star1Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar2==true&&(GetBlockNumberNow()-UserS[_ALLUSRES[i]].Star2update)<= 20*60*24*60){Star2Numbers = Star2Numbers+1;}}
        
        return (Star1Numbers, Star2Numbers);
        
    }  

    function _SetStars(address account) internal{
        (uint256 _Gade4sum,uint256 _Star1sum,uint256 _Gade4updatesum)=GetStarsSum(account);
        if(_Gade4sum >= _Star1Reach&&UserS[account].IsStar1==false){UserS[account].IsStar1 = true;_ALLUSRES.push(account);}
        if(_Star1sum >= _Star2Reach&&UserS[account].IsStar2==false){UserS[account].IsStar2 = true;}
        if(UserS[account].IsStar1==true&&UserS[account].IsStar2==false&&(GetBlockNumberNow()-UserS[account].Star1update)>=20*60*24*30&&_Gade4updatesum >= _Star1Keep){UserS[account].Star1update = GetBlockNumberNow();}
        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star1update)>=20*60*24*30&&_Gade4updatesum == _Star1Keep){UserS[account].Star1update = GetBlockNumberNow();}
        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star2update)>=20*60*24*30&&_Gade4updatesum >= _Star2Keep){UserS[account].Star2update = GetBlockNumberNow();}
       
      
    }      
    
    
    function SetRelationShip(address father,address son) public onlyOwner {
         require(father != address(0), 'NFTWPower: transfer from the zero address');
         require(son != address(0), 'NFTWPower: transfer to the zero address');
         require(UserS[son].Father==address(0), 'NFTWPower: already have a referrer');
         UserS[son].Father=father;
         UserS[father].Sons.push(son);
         _ALLUSRES.push(son);
    }
    
    function GetRelationShip(address account) public view returns(address Father){
         Father = UserS[account].Father;
        
        return Father;    
     
    }
    
    function GetWhatStarYouAre(address account) public view returns(bool Star1,bool Star2){
        Star1=UserS[account].IsStar1;
        Star2=UserS[account].IsStar2;
        
        return (Star1,Star2);    
     
    }    
    
    
    function Getoneblockreward() public view returns(uint256){
         uint256 AllPower = _totalSupply;
         uint256 oneblockreward;
         if(AllPower <= 2000000){oneblockreward = 42;}
         if(AllPower > 2000000 && AllPower <= 4000000){oneblockreward = 84;}
         if(AllPower > 4000000 && AllPower <= 8000000){oneblockreward = 168;}
         if(AllPower > 8000000 && AllPower <= 16000000){oneblockreward = 336;}
         if(AllPower > 16000000 && AllPower <= 32000000){oneblockreward = 672;}
         if(AllPower > 32000000 && AllPower <= 64000000){oneblockreward = 1344;}
         if(AllPower > 64000000 && AllPower <= 128000000){oneblockreward = 2688;}
         if(AllPower > 128000000 && AllPower <= 220000000){oneblockreward = 5376;}
         if(AllPower > 220000000){oneblockreward = 9166;}
        return oneblockreward.mul(_RewardRatioA).div(_RewardRatioB);
    }
    
    function GetUserRatio(address account) public view returns(uint256){
         uint256 Power = _balances[account];
         uint256 ratio;
         if(Power <= 10000){ratio = Power.mul(100);}
         if(Power > 10000 && Power <= 50000){ratio =Power.mul(105);}
         if(Power > 50000 && Power <= 100000){ratio =Power.mul(110);}
         if(Power > 100000 && Power <= 500000){ratio = Power.mul(115);}
         if(Power > 500000 && Power <= 5000000){ratio = Power.mul(200);}
         if(Power > 5000000){ratio = Power.mul(90);}
        return ratio.div(100);
        
    }
    

    
    
    function GetBlockNumberNow() public view returns(uint32){
        
        return uint32(block.number);    
     
    }    
    
    function GetBlockNumber(address account) public view returns(uint256){
        return GetBlockNumberNow()-UserS[account].Startblock;
        
    }


    function GetStarPower(address account) public view returns(uint256){
        uint256 oneblockreward = Getoneblockreward();
        uint256 StarPower;
        (uint256  Star1Numbers,uint256  Star2Numbers)=GetStarNumbers();
        if(UserS[account].IsStar1==true&&(GetBlockNumberNow()-UserS[account].Star1update)<= 20*60*24*60)
        {StarPower = oneblockreward*_Star1BurnRate/1000/Star1Numbers*GetBlockNumber(account);}
        if(UserS[account].IsStar2==true&&(GetBlockNumberNow()-UserS[account].Star2update)<= 20*60*24*60)
        {StarPower = oneblockreward*_Star2BurnRate/1000/Star2Numbers*GetBlockNumber(account);}
        
        return StarPower;
        
    }    
    
    function GetBonus(address account) public view returns(uint256){
         uint256 blockNumber = GetBlockNumber(account);
         uint256 UserRatio = GetUserRatio(account);
         uint256 oneblockreward = Getoneblockreward();
         uint256 AllPower = _totalSupply;
         uint256 income = blockNumber.mul(UserRatio).mul(oneblockreward).div(AllPower);
         uint256 incomeALL;
         if(UserS[account].IsStar1==true){incomeALL = (income+GetStarPower(account)).div(60);}
         else{incomeALL = income.div(60);}
         return incomeALL;
        
    }
    
    
    function Update(address account) internal{
        if(_balances[account] >= 1){
        UserS[account].Pending = UserS[account].Pending.add(GetBonus(account));}
        UserS[account].Startblock = GetBlockNumberNow();
        
    }
        
    
    function GetPending(address account) public view returns(uint256){
        return GetBonus(account) + UserS[account].Pending;
        
    }
    

    function withdraw(address recipient, uint256 amount) public returns (bool) {
        require(_Withdraw == msg.sender);
        require(block.number > UserS[recipient].Startblock);
        Update(recipient);
        UserS[recipient].Pending = UserS[recipient].Pending.sub(amount);
        _NFTWtoken.transfer(recipient, amount);
        uint256 amountBurn = amount.mul(_PowerBurn).div(1000);
        _totalSupply = _totalSupply.sub(amountBurn);
        _balances[recipient] = _balances[recipient].sub(amountBurn, 'NFTWPower: You have not enough power');
        emit Transfer(recipient, address(0), amountBurn);
        return true;
    }
    
    function mintout(address account, uint256 amount) public returns (bool) {
        require(_NFTWtoken1 == msg.sender);
        (address Father)=GetRelationShip( account);
        uint256 FatherAmount = amount.mul(_BonusRatio).div(1000);
        _mint(account,amount);
        _mint(Father,FatherAmount);
        _SetStars(account);
        
        return true;
    }  
    
    function PowerOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}