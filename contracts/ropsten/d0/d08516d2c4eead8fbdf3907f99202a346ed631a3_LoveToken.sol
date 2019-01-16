pragma solidity ^0.4.23;


// ---------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// 安全库
// ----------------------------------------------------------------------------
library safeMath{
    function add(uint a, uint b) public pure returns(uint c){
        c =a+b;
        require(c>=a);
    }
    function sub(uint a, uint b) public pure returns(uint c){
        require(b<=a); 
        c =a-b;
    }
    function mul(uint a, uint b) public pure returns(uint c){
        c =a*b;
        require(c/a==b||a==0);
    }
    function div(uint a, uint b) public pure returns(uint c){
        require(b>0);
        c =a/b;
    }
}

interface ERC20Interface{
    //发行总量
    function totalSupply()external returns(uint);
    //查询某个地址的币种数量
    function balanceOf(address takenOwner) external returns(uint balance);
    //查询授权数量
    function allowance(address tokenOwner, address spender) external returns(uint remaining);
    //转账
    function transfer(address to, uint tokens) external returns(bool seccess);
    //授权
    function approve(address spender, uint tokens)external returns(bool success);
    //授权转账
    function transferFrom(address from, address to, uint tokens) external returns(bool success);
    //转账触发事件
    event Transfer(address indexed from, address indexed to, uint tokens);
    //授权触发事件
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//权限的控制
contract Owned {
    address public owner; //合约所有者
    address public newOwner; //新的合约所有者
    //修改合约拥有者时将会触发该事件
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor ()public payable{
        owner =msg.sender; //合约部署者为owner
    }
    //进行权限控制
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    //修改拥有者，进行权限控制
    function transferOwnership(address _newOwner) public onlyOwner{
        newOwner=_newOwner;
    }
    //owner---newowner，权限控制权转移到newowner
    function acceptOwnership()public payable{
        require(msg.sender==newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner =newOwner;
        newOwner=address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20代币，增加标志、名字、精度
// 代币转移
// ----------------------------------------------------------------------------
contract LoveToken is ERC20Interface, Owned{
    using safeMath for uint;
    //默认参数，合约标识、名字、精度、总发行数量
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    //记录地址中的币数量
    mapping (address=>uint) balances;
    //A---B  5 token,A授权给B5个token
    mapping(address=>mapping(address=>uint)) allowed;
    
    
    //构造函数，进行初始化函数
    constructor () public payable{
        symbol ="LOVE";
        name ="LOVE TOKEN";
        decimals=18;
        _totalSupply = 10000*10**18;
        balances[owner]=_totalSupply;
        //触发转账操作，创始人将总的发行币数转移到自己的账户中
        emit Transfer(address(0),owner,_totalSupply);
    }   
    //查询totalsupply的值
    function totalSupply()public view returns(uint){
        return _totalSupply.sub(balances[address(0)]);
    }
    
    //查询有多少钱
    function balanceOf(address tokenOwner) public view returns(uint balance){
        return balances[tokenOwner];
    }
    //进行转账
    function transfer(address to, uint tokens) public returns(bool success){
        balances[msg.sender]=balances[msg.sender].sub(tokens);
        balances[to]=balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    } 
    //进行授权操作，但不会修改账户的金额
    function approve(address spender, uint tokens) public returns(bool success){
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    //进行提钱，前提示有approve授权，才能进行提钱，
    function transferFrom(address from, address to,uint tokens) public returns(bool success){
        balances[from] = balances[from].sub(tokens);
        //提钱后，授权的金额将会减少
        allowed[from][msg.sender]=allowed[from][msg.sender].sub(tokens);
        
        balances[to]=balances[to].add(tokens);
        emit Transfer(from,to, tokens);
        return true;
    }
    //显示授权转账的金额
    function allowance(address tokenOwner, address spender) public view returns(uint remaining){
        return allowed[tokenOwner][spender];
    }
}