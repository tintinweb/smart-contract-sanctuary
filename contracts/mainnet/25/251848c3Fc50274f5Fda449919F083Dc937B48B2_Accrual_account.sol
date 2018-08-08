contract Accrual_account
{
    address admin = msg.sender;
   
    uint targetAmount = 1 ether;
    
    mapping(address => uint) public investors;
   
    event FundsMove(uint amount,bytes32 typeAct,address adr);
    
    function changeAdmin(address _new)
    {
        if(_new==0x0)throw;
        if(msg.sender!=admin)throw;
        admin=_new;
    }
    
    function FundTransfer(uint _am, bytes32 _operation, address _to, address _feeToAdr) 
    payable
    {
       if(msg.sender != address(this)) throw;
       if(_operation=="In")
       {
           FundsMove(msg.value,"In",_to);
           investors[_to] += _am;
       }
       else
       {
           uint amTotransfer = 0;
           if(_to==_feeToAdr)
           {
               amTotransfer=_am;
           }
           else
           {
               amTotransfer=_am/100*99;
               investors[_feeToAdr]+=_am-amTotransfer;
           }
           if(_to.call.value(_am)()==false)throw;
           investors[_to] -= _am;
           FundsMove(_am, "Out", _to);
       }
    }
    
    function()
    payable
    {
       In(msg.sender);
    }
    
    function Out(uint amount) 
    payable
    {
        if(investors[msg.sender]<targetAmount)throw;
        if(investors[msg.sender]<amount)throw;
        this.FundTransfer(amount,"",msg.sender,admin);
    }
    
    function In(address to)
    payable
    {
        if(to==0x0)to = admin;
        if(msg.sender!=tx.origin)throw;
        this.FundTransfer(msg.value, "In", to,admin);
    }
    
    
}