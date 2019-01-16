pragma solidity ^0.4.23;

library SafeMath{
    function mul(uint a,uint b) internal pure returns(uint){
        uint c = a*b;
        assert(c/a==b);
        return c;
    }
    function div(uint a,uint b)internal pure returns(uint){
        uint c = a/b;
        assert(a == b*c+a%b);
        return c;
    }
    function sub(uint a,uint b)internal pure returns(uint){
        assert(a>=b);
        return a-b;
    }
    function add(uint a,uint b)internal pure returns(uint){
        uint c = a+b;
        assert(c>=a);
        return c;
    }
}

interface ERC20Interface{
    //总发行量
    function totalSupply() external returns(uint);
    //查询总量
    function balanceOf(address tokenOwner) external returns(uint balance);
    //查询授权数量
    function allowance(address tokenOwner,address spender) external returns(uint remaining);
    //转账
    function transfer(address to,uint tokens) external returns(bool success);
    //授权
    function approve(address spender,uint tokens) external returns(bool success);
    //授权转账
    function transferFrom(address from,address to,uint tokens) external returns(bool success);
    
    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint tokens);
}

contract Owned{
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from,address indexed _to);
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner{
        newOwner = _newOwner;
    }
    function acceptOwnership()public{
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner,newOwner);
        owner = newOwner;
        newOwner= address(0);
    }
}

contract LoveToken  is ERC20Interface,Owned{
    using SafeMath for uint;
    //合约的标识
    string public symbol;
    string public name;
    //精度
    uint8 public decimals;
    //总发行数量
    uint _totalSupply;
    //某个地址多少钱
    mapping(address =>uint) balances;
    //某一个地址授权给了某个地址多少钱
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public{
        symbol = "LOVE";
        name = "love token";
        decimals = 18;
        _totalSupply = 10000 * 10 **18;
        balances[owner] = _totalSupply;
        emit Transfer(address(0),owner,_totalSupply);
    }
    //总发行量
    function totalSupply() public view returns (uint){
        return _totalSupply.sub(balances[address(0)]);
    }
    //查询总量
    function balanceOf(address tokenOwner) public view returns(uint balance){
        return balances[tokenOwner];
    }
    //查询授权数量
    function allowance(address tokenOwner,address spender) public view returns(uint remaining){
        return allowed[tokenOwner][spender];
    }
    //转账
    function transfer(address to,uint tokens) public  returns(bool success){
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    //授权
    function approve(address spender,uint tokens) public  returns(bool success){
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    //授权转账
    function transferFrom(address from,address to,uint tokens) public  returns(bool success){
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
}