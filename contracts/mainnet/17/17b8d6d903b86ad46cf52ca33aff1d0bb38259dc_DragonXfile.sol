/*______________________________________
_____***________________________***_____
____*******__________________*******____
_____********______________********_____
______**** ****___________******________
________********________*****___________
__________********_____***_____________
___________**** ****____________________
_____________**** ****__________________
_______________*********________________
_________________*********______________
__________________**********____________
_____________________********___________
____________****_______********_________
__________******________**** ****_______
_______*******____________**** ***______
____********________________********____
____******____________________******____
________________________________________
______________________________________*/

// 1. our product provides file lending service to customers who need storage which uses to store
//    data files, host directories or others that need to consume data in internet
// 2. this token meaning DXF token will be used for paying service fee, set different level which use for
//    indicating privileges's holders.
// 3. total supply will be fixed at 10,000 token
// 4. Buring mechanism will be active after deploying and burning rate will be decreased day by day 
//    (target burn 60% total token)
//    By following burning rate:
//       - day 1: 8%
//       - day 2: 4%
//       - day 3: 2%
//       - from day 4: 0%
// 5. top 5 holders in day 1 will be set a entry to black diamond level when our service launch
//    top next 5 holders in day 1 will be  set a entry to gold level when our service launch.
//    To be clear that our platform will seperate 6 levels including: golden diamond, black diamond,
//    titanium, gold, silver and non-level
// 6. revenue share base on token holders
// 7. there has been no any sales. At this time, our side will not run any marketing, 
//    100% generated token will be provided to liquidity and we trust in the community to see it through 
// 8. if you have questions find someone who can read

pragma solidity ^0.4.23;

//@from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
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

  function ceil(uint256 m, uint256 n) internal pure returns (uint256) {
    uint256 a = add(m, n);
    uint256 b = sub(a, 1);
    return mul(div(b, n), n);
  }
}

//@from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address target) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address target, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed target, uint256 value);
}

contract ERC20 is IERC20 {

  uint8 public decimal;
  string public name;
  string public symbol;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    decimal = _decimals;
    name = _name;
    symbol = _symbol; 
  }

  function name() public view returns(string memory) {
    return name;
  }

  function symbol() public view returns(string memory) {
    return symbol;
  }

  function decimals() public view returns(uint8) {
    return decimal;
  }
}

contract DragonXfile is ERC20("DragonXfile" , "DFX", 18){
  using SafeMath for uint256;
  
  mapping (address => uint256) public _dxfbalance;
  mapping (address => mapping (address => uint256)) public _allowed;
  
  uint256 _totalSupply = 10000 * 10 ** 18; //10k token
  uint8 constant private burnrated0 = 8;
  uint8 constant private burnrated1 = 4;
  uint8 constant private burnrated2 = 2;
  uint8 constant private burnrated3 = 0;
  
  uint256 constant private milestoned1 = 1605186000; //Wed, 12 Nov 2020 13:00:00 GMT d1
  uint256 constant private milestoned2 = 1605272400; //Wed, 13 Nov 2020 13:00:00 GMT d2
  uint256 constant private milestoned3 = 1605358800; //Wed, 14 Nov 2020 13:00:00 GMT d3

  constructor() public {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _dxfbalance[owner];
  }
  function caculateBurnRate() public view returns (uint8){
    if (now >= milestoned3) return burnrated3;
    if (now >= milestoned2) return burnrated2;
    if (now >= milestoned1) return burnrated1;
    return burnrated0;
  }
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _dxfbalance[msg.sender]);
    require(to != address(0));
    uint8 burnrate = caculateBurnRate();
    uint256 brn = value.mul(burnrate).div(100);
    
    uint256 rvalue = value.sub(brn);
    _dxfbalance[msg.sender] = _dxfbalance[msg.sender].sub(value);
    _dxfbalance[to] = _dxfbalance[to].add(rvalue);
    _totalSupply = _totalSupply.sub(brn);

    emit Transfer(msg.sender, to, rvalue);
    emit Transfer(msg.sender, address(0), brn);

    return true;
  }
 
  function allowance(address owner, address target) public view returns (uint256) {
    return _allowed[owner][target];
  }

  function approve(address target, uint256 value) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = value;
    emit Approval(msg.sender, target, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _dxfbalance[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _dxfbalance[from] = _dxfbalance[from].sub(value);
    uint8 burnrate = caculateBurnRate();
    uint256 brn = value.mul(burnrate).div(100);
    
    uint256 rvalue = value.sub(brn);

    _dxfbalance[to] = _dxfbalance[to].add(rvalue);
    _totalSupply = _totalSupply.sub(brn);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, rvalue);
    emit Transfer(from, address(0), brn);

    return true;
  }
  
  function increaseAllowance(address target, uint256 addedValue) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = (_allowed[msg.sender][target].add(addedValue));
    emit Approval(msg.sender, target, _allowed[msg.sender][target]);
    return true;
  }

  function decreaseAllowance(address target, uint256 val) public returns (bool) {
    require(target != address(0));
    _allowed[msg.sender][target] = (_allowed[msg.sender][target].sub(val));
    emit Approval(msg.sender, target, _allowed[msg.sender][target]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _dxfbalance[account] = _dxfbalance[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    setBurn(msg.sender, amount);
  }

  function setBurn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _dxfbalance[account]);
    _totalSupply = _totalSupply.sub(amount);
    _dxfbalance[account] = _dxfbalance[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
}