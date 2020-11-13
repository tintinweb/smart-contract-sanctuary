pragma solidity ^0.5.17;

////////////////////////////////////////////////////////////////////////////////
contract    ERC20
{
    mapping(address => uint256)                         balances;
    mapping(address => mapping (address => uint256))    allowances;

    uint    public  decimals    = 2;
    uint256 public  totalSupply = 100000000 * 10**decimals;        // 800 Millions (18 decimals)


    string  public  constant    name       = "JBTR Token";
    string  public  constant    symbol     = "JBTR";

    event Transfer(address indexed _from,  address indexed _to,      uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //--------------------------------------------------------------------------
    constructor()   public 
    {
    }
    //--------------------------------------------------------------------------
    function        transfer(address toAddr, uint256 amountInWei)  public   returns (bool)
    {
        uint256         baseAmount;
        uint256         finalAmount;

        require(toAddr!=address(0x0) && toAddr!=msg.sender 
                                     && amountInWei!=0
                                     && amountInWei<=balances[msg.sender]);
        //-----

        baseAmount  = balances[msg.sender];
        finalAmount = baseAmount - amountInWei;
        
        assert(finalAmount <= baseAmount);
        
        balances[msg.sender] = finalAmount;

        //-----
       
        baseAmount  = balances[toAddr];
        finalAmount = baseAmount + amountInWei;

        assert(finalAmount >= baseAmount);
        
        balances[toAddr] = finalAmount;
        
        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool) 
    {
        require(amountInWei!=0                                   &&
                balances[fromAddr]               >= amountInWei  &&
                allowances[fromAddr][msg.sender] >= amountInWei);

                //-----

        uint256 baseAmount  = balances[fromAddr];
        uint256 finalAmount = baseAmount - amountInWei;
        
        assert(finalAmount <= baseAmount);
        
        balances[fromAddr] = finalAmount;
        
                //-----
                
        baseAmount  = balances[toAddr];
        finalAmount = baseAmount + amountInWei;
        
        assert(finalAmount >= baseAmount);
        
        balances[toAddr] = finalAmount;
        
                //-----
                
        baseAmount  = allowances[fromAddr][msg.sender];
        finalAmount = baseAmount - amountInWei;
        
        assert(finalAmount <= baseAmount);
        
        allowances[fromAddr][msg.sender] = finalAmount;
        
        //-----           
        
        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
     //--------------------------------------------------------------------------
    function balanceOf(address _owner) public view returns (uint256 balance) 
    {
        return balances[_owner];
    }
    //--------------------------------------------------------------------------
    function approve(address _spender, uint256 _value) public returns (bool success) 
    {
        allowances[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //--------------------------------------------------------------------------
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) 
    {
        return allowances[_owner][_spender];
    }
}
/////////////////////////////////////////////////////////////////////////////////////////
contract    Airdropper  is ERC20
{
    event onBulkTransfer(address sender, uint256 transactionCount, address tokenAddress);
    
    function    bulkTransfer(address tokenAddress,  address[] memory toWallets, 
                                                    uint256[] memory amountsInBaseUnit)
                                                    public
    {
        uint256     i;
        uint256     n;
        
        require(toWallets.length==amountsInBaseUnit.length);
        
        n = toWallets.length;
        
        for (i=0; i<n; i++)
        {
            if (toWallets[i]==address(0x0) || amountsInBaseUnit[i]==0)    
            {
                continue;
            }
            
            ERC20(tokenAddress).transfer(toWallets[i], amountsInBaseUnit[i]);
        }
        
        emit onBulkTransfer(msg.sender, n, tokenAddress);
    }
}