/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.4.23;
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
  }  //使用这个库防止溢出
}
interface ERC20Interface{
    function totalsupply() external returns(uint); //总发行量
    function balanceof(address tokenowner) external returns(uint balance);//查询数量；
    function allowance(address tokenowner,address spender) external returns(uint remaining);//查询授权数量
    function transfer(address to,uint tokens) external returns(bool success);//转账
    function approve(address spender,uint tokens) external returns(bool success);//批准
    function transferfrom(address from,address to,uint tokens) external returns(bool success);//授权转账
    
    event Transfer(address indexed from,address indexed to,uint tokens); // 谁转给谁多少钱
    event Approval(address indexed tokenowner,address indexed spender,uint tokens); //谁授权给谁多少钱
    
}
contract owned{
    address owner;
    address newowner;
    
    event ownershiptransferred(address indexed _from,address indexed _to);
    constructor() public{
       owner=msg.sender;
    }
    modifier onlyowner{
        require(msg.sender==owner);
        _;
    }
    function transferownership(address _newowner) public onlyowner{
        newowner=_newowner;
    }
    function acceptownership() public{
        require(msg.sender==newowner);
        emit ownershiptransferred(owner,newowner);
        owner=newowner;
        newowner=address(0);
    }
}
contract lovetoken is ERC20Interface, owned{
    
    using SafeMath for uint;
    string public symbols;//代币的标志
    string public name;//代币的名字
    uint8 public decimals;//代币的精度
    uint _totalsupply;//代币的总发行量
    mapping(address=>uint) balances; //查询代币的数量
    mapping(address=>mapping(address=>uint)) allowed; //a=>b 多少金额
    
    constructor() public{
        symbols='LOVE';
        name='LOVETOKEN';
        decimals=10;
        _totalsupply=100000000*10**11;
        balances[owner]=_totalsupply;
        emit Transfer(address(0),owner,_totalsupply);
    }
    function totalsupply() public view   returns(uint){
        return _totalsupply.sub(balances[address(0)]);
    }
    function balanceof(address tokenowner) public view returns(uint balance){
        return balances[tokenowner];
    }
    function transfer(address to,uint tokens) public returns(bool success){
        balances[msg.sender]=balances[owner].sub(tokens);
        balances[to]=balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    } function approve(address spender,uint tokens) public returns(bool success){
        allowed[msg.sender][spender]=tokens;
        emit Approval (msg.sender,spender,tokens);
        return true;
    }
    function transferfrom(address from,address to,uint tokens) public returns(bool success){
        balances[from]=balances[from].sub(tokens);
        allowed[from][to]=allowed[from][to].sub(tokens);
        balances[to]=balances[to].add(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
    function allowance(address tokenowner,address spender) public returns(uint remaining){
        return allowed[tokenowner][spender];
    }
    
}