/**
 *Submitted for verification at BscScan.com on 2021-10-16
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
    
    function _Approve(address owner, address spender, uint256 amount)  external;}



contract NFTWPower is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8  private _decimals;
    
    IBEP21   _NFTWtoken1;
    IBEP20   _NFTWtoken; 
    address  _Withdraw;
    address[]_ALLUSRES;
    
    uint256  _Invitation;
    uint256  _AmountMX;
    uint256  _RewardRatioA;
    uint256  _RewardRatioB;
    uint256  _Star1Power;
    uint256  _Star2Power;
    uint256  _Star3Power;
    uint256  _Star4Power;
    
    struct User{
        address Father;
        address[] Sons;
        uint256 Startblock;
        uint256  Pending;
        bool IsGade4;
        bool IsStar1;
        bool IsStar2;
        bool IsStar3;
        bool IsStar4;
        uint256 Star1update;
        uint256 Star2update;
        uint256 Star3update;
        uint256 Star4update;
        uint256 Gade4update;
    }
    
    mapping (address => User) private UserS;
    
    
    


    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 0;
        _Invitation = 1000;
        _AmountMX = 1000000000000000000000;
        _RewardRatioA = 1000;
        _RewardRatioB = 1000;
        _Star1Power = 120;
        _Star2Power = 90;
        _Star3Power = 60;
        _Star4Power = 30;
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
        if(recipient == address(0)){
        _NFTWtoken1._Approve(msg.sender, address(this), amount);    
        _NFTWtoken.transferFrom (msg.sender, recipient, amount);
        
        (address Father,address Grandpa)=GetRelationShip(msg.sender);
        uint256 FatherAmount = amount.mul(70).div(1000);
        uint256 GrandpaAmount = amount.mul(30).div(1000);
       
        Update(msg.sender);
        _mint(msg.sender,amount);
        emit Transfer(address(0), msg.sender, amount);
        Update(Father);
         _mint(Father,FatherAmount);
        emit Transfer(address(0),Father, FatherAmount);
         Update(Grandpa);
        _mint(Grandpa,GrandpaAmount);
        emit Transfer(address(0),Grandpa, GrandpaAmount);}
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


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'NFTWPower: decreased allowance below zero'));
        return true;
    }


    function mint(address account,uint256 amount) public onlyOwner returns (bool) {
        (address Father,address Grandpa)=GetRelationShip(account);
        uint256 FatherAmount = amount.mul(70).div(1000);
        uint256 GrandpaAmount = amount.mul(30).div(1000);
        Update(account);
        _mint(account,amount);
        emit Transfer(address(0), account, amount);
        Update(Father);
        _mint(Father,FatherAmount);
        emit Transfer(address(0),Father, FatherAmount);
        Update(Grandpa);
        _mint(Grandpa,GrandpaAmount);
        emit Transfer(address(0),Grandpa, GrandpaAmount);
        return true;
    }


    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 'NFTWPower: transfer from the zero address');
        require(recipient != address(0), 'NFTWPower: transfer to the zero address');
        if(amount <= _Invitation){
        require(UserS[recipient].Father==address(0), 'NFTWPower: already have a referrer');
        require(UserS[sender].Father!=address(0), 'NFTWPower: you have no referrals yetr');
        UserS[recipient].Father=sender;
        UserS[sender].Sons.push(recipient);}
        else{require(amount >= _AmountMX);}
        _ALLUSRES.push(recipient);
        UserS[recipient].Startblock = block.number;
        Update(sender);
        _balances[sender] = _balances[sender].sub(amount, 'NFTWPower: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'NFTWPower: mint to the zero address');
        require(UserS[account].Father!=address(0), 'NFTWPower: you have no referrals yetr');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        _SetStars(account);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'NFTWPower: burn from the zero address');
        _balances[account] = _balances[account].sub(amount, 'NFTWPower: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'NFTWPower: approve from the zero address');
        require(spender != address(0), 'NFTWPower: approve to the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
    
   
    
    function SetToken(address nftwtoken,address Withdraw) public onlyOwner {
      _NFTWtoken = IBEP20(nftwtoken); 
      _NFTWtoken1 = IBEP21(nftwtoken);
      _Withdraw = Withdraw;
    }
    
    
    function SetRewardRatio(uint256 RewardRatioA,uint256 RewardRatioB) public onlyOwner {
      _RewardRatioA = RewardRatioA;
      _RewardRatioB = RewardRatioB; 
    }
     
    
    function SetAmount(uint256 Invitation,uint256 AmountMX) public onlyOwner {
      _Invitation = Invitation; 
      _AmountMX = AmountMX;
   
    }
    
    function SetStarPower(uint256 Star1Power,uint256 Star2Power,uint256 Star3Power,uint256 Star4Power) public onlyOwner {
      _Star1Power = Star1Power; 
      _Star2Power = Star2Power;
      _Star3Power = Star3Power;
      _Star4Power = Star4Power;
    }
    
    
    function _SetStars(address account) internal{
        address sons;
        uint256 Gade4sum;
        uint256 Star1sum;
        uint256 Star2sum;
        uint256 Star3sum;
        uint256 Gade4updatesum;
        
        if(_balances[account] >= 500000){UserS[account].IsGade4 = true;UserS[account].Gade4update = block.number;}
        
        for(uint i = 0; i < UserS[account].Sons.length; i++){sons = UserS[account].Sons[i];
        if((block.number-UserS[sons].Gade4update)<= 20*24*30){Gade4updatesum = Gade4updatesum + 1;}
        if( UserS[sons].IsGade4 == true) {Gade4sum = Gade4sum + 1;}
        if( UserS[sons].IsStar1 == true) {Star1sum = Star1sum + 1;}
        if( UserS[sons].IsStar2 == true) {Star2sum = Star2sum + 1;}
        if( UserS[sons].IsStar3 == true) {Star3sum = Star3sum + 1;}}
        
        if(Gade4sum >= 5){UserS[account].IsStar1 = true;}
        if(Star1sum >= 3){UserS[account].IsStar2 = true;}
        if(Star2sum >= 3){UserS[account].IsStar3 = true;}
        if(Star3sum >= 3){UserS[account].IsStar4 = true;}
        
        
        if(UserS[account].IsStar1==true&&Gade4updatesum >= 1){UserS[account].Star1update = block.number;}
        
        if(UserS[account].IsStar2==true&&Gade4updatesum == 1){UserS[account].Star1update = block.number;}
        if(UserS[account].IsStar2==true&&Gade4updatesum >= 2){UserS[account].Star2update = block.number;}
        
        if(UserS[account].IsStar3==true&&Gade4updatesum == 1){UserS[account].Star1update = block.number;}
        if(UserS[account].IsStar3==true&&Gade4updatesum == 2){UserS[account].Star2update = block.number;}
        if(UserS[account].IsStar3==true&&Gade4updatesum >= 3){UserS[account].Star3update = block.number;}
        
        if(UserS[account].IsStar4==true&&Gade4updatesum == 1){UserS[account].Star1update = block.number;}
        if(UserS[account].IsStar4==true&&Gade4updatesum == 2){UserS[account].Star2update = block.number;}
        if(UserS[account].IsStar4==true&&Gade4updatesum == 3){UserS[account].Star3update = block.number;}
        if(UserS[account].IsStar4==true&&Gade4updatesum >= 4){UserS[account].Star4update = block.number;}
    }      
    
    
    function SetRelationShip(address father,address son) public onlyOwner {
         require(father != address(0), 'NFTWPower: transfer from the zero address');
         require(son != address(0), 'NFTWPower: transfer to the zero address');
         require(UserS[son].Father==address(0), 'NFTWPower: already have a referrer');
         UserS[son].Father=father;
         UserS[father].Sons.push(son);
         _ALLUSRES.push(son);
    }
    
    function GetRelationShip(address account) public view returns(address Father,address Grandpa){
         Father = UserS[account].Father;
         Grandpa = UserS[Father].Father;
        return (Father,Grandpa);    
     
    }
    
    function GetWhatStarYouAre(address account) public view returns(bool Star1,bool Star2,bool Star3,bool Star4){
        Star1=UserS[account].IsStar1;
        Star2=UserS[account].IsStar2;
        Star3=UserS[account].IsStar3;
        Star4=UserS[account].IsStar4;
        return (Star1,Star2,Star3,Star4);    
     
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
         if(Power <= 10000){ratio = Power.mul(120);}
         if(Power > 10000 && Power <= 50000){ratio =Power.mul(140);}
         if(Power > 50000 && Power <= 100000){ratio =Power.mul(160);}
         if(Power > 100000 && Power <= 500000){ratio = Power.mul(180);}
         if(Power > 500000 && Power <= 1000000){ratio = Power.mul(200);}
         if(Power > 1000000){ratio = Power.mul(100);}
        return ratio.div(100);
        
    }
    
    function GetAllPower() public view returns(uint256){
        uint256 AllPower;
        for(uint i = 0; i < _ALLUSRES.length; i++){AllPower = AllPower.add(GetUserRatio(_ALLUSRES[i]));}
        
        return AllPower;
    } 
    
    
    function GetBlockNumber(address account) public view returns(uint256){
         uint256 startblock = UserS[account].Startblock;
         uint256 BlockNumber = block.number;
        return BlockNumber.sub(startblock);
        
    }
    

    function GetStarNumbers() public view returns(uint256 Star1Numbers,uint256 Star2Numbers,uint256 Star3Numbers,uint256 Star4Numbers){
        for(uint i = 0; i < _ALLUSRES.length; i++){
        if(UserS[_ALLUSRES[i]].IsStar1==true&&(block.number-UserS[_ALLUSRES[i]].Star1update)<= 20*24*30){Star1Numbers = Star1Numbers+1;}
        
        if(UserS[_ALLUSRES[i]].IsStar2==true&&(block.number-UserS[_ALLUSRES[i]].Star1update)<= 20*24*30){Star2Numbers = Star1Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar2==true&&(block.number-UserS[_ALLUSRES[i]].Star2update)<= 20*24*30){Star2Numbers = Star2Numbers+1;}
        
        
        if(UserS[_ALLUSRES[i]].IsStar3==true&&(block.number-UserS[_ALLUSRES[i]].Star1update)<= 20*24*30){Star3Numbers = Star1Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar3==true&&(block.number-UserS[_ALLUSRES[i]].Star2update)<= 20*24*30){Star3Numbers = Star2Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar3==true&&(block.number-UserS[_ALLUSRES[i]].Star3update)<= 20*24*30){Star3Numbers = Star3Numbers+1;}
        
        if(UserS[_ALLUSRES[i]].IsStar4==true&&(block.number-UserS[_ALLUSRES[i]].Star1update)<= 20*24*30){Star4Numbers = Star1Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar4==true&&(block.number-UserS[_ALLUSRES[i]].Star2update)<= 20*24*30){Star4Numbers = Star2Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar4==true&&(block.number-UserS[_ALLUSRES[i]].Star3update)<= 20*24*30){Star4Numbers = Star3Numbers+1;}
        if(UserS[_ALLUSRES[i]].IsStar4==true&&(block.number-UserS[_ALLUSRES[i]].Star4update)<= 20*24*30){Star4Numbers = Star4Numbers+1;}}
        
        
        return (Star1Numbers,Star2Numbers,Star3Numbers,Star4Numbers);
        
    }    

    
    function GetStarPower(address account) public view returns(uint256){
        uint256 oneblockreward = Getoneblockreward();
        uint256 StarPower;
        (uint256 Star1Numbers,uint256 Star2Numbers,uint256 Star3Numbers,uint256 Star4Numbers)=GetStarNumbers();
         if(UserS[account].IsStar1==true&&(block.number-UserS[account].Star1update)<= 20*24*30)
        {StarPower = oneblockreward*_Star1Power/1000/Star1Numbers*(block.number-UserS[account].Star1update);}
        
         if(UserS[account].IsStar2==true&&(block.number-UserS[account].Star1update)<= 20*24*3)
        {StarPower = oneblockreward*_Star1Power/1000/Star1Numbers*(block.number-UserS[account].Star1update);}
         if(UserS[account].IsStar2==true&&(block.number-UserS[account].Star2update)<= 20*24*30)
        {StarPower = oneblockreward*_Star2Power/1000/Star2Numbers*(block.number-UserS[account].Star2update);}

         if(UserS[account].IsStar3==true&&(block.number-UserS[account].Star1update)<= 20*24*30)
        {StarPower = oneblockreward*_Star1Power/1000/Star1Numbers*(block.number-UserS[account].Star1update);}
         if(UserS[account].IsStar3==true&&(block.number-UserS[account].Star2update)<= 20*24*30)
        {StarPower = oneblockreward*_Star2Power/1000/Star2Numbers*(block.number-UserS[account].Star2update);}
         if(UserS[account].IsStar3==true&&(block.number-UserS[account].Star3update)<= 20*24*30)
        {StarPower = oneblockreward*_Star3Power/1000/Star3Numbers*(block.number-UserS[account].Star3update);}

         if(UserS[account].IsStar4==true&&(block.number-UserS[account].Star1update)<= 20*24*30)
        {StarPower = oneblockreward*_Star1Power/1000/Star1Numbers*(block.number-UserS[account].Star1update);}
         if(UserS[account].IsStar4==true&&(block.number-UserS[account].Star2update)<= 20*24*30)
        {StarPower = oneblockreward*_Star2Power/1000/Star2Numbers*(block.number-UserS[account].Star2update);}
         if(UserS[account].IsStar4==true&&(block.number-UserS[account].Star3update)<= 20*24*30)
        {StarPower = oneblockreward*_Star3Power/1000/Star3Numbers*(block.number-UserS[account].Star3update);}
         if(UserS[account].IsStar4==true&&(block.number-UserS[account].Star4update)<= 20*24*30)
        {StarPower = oneblockreward*_Star4Power/1000/Star4Numbers*(block.number-UserS[account].Star4update);}
        
         
        return StarPower;
        
    }    
    
    function GetBonus(address account) public view returns(uint256){
         uint256 blockNumber = GetBlockNumber(account);
         uint256 UserRatio =GetUserRatio(account);
         uint256 oneblockreward = Getoneblockreward();
         uint256 AllPower = GetAllPower();
         uint256 income;
         if(UserS[account].IsStar1==true){uint256 StarPower = GetStarPower(account);
         income = blockNumber.mul(UserRatio).mul(oneblockreward).div(AllPower)+StarPower;}
         else{income = blockNumber.mul(UserRatio).mul(oneblockreward).div(AllPower);}
         
         return income;
        
    }    
    
 
    
    function GetPending(address account) public view returns(uint256){
        return GetBonus(account) + UserS[account].Pending;
        
    }
    
    
    function Update(address account) internal{
        if(_balances[account] >= 1){
        UserS[account].Pending = UserS[account].Pending.add(GetBonus(account));}
        UserS[account].Startblock = block.number;}
    


    function withdraw(address recipient, uint256 amount) public  returns (bool) {
        require(_Withdraw == msg.sender);
        require(block.number > UserS[recipient].Startblock);
        Update(recipient);
        if(UserS[recipient].IsStar1==true){_SetStars(recipient);}
        UserS[recipient].Pending = UserS[recipient].Pending.sub(amount);
        _NFTWtoken.transfer(recipient, amount);
        
        return true;
    }
}