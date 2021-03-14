/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address payable private _Powner;   

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address payable msgSender = _msgSender();
        _owner = msgSender; 
        _Powner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function owner_payable() public view virtual returns (address payable) {
        return _Powner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _Powner = newOwner;
    }
}


//雞巴大小
contract DickSizeToken is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _maximums;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public _limitICO; // limit for faucet and mining
    uint256 private _coinbase; // profit from mining per member
    uint256 private _bigBonusLim;  // max bonus for bigDick
    uint256 public _bonusWins; // How many BigDicks was
    uint256 public _kingsize; // the royal size of penis
    uint256 public _micropenis;    
    uint256 public _ratioInchPerEther;  //price for buy 
    uint256 public _minWei; // the minimal wei in address to consider it real. For mining 
    
    uint256 public _LastRecordSet;  // sets by func IhaveTheBiggestDick. For big bonus  
    address public _theBiggestDick; // arddress of the biggest dick
    string public _MessageFromBigDick; //mess to the all world
    string public _Intro; // 'hurry up! Less than two million mens will have a king size (7") penis';
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
  
    event BuyDickInch(address indexed from, uint256 amountWEI);  
    event BigDickBonus(address indexed to, uint256 amountInch);
    event BigDickSays(address indexed from, string Says);    


    constructor () public { //string memory name_, string memory symbol_

        _name = "DickSize"; //"DickSize";
       _symbol = "inch";//"inch"; 
       _decimals = 2;  //_setupDecimals(2);
       _mint(_msgSender(),1500000000); 
       _coinbase=100;     //setup_coinbase(100);
       _bigBonusLim = 10000; //setup_bigBonusLim(10000) ;
       _kingsize = 700;
       _micropenis = 300;
       _limitICO = 1000000000; //setup_limitICO(1000000000);
       _ratioInchPerEther = 2000; //setup_ratioInchPerEther(20); //averege 100$
       _minWei = 10**14; //setup_minWei(10**14);
    }
    
 
    // setups
    function setup_Intro(string memory value)public virtual onlyOwner{
        _Intro = value;
    }
    
    function setup_bigBonusLim(uint256 value)public virtual onlyOwner{
        _bigBonusLim = value;
    }
    
    function setup_ratioInchPerEther(uint256 price)public virtual onlyOwner{
        _ratioInchPerEther = price.mul(10**_decimals);
    }
    
    function setup_minWei(uint256 value)public virtual onlyOwner{
        _minWei = value;
    }
    
    function setup_limitICO(uint256 value)public virtual onlyOwner{
        _limitICO = value;
    } 
    
    function setup_coinbase(uint256 value)public virtual onlyOwner{
        _coinbase = value;
    } 
    

    
    function send_to (address[] memory newMembers,uint256 value) public virtual onlyOwner{
        uint256 len = newMembers.length;
        for (uint256 i = 0; i < len; i++)
        extend(newMembers[i],value); 
        
    }
    
    // setups

    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (_maximums[recipient]<_balances[recipient]) _maximums[recipient]=_balances[recipient];
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

//feature
//coinbase for mining
    function coinbase() public view virtual  returns (uint256) {
        uint256 declim  = totalSupply().sub(_limitICO);
        if (_balances[owner()]<declim) return 0;
        return _coinbase;
    }
    

//coinbase to the new memders
    function giftbase() public view virtual  returns (uint256) {
        if (coinbase()==0) return 0;
        return coinbase().div(2);
    }

// bonus for the biggest dick    
    function bigbonus() public view virtual  returns (uint256) {
        if (_bonusWins.mul(100)>=_bigBonusLim) return _bigBonusLim;
        return _bonusWins.mul(100);
    }

//real length of champion
    function BigDickLength() public view virtual returns (uint256){
        return balanceOf(_theBiggestDick);
    }  

    function isNew(address to) public view virtual returns (bool){
        return  _maximums[to]==0 && address(to).balance>=_minWei;    
    }

 
//    function isNewCheck(address to) public virtual returns (bool){
//            require(address(to).balance>=_minWei, "isNew: recipient must have _minWei");        
//            require(_balances[to]==0, "isNew: recipient already have inches");
//            return true;
//    }

    function extend(address to, uint256 amount) internal virtual returns (bool){ 
        require(amount < _balances[owner()], "Opps! The global men's fund is almost empty");
        _balances[owner()] = _balances[owner()].sub(amount);
        _balances[to] = _balances[to].add(amount);
        if (_maximums[to]<_balances[to]) _maximums[to]=_balances[to];
        emit Transfer(owner(), to, amount); 
        return true;
    }

// free inch    
    function faucet () public returns (bool){
         require(coinbase() != 0, "Coinbase is zero");   
         require(_maximums[_msgSender()]<_micropenis, "faucet: You already have minimum inches, try to mining");
         extend(_msgSender(),coinbase()); 
         return true;
    }  


// You can buy Inches by Ether with price's ratio "_ratioInchPerEther"  
    function buyInches() payable external  {
        uint256 amountEth = msg.value;
        uint256 amountToken = amountEth.mul(_ratioInchPerEther).div(10**18);
        require(amountEth > 0, "You need to send some ether to buy inches");
        require(amountToken > 0, "Oh! It is not enough to buy even a small piece");        

        extend(_msgSender(),amountToken); 
        owner_payable().transfer(amountEth);
        emit BuyDickInch(_msgSender(), amountEth);  
    }

//if you really have the biggest dick, then capture it in history and leave a message to posterity
    function IhaveTheBiggestDick(string memory MessageToTheWorld) public returns (bool){
        require(_msgSender()!=owner(), "Sorry, the owner has no rights"); 
        require(_msgSender()!=_theBiggestDick, "You already have The Biggest dick");
        require(_balances[_msgSender()]>_balances[_theBiggestDick], "Sorry, it's not true");
        _theBiggestDick = _msgSender();
        _MessageFromBigDick = MessageToTheWorld;
        
//BigDickBonus - if you exceed the previous record by more than double bonus, you will receive a bonus 
        if (_balances[_msgSender()]>=_LastRecordSet.add(bigbonus().mul(2))){
             extend(_msgSender(),bigbonus());
             _bonusWins++;
             emit BigDickBonus(_msgSender(),bigbonus());
        }
        
        _LastRecordSet = _balances[_theBiggestDick];
        emit BigDickSays(_theBiggestDick,_MessageFromBigDick);
        return true;
    }



// Mining by newMembers without this token with minimum wei 
    function mining (address[] memory newMembers) public returns (bool){
        require(coinbase() != 0, "Coinbase is zero");   
        uint256 len = newMembers.length;
        for (uint256 i = 0; i < len; i++)
        if (isNew(newMembers[i])) {
        extend(newMembers[i],giftbase()); 
        extend(_msgSender(),coinbase()); 
        }
        return true;
    }  


// Size without decimals
    function mySizeInInch(address YourAddress) public  view virtual returns (uint256) {
        return balanceOf(YourAddress).div(10**_decimals);
    }
    
// Size in centimeters without decimals
    function mySizeInCM(address YourAddress) public  view virtual returns (uint256) {
      //  return balanceOf(_msgSender()).mul(254).div(100).div(10**_decimals);
      return balanceOf(YourAddress).mul(254).div(100).div(10**_decimals);
    }    
    
//feature    
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


//    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//        require(b > 0, "SafeMath: modulo by zero");
//        return a % b;
//    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


//    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//        require(b > 0, errorMessage);
//        return a % b;
//    }


}