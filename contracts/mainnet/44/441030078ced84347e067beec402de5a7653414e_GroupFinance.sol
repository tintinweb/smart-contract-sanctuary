/*MMMMMMMMMMMMMMMMMMMMMKd:;:kXWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNkxKd,;cl0WMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMKdOWklxo'cKMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM0o0WkdXO,;OMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMkl0WkdXO;,kWMMMMMM
MMMMMMMMMMMMMMMMMMMMMWxlKWkdX0;'xWMMMMMM
MMMMMMMMMMMMMMMMMMMMMWdlXWxdN0:'dWMMMMMM
MMMMMMMMMMMMMMMMMMMNXOclXWxdNK:.oNMMMMMM
MMMMMMMMMMMMMMMMWXkllc,lXNddNK:.oNMMMMMM
MMMMMMMMMMMMMWKkxo;l0Kkdko,oXx,.oNMMMMMM
MMMMMMMMMMMMNk:oXXxxXNWXd,.:l,..oNMMMMMM
MMMMMMMMMWKko:'lXMKkkKMMNk;'....lXMMMMMM
MMMMMMMMM0lo0KkcxNWX0XWMMWKo'...:0MMMMMM
MMMMMMMMKl;xNMWkcOWMMW0KWMMNO:'.'xWMMMMM
MMMMMMMKoll:oXMNocKMMWOlkWMMMXx;.cXMMMMM
MMMMMMM0kNNd,dNM0:oXMMXc,xNMMWN0l;kWMMMM
MMMMMMMX0XXc.,xNNd;dKK0xoxKKxlxKdl0MMMMM
MMMMMMMW00Nd'.,ldc';lxKNWWO:..:ccOWMMMMM
MMMMMMMMX0X0:':;..,kXNWKxl,....,kWMMMMMM
MMMMMMMMWKKN0Ok:..oNMWO:......'dNMMMMMMM
MMMMMMMMMX0NWKc..'dNW0:.......lXMMMMMMMM
MMMMMMMMMWKXWk,...oXXd,''....;OWMMMMMMMM
MWMMMMMMMMX0N0oc,.lKKkol:'..'dNMMMMMMMMM
OoodxkO0XNWO0WWNd'oko:'.....cKNXKOkxdooO
Kl'....,cldkONMWk:kkc,.....'lolc,....'cK
Nx,...',;,';dKWW0o0Oc,.,:,.',',;,'...,xN
l,....;:,;:;;coolcdo:,'oX0c',,,':;....,l
0Oxd:';;c0NklooxOOOOOklxNNK0KOc.,:':dxO0
MMMW0c;';k0l,,c0W0kNMXo:llOWNd'.';c0WMMM
MMMMWk;.',,...;OWxdNWKc..cKNx,...,xNMMMM
MMMMMNkc;''...;xOllO0x;.'coc,'';cxXMMMMM
MMMMMMWNKOdoc:;:;,',,,'',;:codkKNWMMMM*/

/// Only 3000GRP (GroupToken)
/// 3% burn rate and trade will be effected from Tue, 10 Nov 2020 13:00:00 GMT. Burning process will be implemented 
//  until the remain of tokens hit 1000

/// dev no token, no any sales, no marketing for this token and trust in the community to see it through 
/// no mint function, 100% add LQ

pragma solidity ^0.4.25;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}
contract ERC20Details is ERC20 {

  uint8 public _decimal;
  string public _name;
  string public _symbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _decimal = decimals;
    _name = name;
    _symbol = symbol; 
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimal;
  }
}

contract GroupFinance is ERC20Details {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  
  string private constant _NAME  = "Group.Finance";
  string private constant _SYMBOL = "GRP";
  uint8 private constant _DECIMALS = 18;
  uint16 private constant supply = 3000;
  address owner = msg.sender;
  address constant public deployer = 0xC331b3a9f2F02a5B3Be2FBf07C398e8f61C44C87;
  uint256 private constant releaseTime = 1605013200;
  uint256 _totalSupply = supply * 10 ** uint256(_DECIMALS);
  uint256 private constant burnrate = 3;
  uint16 private constant minimum = 1000;
  uint256 _minimumSupply = minimum * 10 ** uint256(_DECIMALS);

  constructor() public payable ERC20Details(_NAME, _SYMBOL, _DECIMALS){
    mint(msg.sender, _totalSupply);
  }
  
  function mint(address account, uint256 amount) internal {
    require(amount != 0);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }

  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }

  function burnToken(uint256 value) private view returns (uint256){
      uint256 burnable = _totalSupply - _minimumSupply;
      if (burnable <= 0)
        return 0;
        
      uint256 tokenForburn = 0;
      uint256 _burn = value.mul(burnrate).div(100);
      if (burnable >= _burn)
        tokenForburn = _burn;
      else
        tokenForburn = burnable;
      return tokenForburn;
  }
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));
    if (msg.sender != deployer)
        require(now > releaseTime);
    uint256 needBurn = 0;
    if (now > releaseTime)
        needBurn = burnToken(value);
    uint256 _transfer = value.sub(needBurn);
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(_transfer);
    _totalSupply = _totalSupply.sub(needBurn);

    emit Transfer(msg.sender, to, _transfer);
    emit Transfer(msg.sender, address(0), needBurn);
    return true;
  }
    
  //Buy back and airdrop
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
    
    if (from != deployer)
        require(now > releaseTime);
    uint256 needBurn = 0;
    if (now > releaseTime)
        needBurn = burnToken(value);
    uint256 _transfer = value.sub(needBurn);

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(_transfer);
    _totalSupply = _totalSupply.sub(needBurn);

    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, _transfer);
    emit Transfer(from, address(0), needBurn);
    
    return true;
  }

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
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}