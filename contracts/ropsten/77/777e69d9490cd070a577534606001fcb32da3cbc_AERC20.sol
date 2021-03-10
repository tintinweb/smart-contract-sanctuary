/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.5.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}






contract AERC20 is IERC20  {


    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public _limitICO; // limit for faucet and mining
    uint256 private _coinbase; // profit from mining per member
    uint256 private _bigbonuslim;  //
    uint256 public _bonusWins;
    uint256 public _kingsize; // the royal size of penis
    uint256 public _micropenis;    
    uint256 public _ratioInchPerEther;  //price for buy 
    uint256 public _minWei; // the minimal wei in address to consider it real. For mining 
    
    uint256 public _LastRecordSet;  // sets by func IhaveTheBiggestDick. For big bonus  
    address public _theBiggestDick; // arddress of the biggest dick
    string public _MessageFromBigDick; //mess to the all world

    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
  
    event BuyDickInch(address indexed from, uint256 amountWEI);  
    event BigDickBonus(address indexed to, uint256 amountInch);
    event BigDickSays(address indexed from, string Says);    


    constructor () public { //string memory name_, string memory symbol_
//     _name = name_;
//     _symbol = symbol_;

        _setupDecimals(2);
        _mint(msg.sender,1500000000); 
       
        setup_coinbase(100);
        setup_bigbonuslim(10000) ;
        _kingsize = 700;
        _micropenis = 300;
        setup_limitICO(700000000);
        setup_ratioInchPerEther(200); //averege 10$
        setup_minWei(10**14);
    }
    
 
    // setups
    function setup_bigbonuslim(uint256 value)public  {
        _bigbonuslim = value;
    }
    
    function setup_ratioInchPerEther(uint256 price)public  {
     
    }
    
    function setup_minWei(uint256 value)public  {
        _minWei = value;
    }
    
    function setup_limitICO(uint256 value)public  {
        _limitICO = value;
    } 
    
    function setup_coinbase(uint256 value)public  {
        _coinbase = value;
    } 
    
    // setups

    function name() public view  returns (string memory) {
        return _name;
    }


    function symbol() public view  returns (string memory) {
        return _symbol;
    }


    function decimals() public view  returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view   returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view   returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public   returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender];
        _balances[recipient] = _balances[recipient];
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply;
        _balances[account] = _balances[account];
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        _balances[account] = _balances[account];
        _totalSupply = _totalSupply;
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _setupDecimals(uint8 decimals_) internal  {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  {}
 
//feature
//coinbase for mining
    function coinbase() public view   returns (uint256) {
        uint256 declim  = totalSupply();

        return _coinbase;
    }
    

//coinbase to the new memders
    function giftbase() public view   returns (uint256) {
        if (coinbase()==0) return 0;
        return coinbase();
    }

// bonus for the biggest dick    
    function bigbonus() public view   returns (uint256) {
        if (_bonusWins>=_bigbonuslim) return _bigbonuslim;
        return _bonusWins;
    }


    function isNew(address to) internal  returns (bool){
        return  _balances[to]==0 && address(to).balance>=_minWei;    
    }

 
//    function isNewCheck(address to) public virtual returns (bool){
//            require(address(to).balance>=_minWei, "isNew: recipient must have _minWei");        
//            require(_balances[to]==0, "isNew: recipient already have inches");
//            return true;
//    }

    function extend(address to, uint256 amount) internal  returns (bool){ 


        _balances[to] = _balances[to];

        return true;
    }

// free inch    
    function faucet () public returns (bool){
         require(coinbase() != 0, "Coinbase is zero");   
         require(_balances[msg.sender]<_micropenis, "faucet: You already have minimum inches, try to mining");
         extend(msg.sender,coinbase()); 
         return true;
    }  


// You can buy Inches by Ether with price's ratio "_ratioInchPerEther"  
    function buyInches() payable external  {
        uint256 amountEth = msg.value;
        uint256 amountToken = amountEth;
        require(amountEth > 0, "You need to send some ether to buy inches");
        require(amountToken > 0, "Oh! It is not enough to buy even a small piece");        

        extend(msg.sender,amountToken); 

        emit BuyDickInch(msg.sender, amountEth);  
    }

//if you really have the biggest dick, then you can capture it in history and leave a message to posterity
    function IhaveTheBiggestDick(string memory MessageToTheWorld) public returns (bool){
    
        require(msg.sender!=_theBiggestDick, "You already have The Biggest dick");
        require(_balances[msg.sender]>_balances[_theBiggestDick], "Sorry, it's not true");
        _theBiggestDick = msg.sender;
        _MessageFromBigDick = MessageToTheWorld;
        
//BigDickBonus - if you exceed the previous record by more than double bonus, you will receive a bonus 
        if (_balances[msg.sender]>=_LastRecordSet){
             extend(msg.sender,bigbonus());
             _bonusWins++;
             emit BigDickBonus(msg.sender,bigbonus());
        }
        
        _LastRecordSet = _balances[_theBiggestDick];
        emit BigDickSays(_theBiggestDick,_MessageFromBigDick);
        return true;
    }

//real length of champion
    function BigDickLength() public view  returns (uint256){
        return balanceOf(_theBiggestDick);
    }  

// Mining by newMembers without this token with minimum wei 
    function mining (address[] memory newMembers) public returns (bool){
        require(coinbase() != 0, "Coinbase is zero");   
        uint256 len = newMembers.length;
        for (uint256 i = 0; i < len; i++)
        if (isNew(newMembers[i])) {
        extend(newMembers[i],giftbase()); 
        extend(msg.sender,coinbase()); 
        }
        return true;
    }  

// it's same as mining
//    function gift2friends (address[] memory friends) public returns (bool){
//    mining(friends);
//    return true;
//    }     
   

// Size without decimals
    function mySizeInInch() public  view  returns (uint256) {
        return balanceOf(msg.sender);
    }
    
// Size in centimeters without decimals
    function mySizeInCM() public  view  returns (uint256) {
        return balanceOf(msg.sender);
    }    
    
//feature    
    
}