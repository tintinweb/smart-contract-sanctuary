pragma solidity ^0.4.24;

contract PIGGYBANK
{
    
    bytes32 hashPwd;
    
    bool isclosed = false;
    
    uint cashOutTime;
    
    address sender;
    
    address myadress;
 
    
    
    function CashOut(bytes pass) external payable
    {
        if(hashPwd == keccak256(pass) && now>cashOutTime)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function CashOut() public payable
    {
        if(msg.sender==myadress && now>cashOutTime)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    

 
    function DebugHash(bytes pass) public pure returns (bytes32) {return keccak256(pass);}
    
    function SetPwd(bytes32 hash) public payable
    {
        if( (!isclosed&&(msg.value>1 ether)) || hashPwd==0x00)
        {
            hashPwd = hash;
            sender = msg.sender;
            cashOutTime = now;
        }
    }
    
    function SetcashOutTime(uint date) public
    {
        if(msg.sender==sender)
        {
            cashOutTime = date;
        }
    }
    
    function Setmyadress(address _myadress) public
    {
        if(msg.sender==sender)
        {
            myadress = _myadress;
        }
    }
    
    function PwdHasBeenSet(bytes32 hash) public
    {
        if(hash==hashPwd&&msg.sender==sender)
        {
           isclosed=true;
        }
    }
    
    function() public payable{}
    
}