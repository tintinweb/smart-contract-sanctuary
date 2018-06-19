contract Base 
{
    function add(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        if((z >= x) && (z >= y))
        {
          return z;
        }
        else
        {
            throw;
        }
        
    }

    function sub(uint256 x, uint256 y) internal returns (uint256) {
        if(x >= y)
        {
           uint256 z = x - y;
           return z;
        }
        else
        {
            throw;
        }
    }

    function mul(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        if((x == 0) || (z / x == y))
        {
            return z;
        }
        else
        {
            throw;
        }
    }
    
    address Owner_01;
    address Owner_02;
    address Owner_03;
    
    function Base()
    {
        Owner_01 = msg.sender;
    }
    
    event Deposit(address indexed sender, uint value);
    event Withdraw(address indexed sender, uint value);
    event Log(string message);
}

contract SiriusFund is Base
{
    uint public TotalInvested;
    uint public Available;
    uint public InvestorsQty;
    mapping (address => uint) public Investors;
    address Owner_0l;
    address Owner_02;
    address Owner_03;
    
    function initSiriusFund()
    {
        Owner_0l = msg.sender;
    }
    
    function SetScndOwner(address addr) public anyOwner
    {
        Owner_02 = addr;
    }
    
    function SetThrdOwner(address addr) public anyOwner
    {
        Owner_03 = addr;
    }
    
    function() 
    {
        DepositFund();
    }
    
    function DepositFund() public
    {
        if(msg.value>= 1 ether)
        {
            if(Investors[msg.sender]==0)InvestorsQty++;
            Investors[msg.sender]+=msg.value;
            TotalInvested+=msg.value;
            Available+=msg.value;
            Deposit(msg.sender,msg.value);
        }   
    }
    
    function withdraw(address _addr, uint _wei) public anyOwner
    {
        if(Investors[_addr]==0)throw;
        if(_addr.send(_wei))
        {
             Available-=_wei;
             Withdraw(_addr,_wei);
        }
    }
    
    modifier anyOwner()
    {
        if ( msg.sender != Owner_01 && msg.sender != Owner_02 && msg.sender != Owner_03)throw;
        _
    }
}