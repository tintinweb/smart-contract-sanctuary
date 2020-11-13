/*



   __  __      _ __              
  / / / /___  (_) /   ____  _  __
 / / / / __ \/ / /   / __ \| |/_/
/ /_/ / / / / / /___/ /_/ />  <  
\____/_/ /_/_/_____/\____/_/|_|  
                                 

______         _____       _       ______                       
| ___ \       /  ___|     | |      | ___ \                      
| |_/ / __ ___\ `--.  __ _| | ___  | |_/ / ___  _ __  _   _ ___ 
|  __/ '__/ _ \`--. \/ _` | |/ _ \ | ___ \/ _ \| '_ \| | | / __|
| |  | | |  __/\__/ / (_| | |  __/ | |_/ / (_) | | | | |_| \__ \
\_|  |_|  \___\____/ \__,_|_|\___| \____/ \___/|_| |_|\__,_|___/
                                                                
                                                                

                                                     
PRESALE BONUS TOKEN

unilox.io

$PRELOX

$PRELOX is used to secure a 2X bonus on presale purchases of $LOX token

$LOX presale begins Sept 18 and ends Sept 20

LOX/ETH will launch on Uniswap Setp 20

To gain the 2X bonus buyers of $LOX must hold at least 1,000 $PRELOX tokens



Website:   https://unilox.io

Telegram:  https://t.me/unilox

Twitter:   https://twitter.com/Uniloxio

Discord:   https://discord.gg/PcaQ473

*/


pragma solidity ^0.5.17;

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

contract PRELOX is ERC20Detailed {


  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (uint => string) private _assets;

  string constant tokenName = "UniLox.io";   
  string constant tokenSymbol = "PRELOX";  
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 2000000e18;
  address admin; 

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    
    admin = msg.sender;
    _balances[admin] = 1000000e18;

    emit Transfer(address(0), msg.sender, 1000000e18);
  }

  function() external payable {
  }

   function withdraw() external onlyAdministrator() {

      msg.sender.transfer(address(this).balance);
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


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint tokensToSend = value;

    _balances[msg.sender] = _balances[msg.sender].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);

    emit Transfer(msg.sender, to, tokensToSend);

    return true;
  }

     modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(_customerAddress == admin);
        _;
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

    uint tokensToSend = value;

    _balances[from] = _balances[from].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokensToSend);

    emit Transfer(from, to, tokensToSend);
   
    return true;
  }

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }

}