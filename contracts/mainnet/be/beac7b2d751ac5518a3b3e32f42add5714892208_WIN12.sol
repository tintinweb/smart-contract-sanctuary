/**
WIN12
This is not your traditional Degen token. The Real Objective of the game is to BURN tokens from 12 total supply to 0.12 total supply in 12 hours. 

12 players will get prizes in any case.

TG Link - https://t.me/GIGO_gamified
Twitter: @GIGO_Gamified 
Website - soon 


Tokenomics 
MAX SUPPLY: 12 WIN12
Only in 12.11.2020 at 11 AM PST 
NO PRESALE
NO MINT
12% burn 
Liquidity Locked for 12 hours 
Buy limit 1.2

Check the above links to read about the actual Objective of the Token and how you may win, if even if you lose (almost) all the tokens. 
Never Trade without reading first !


                                            __                    
                                       ...-'  |`.      .-''-.     
              .--.   _..._             |      |  |   .' .-.  )    
       _     _|__| .'     '.           ....   |  |  / .'  / /     
 /\    \\   //.--..   .-.   .            -|   |  | (_/   / /      
 `\\  //\\ // |  ||  '   '  |             |   |  |      / /       
   \`//  \'/  |  ||  |   |  |          ...'   `--'     / /        
    \|   |/   |  ||  |   |  |          |         |`.  . '         
     '        |  ||  |   |  |          ` --------\ | / /    _.-') 
              |__||  |   |  |           `---------'.' '  _.'.-''  
                  |  |   |  |                     /  /.-'_.'      
                  |  |   |  |                    /    _.'         
                  '--'   '--'                   ( _.-'            
*/

pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract WIN12 is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  address uniswapWallet = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address liquidityWallet = 0xFC8B42aC9133EF1E9e6645b9b023f15A060f167B;

  string constant tokenName = "WIN12 GAME - GIGO Fair Token";
  string constant tokenSymbol = "WIN12";
  uint8  constant tokenDecimals = 12;
  uint256 _totalSupply = 12000000000000;
  uint256 public burnPercent = 1200;
  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function getburningPercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(burnPercent);
    uint256 burningPercent = roundValue.mul(burnPercent).div(10000);
    return burningPercent;
  }
 

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    if (msg.sender == uniswapWallet || msg.sender == liquidityWallet || to == liquidityWallet || to == uniswapWallet ){
    
        uint256 tokenTransfer = value;
        
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokenTransfer);
        
        emit Transfer(msg.sender, to, tokenTransfer);
        return true;
    } else {
      
      
        if (value > 1200000000000) {
                revert();
            }

    uint256 tokensToBurn = getburningPercent(value);
     uint256 tokensForTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensForTransfer);

     
// No change here, or nothing will work 

    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(msg.sender, to, tokensForTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
    
  }
 }
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    
    
     
  if  (msg.sender == liquidityWallet || from == liquidityWallet){
      
       _balances[from] = _balances[from].sub(value);
        uint256 tokenTransfer = value;
     _balances[to] = _balances[to].add(tokenTransfer);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokenTransfer);

        return true;
    } else {
        

    _balances[from] = _balances[from].sub(value);



    uint256 tokensToBurn = getburningPercent(value);
     uint256 tokensForTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensForTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, tokensForTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

    // NO MINTING

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}