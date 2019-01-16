pragma solidity ^0.4.17;

contract Bidding
{
    address public supervisor;
    address[] public bidders;
    uint[] private bidderValue;
    address public bidderWinner;
    
    function Bidding() public
    {
        supervisor=msg.sender;
    }
    
    function enter() public payable
    {
        require(msg.value > 0.01 ether);
        
        bidders.push(msg.sender);
        bidderValue.push(msg.value);
    }
    
    function pickWinner() public onlyHeCan() returns(address){
      uint  winner=0;
        for(uint biddersIndex=1; biddersIndex<bidders.length;biddersIndex++)
        {
       if(bidderValue[biddersIndex] > bidderValue[winner] )
        {
            winner=biddersIndex;
        }
        bidderWinner=bidders[winner];
        
        }
        return bidders[winner];
       //bidders=new address[](0);
     
    
    }
    modifier onlyHeCan(){
        require(msg.sender==supervisor);
        _;
    }
    function seeBidders() public view returns(address[]){
        return bidders;
    }
    
    
}